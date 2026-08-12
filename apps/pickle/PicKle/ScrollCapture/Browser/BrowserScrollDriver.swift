import AppKit

/// Reads and drives the scroll position of the front browser tab over Apple Events.
///
/// **Why this exists.** Pixel stitching can only ever *guess* how far a page moved,
/// and five rounds of measurement put a floor under that guess: Vision quantises to
/// whole pixels while momentum scrolling renders at fractional offsets, and a page
/// is free to reflow its own content between two frames. A browser is the one class
/// of target that will simply *tell* us where it is — so for browsers we stop
/// guessing, place every tile at the coordinate the page reports, and the whole
/// error class disappears (see the plan, §10).
///
/// Every JavaScript payload here is a **fixed compile-time constant**. The only
/// value ever interpolated is a scroll offset, and it is a `Double` this app
/// computed, range-checked and formatted with `%.2f` — so the injected text can
/// only ever be digits, a dot and a minus sign. There is no path from anything the
/// user or the page controls into the script text.
@available(macOS 14.0, *)
final class BrowserScrollDriver {

    /// Which scripting dictionary a browser speaks. Safari and the Chromium family
    /// use different verbs for the same thing and nothing else differs.
    enum Family {
        case safari
        case chromium

        /// Bundle identifiers we drive. Everything in the Chromium column ships the
        /// same `execute … javascript` command, so adding a browser is one line.
        static func of(bundleID: String) -> Family? {
            switch bundleID {
            case "com.apple.Safari": return .safari
            case "com.google.Chrome", "com.google.Chrome.canary",
                 "com.microsoft.edgemac", "com.brave.Browser",
                 "com.vivaldi.Vivaldi", "org.chromium.Chromium": return .chromium
            default: return nil
            }
        }
    }

    /// Scroll geometry of the tagged scroller, in CSS pixels.
    struct Metrics {
        /// Current scroll offset from the top.
        let y: Double
        /// Height of the visible part — the page's own idea of a viewport.
        let viewport: Double
        /// Total scrollable height.
        let total: Double

        /// The page can't scroll (or is one screen tall), so there is nothing to
        /// assemble and the session should just keep its single frame.
        var isScrollable: Bool { total > viewport + 2 }
        /// Furthest `y` that still shows new content.
        var maxY: Double { max(0, total - viewport) }
    }

    enum DriverError: Error {
        /// The user hasn't granted PICkle permission to control this browser
        /// (System Settings → Privacy & Security → Automation), error -1743.
        case notAuthorized
        /// Automation is allowed but the browser refuses to run JavaScript sent by
        /// Apple Events — Safari's Develop menu toggle, Chrome's View → Developer one.
        case javaScriptBlocked
        /// No front window, or no tab in it.
        case noWindow
        /// The browser didn't answer inside `timeout`. Treated as fatal: the queue
        /// is still blocked on the call we gave up on.
        case timedOut
        /// The script ran but the answer wasn't the shape we expect.
        case badResponse
        /// Anything else the browser reported.
        case scriptFailed(number: Int, message: String)

        /// Whether this is the "you have to turn something on" class of failure —
        /// the one worth showing the onboarding alert for.
        var isSetupProblem: Bool {
            switch self {
            case .notAuthorized, .javaScriptBlocked: return true
            default: return false
            }
        }
    }

    /// Apple's default event timeout is a full minute; a browser that hasn't
    /// answered a `scrollTop` read in this long is wedged, and waiting only makes
    /// the user watch a frozen panel.
    private static let timeout: TimeInterval = 6

    let family: Family
    private let bundleID: String
    /// AppleScript is executed off the main thread (a wedged browser must never
    /// freeze the menu bar) and always on this one queue, because `NSAppleScript`
    /// is safe on a single thread at a time and nothing more.
    private let queue = DispatchQueue(label: "com.Team-jAm.PICkle.browser-events", qos: .userInitiated)
    /// Set once a call times out. The queue is still occupied by that call, so every
    /// later request would silently wait behind it — fail them immediately instead.
    ///
    /// A type of its own so the timeout closure can capture the flag rather than the
    /// whole driver, which keeps a non-`Sendable` class out of a `@Sendable` closure.
    private final class PoisonFlag: @unchecked Sendable {
        private let lock = NSLock()
        private var value = false
        var isSet: Bool {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        func set() {
            lock.lock()
            value = true
            lock.unlock()
        }
    }

    private let poison = PoisonFlag()

    /// nil when `bundleID` isn't a browser we can drive.
    init?(bundleID: String) {
        guard let family = Family.of(bundleID: bundleID) else { return nil }
        self.family = family
        self.bundleID = bundleID
    }

    // MARK: - Operations

    /// Find the element that actually scrolls, tag it as `window.__pickleScroller`,
    /// and report where it is. Every later call reuses the tag.
    func prepare() async throws -> Metrics {
        try parseMetrics(await run(Self.metricsJS))
    }

    /// Scroll to `y` and report where the page actually landed.
    ///
    /// The returned offset is the one to believe: a page can clamp the request at
    /// its own bottom, snap to a scroll-snap point, or ignore it entirely, and every
    /// tile is placed at the reported value rather than the requested one.
    func scroll(to y: Double) async throws -> Metrics {
        // Belt and braces around the one interpolated value: NaN and infinity have
        // no digits-only spelling, and the clamp keeps the text short and finite.
        let safe = y.isFinite ? min(max(y, 0), 100_000_000) : 0
        return try parseMetrics(await run(Self.scrollJS(to: safe)))
    }

    /// Height, in CSS pixels, that each tile must overlap the previous one by so
    /// that pinned page chrome can be discarded from the top of it.
    ///
    /// Measured, not guessed: whatever fixed/sticky bars sit against the top of the
    /// viewport are hit-tested and their lowest edge (plus a margin) becomes the
    /// pad. Nothing is hidden or restyled — a page that is mid-animation or whose
    /// layout depends on its own header stays exactly as the user sees it.
    func stickyPad() async throws -> Double {
        let text = try await run(Self.padJS)
        guard let value = Double(text.trimmingCharacters(in: .whitespacesAndNewlines)),
              value.isFinite else { throw DriverError.badResponse }
        return min(max(value, 0), 5_000)
    }

    // MARK: - AppleScript plumbing

    /// Run one payload in the front tab and hand back whatever string it evaluated to.
    private func run(_ javaScript: String) async throws -> String {
        if poison.isSet { throw DriverError.timedOut }

        let source = script(for: javaScript)
        let poison = self.poison
        return try await withCheckedThrowingContinuation { continuation in
            // The script and the timer both always run; whichever gets here first is
            // the answer, and the loser must not touch the continuation — or the
            // driver — again. `claim` is the only thing that decides which is which.
            let settled = NSLock()
            var isSettled = false
            func claim() -> Bool {
                settled.lock()
                defer { settled.unlock() }
                guard !isSettled else { return false }
                isSettled = true
                return true
            }

            queue.async {
                var errorInfo: NSDictionary?
                let script = NSAppleScript(source: source)
                let descriptor = script?.executeAndReturnError(&errorInfo)
                guard claim() else { return }   // the timeout already gave up on us
                if let errorInfo {
                    continuation.resume(throwing: Self.mapError(errorInfo))
                } else if let text = descriptor?.stringValue {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(throwing: DriverError.badResponse)
                }
            }

            DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + Self.timeout) {
                // Only poison the driver if this call really did time out. Poisoning
                // unconditionally would kill every session the moment its first
                // *successful* call turned six seconds old.
                guard claim() else { return }
                poison.set()
                continuation.resume(throwing: DriverError.timedOut)
            }
        }
    }

    /// The one-line tell block for this browser family.
    private func script(for javaScript: String) -> String {
        let literal = Self.appleScriptLiteral(javaScript)
        switch family {
        case .safari:
            return "tell application id \"\(bundleID)\" to do JavaScript \(literal) "
                + "in current tab of front window"
        case .chromium:
            return "tell application id \"\(bundleID)\" to execute front window's active tab "
                + "javascript \(literal)"
        }
    }

    /// Wrap a payload as an AppleScript string literal. The payloads are written
    /// without quotes or backslashes so this is a no-op today; it stays because a
    /// payload edited later must not be able to break out of the literal.
    private static func appleScriptLiteral(_ text: String) -> String {
        let escaped = text
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        return "\"\(escaped)\""
    }

    /// Turn AppleScript's error dictionary into something the UI can act on.
    ///
    /// The JavaScript-is-blocked case has no shared error number — Safari and each
    /// Chromium browser report their own — but every one of them names JavaScript in
    /// the message, and none of the other failures do. That word is not localised.
    private static func mapError(_ info: NSDictionary) -> DriverError {
        let number = (info[NSAppleScript.errorNumber] as? NSNumber)?.intValue ?? 0
        let message = (info[NSAppleScript.errorMessage] as? String) ?? ""
        if number == -1743 { return .notAuthorized }
        if message.range(of: "javascript", options: .caseInsensitive) != nil {
            return .javaScriptBlocked
        }
        switch number {
        case -1728, -1719, -1700: return .noWindow          // no window / no such object
        case -600, -609, -10814:  return .noWindow          // the browser went away
        default: return .scriptFailed(number: number, message: message)
        }
    }

    private func parseMetrics(_ text: String) throws -> Metrics {
        guard let data = text.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let y = object["y"] as? Double ?? (object["y"] as? NSNumber)?.doubleValue,
              let viewport = object["vh"] as? Double ?? (object["vh"] as? NSNumber)?.doubleValue,
              let total = object["total"] as? Double ?? (object["total"] as? NSNumber)?.doubleValue,
              y.isFinite, viewport > 0, total > 0 else { throw DriverError.badResponse }
        return Metrics(y: y, viewport: viewport, total: total)
    }

    // MARK: - JavaScript payloads (fixed constants)

    /// Tag the scrolling element and report `{y, vh, total}`.
    ///
    /// The scroller is not always the document: single-page apps routinely put the
    /// whole conversation or feed inside an `overflow-y: auto` div, and scrolling
    /// `document.scrollingElement` there does nothing at all. So: reuse an existing
    /// tag, else the document if it really scrolls, else hit-test the middle of the
    /// viewport and walk up to the first scrollable ancestor — which is the same
    /// element the browser itself would scroll if the user spun the wheel there.
    private static let metricsJS = """
    (function(){var d=document;var e=window.__pickleScroller;\
    if(!e||!e.isConnected||e.scrollHeight<=e.clientHeight+2){e=null;}\
    if(!e){var s=d.scrollingElement||d.documentElement;\
    if(s&&s.scrollHeight>s.clientHeight+2){e=s;}}\
    if(!e){var stack=d.elementsFromPoint(Math.round(window.innerWidth/2),\
    Math.round(window.innerHeight/2))||[];\
    for(var i=0;i<stack.length&&!e;i++){var n=stack[i];\
    while(n&&n.nodeType===1){if(n.scrollHeight>n.clientHeight+2){var st=window.getComputedStyle(n);\
    var oy=st.overflowY;if(oy==='auto'||oy==='scroll'||oy==='overlay'){e=n;break;}}\
    n=n.parentElement;}}}\
    if(!e){e=d.scrollingElement||d.documentElement;}\
    window.__pickleScroller=e;\
    return JSON.stringify({y:e.scrollTop,vh:e.clientHeight,total:e.scrollHeight});})()
    """

    /// Jump the tagged scroller to an absolute offset and report where it landed.
    ///
    /// `behavior: 'instant'` is not decoration: a page with
    /// `html { scroll-behavior: smooth }` animates a plain `scrollTop` assignment,
    /// and the offset read back a millisecond later would be the position the page
    /// is scrolling *away from* — every tile placed at a lie.
    private static func scrollJS(to y: Double) -> String {
        let offset = String(format: "%.2f", y)
        return """
        (function(){var e=window.__pickleScroller;\
        if(!e||!e.isConnected){return '';}\
        if(e.scrollTo){e.scrollTo({top:\(offset),left:e.scrollLeft,behavior:'instant'});}\
        else{e.scrollTop=\(offset);}\
        return JSON.stringify({y:e.scrollTop,vh:e.clientHeight,total:e.scrollHeight});})()
        """
    }

    /// Lowest edge of anything pinned against the top of the viewport, + 40px, floor 200px.
    ///
    /// Hit-testing three points along the top edge and walking up their ancestors
    /// finds a pinned bar for a few hundred `getComputedStyle` calls at most. Scanning
    /// every element in the document would answer the same question and take seconds
    /// on a large page — long enough to trip our own Apple Event timeout.
    ///
    /// Only wide, shallow bars count: a floating action button in the corner is
    /// pinned too, but it isn't what a tile has to overlap past, and treating it as
    /// a header would throw away hundreds of good pixels from every tile.
    private static let padJS = """
    (function(){var vw=window.innerWidth,vh=window.innerHeight;var m=0;var seen=[];\
    var xs=[Math.round(vw*0.25),Math.round(vw*0.5),Math.round(vw*0.75)];\
    for(var k=0;k<xs.length;k++){var stack=document.elementsFromPoint(xs[k],2)||[];\
    for(var i=0;i<stack.length;i++){var n=stack[i];\
    while(n&&n.nodeType===1){if(seen.indexOf(n)<0){seen.push(n);\
    var st=window.getComputedStyle(n);var p=st.position;\
    if((p==='fixed'||p==='sticky')&&st.visibility!=='hidden'&&st.display!=='none'){\
    var r=n.getBoundingClientRect();\
    if(r.width>=vw*0.5&&r.height>0&&r.top<=4&&r.bottom<=vh*0.5&&r.bottom>m){m=r.bottom;}}}\
    n=n.parentElement;}}}\
    return String(Math.max(200,Math.ceil(m)+40));})()
    """
}
