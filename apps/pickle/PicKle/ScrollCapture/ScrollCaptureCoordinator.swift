import AppKit

/// Everything the user sees when scrolling capture can't run. Kept outside the
/// coordinator (which is macOS 14+) so the "your Mac is too old" path can reach it.
enum ScrollCaptureAlerts {

    /// macOS 13: `SCScreenshotManager` doesn't exist, so there's nothing to offer.
    static func unsupported() {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L("scroll.alert.unsupported.title")
        alert.informativeText = L("scroll.alert.unsupported.message")
        alert.addButton(withTitle: L("common.ok"))
        run(alert)
    }

    /// A frame grab threw — usually the display went away mid-session.
    static func captureFailed() {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L("scroll.alert.failed.title")
        alert.informativeText = L("scroll.alert.failed.message")
        alert.addButton(withTitle: L("common.ok"))
        run(alert)
    }

    /// Screen Recording gate. Normal captures shell out to `screencapture -i`,
    /// which is user-driven and needs no grant, so this is the *only* place PICkle
    /// ever asks — and existing users only meet it if they try scrolling capture.
    /// Returns true when we may proceed.
    static func ensureScreenRecordingPermission() -> Bool {
        if ScreenRecordingPermission.isAuthorized() { return true }
        // First call raises the system prompt and adds PICkle to the list. macOS
        // often only honors a fresh grant in a newly launched process, hence the
        // "quit and reopen" line in the alert below.
        if ScreenRecordingPermission.request() { return true }
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = L("scroll.alert.permission.title")
        alert.informativeText = L("scroll.alert.permission.message")
        alert.addButton(withTitle: L("scroll.alert.permission.openSettings"))
        alert.addButton(withTitle: L("scroll.alert.permission.later"))
        if run(alert) == .alertFirstButtonReturn {
            ScreenRecordingPermission.openSystemSettings()
        }
        return false
    }

    /// First-run onboarding for the browser path. Driving a browser needs two
    /// switches the user has to throw themselves — the Automation permission, and
    /// each browser's own "allow JavaScript from Apple Events" toggle — and neither
    /// can be requested programmatically, so all we can do is say where they are.
    ///
    /// Returns true when the user would rather not bother: the same region then runs
    /// as an ordinary manual scrolling capture, which needs no permission at all.
    @available(macOS 14.0, *)
    static func browserOnboarding(family: BrowserScrollDriver.Family) -> Bool {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = L("scroll.browser.onboard.title")
        alert.informativeText = family == .safari
            ? L("scroll.browser.onboard.message.safari")
            : L("scroll.browser.onboard.message.chromium")
        alert.addButton(withTitle: L("scroll.browser.onboard.manual"))
        alert.addButton(withTitle: L("scroll.browser.onboard.cancel"))
        return run(alert) == .alertFirstButtonReturn
    }

    /// LSUIElement apps have no windows of their own to front, so an alert can
    /// open behind whatever the user is looking at. Activating is safe here (and
    /// unlike the capture overlays, desirable) because nothing is being filmed yet.
    @discardableResult
    private static func run(_ alert: NSAlert) -> NSApplication.ModalResponse {
        NSApp.activate(ignoringOtherApps: true)
        return alert.runModal()
    }
}

/// Entry point and state machine for scrolling capture: region drag → repeated
/// frame grabs while the user scrolls by hand → one tall stitched PNG in the
/// bottle folder. AppDelegate owns exactly one of these.
///
/// The whole feature is isolated here; the ⇧⌥S / ⇧⌥D / ⇧⌥A paths still go through
/// `screencapture -i` and are untouched by any of it.
@available(macOS 14.0, *)
final class ScrollCaptureCoordinator {

    private enum State {
        case idle
        /// The region overlay is up, waiting for a drag.
        case selecting
        /// Frames are being grabbed on a timer.
        case capturing
        /// A browser is being scrolled and photographed for us.
        case autoCapturing
        /// [Done] pressed; composing and writing the PNG.
        case finishing
    }

    /// Grab rate. Fast enough that a normal scroll leaves plenty of overlap between
    /// consecutive frames — and, more importantly, that a lazily-painted band gets
    /// several chances to settle before it scrolls out of view. A machine that can't
    /// keep up simply drops ticks (see `isBusy`) rather than building a backlog.
    private static let frameInterval: TimeInterval = 0.12
    /// How long to wait after the user finishes before taking one last frame. Long
    /// enough for a page to finish painting whatever a closing fling revealed.
    private static let settleDelay: TimeInterval = 0.35
    /// Refuse drags smaller than this on either axis — a tiny region has too little
    /// texture for Vision to lock onto.
    private static let minimumRegionSide: CGFloat = 80
    /// Safety ceiling for the stitched image, in pixels.
    private static let maxHeightPixels = 30_000

    private var state: State = .idle
    private let selector = ScrollRegionSelectController()
    private var panel: ScrollCapturePanel?
    private var grabber: ScrollFrameGrabber?
    private var stitcher: ScrollStitcher?
    private var timer: Timer?
    /// A grab or a registration is in flight. New ticks are dropped rather than
    /// queued, so a slow machine loses frames instead of building a backlog.
    private var isBusy = false
    private var screenObserver: NSObjectProtocol?
    private var onSaved: ((URL) -> Void)?
    /// Bumped for every session. A grab is async, so one started before a cancel
    /// can land after the *next* session has begun — where it would become that
    /// session's first frame, a slice of the wrong region pasted at the top.
    /// Frames tagged with a stale ID are dropped.
    private var sessionID = 0
    /// Slices accepted so far, mirrored from the stitcher's progress callbacks so
    /// the display-change handler can read it without blocking on the stitch queue.
    private var stripCount = 0
    /// Seams reported so far, so the panel only reacts to *new* ones.
    private var seamCount = 0
    /// Captured pixels per point for the running session, kept for the saved PNG's DPI.
    private var captureScale: CGFloat = 1
    /// Whatever app was in front when the shortcut fired. Read at that moment and
    /// not later, because the region overlay is the only thing on screen afterwards
    /// — it never activates PICkle, so this stays the app the user meant to capture.
    private var targetBundleID: String?
    /// Non-nil only while a browser is driving itself.
    private var browserSession: BrowserScrollSession?
    /// A modal alert is up. `runModal` spins its own run loop, so the ⇧⌥W handler
    /// keeps firing underneath it — and a second press would start a session on top
    /// of the one waiting for the user's answer.
    private var isPresentingAlert = false
    /// Share of the region that must lie inside the target browser's own window
    /// before the automatic path is used. The browser reports the scroll offset of
    /// *its* page; if the user drew the region over something else, those numbers
    /// describe a page that isn't in the picture, and the result is a striped mess.
    private static let minimumWindowCoverage: CGFloat = 0.7

    deinit {
        stopTicking()
        dismissUI()
    }

    /// The shortcut. Starts a session, or ends the one already running — pressing
    /// ⇧⌥W again is the keyboard equivalent of clicking [Done].
    ///
    /// `onSaved` is only used when a session starts; a press that finishes one
    /// calls back through the closure the session began with.
    func toggle(onSaved: @escaping (URL) -> Void) {
        // An alert is waiting for an answer. The shortcut is global and keeps
        // firing through a modal run loop, so without this a second press would
        // begin a session while the first one is still deciding what to be.
        guard !isPresentingAlert else { return }
        switch state {
        case .idle:      begin(onSaved: onSaved)
        case .selecting: cancel()      // nothing captured yet, so "again" means "forget it"
        case .capturing: finish(settle: true)
        // Same meaning as in a manual session: stop here and keep what you have,
        // rather than throwing the tiles away.
        case .autoCapturing: browserSession?.finishEarly()
        case .finishing: break         // already saving
        }
    }

    // MARK: - Session lifecycle

    private func begin(onSaved: @escaping (URL) -> Void) {
        guard ScrollCaptureAlerts.ensureScreenRecordingPermission() else { return }
        self.onSaved = onSaved
        sessionID &+= 1
        stripCount = 0
        seamCount = 0
        targetBundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        state = .selecting
        ScrollSessionLog.startSession("front app = \(targetBundleID ?? "unknown")")
        selector.begin(minimumSide: Self.minimumRegionSide,
                       onSelect: { [weak self] region, screen in
                           self?.startSession(region: region, screen: screen)
                       },
                       onCancel: { [weak self] in self?.cancel() })
    }

    /// The fork. A supported browser can be asked where it is and told where to go,
    /// so it gets the automatic path where tiles are placed by coordinate; anything
    /// else gets the manual path, where the user scrolls and frames are matched
    /// against each other. Only the choice is new — both sessions below are the same
    /// ones they always were.
    private func startSession(region: NSRect, screen: NSScreen) {
        guard state == .selecting else { return }
        if let bundleID = targetBundleID, let driver = BrowserScrollDriver(bundleID: bundleID) {
            let coverage = Self.windowCoverage(of: region, bundleID: bundleID)
            if coverage >= Self.minimumWindowCoverage {
                ScrollSessionLog.write(String(format: "mode = browser (%@, region %.0f%% inside its window)",
                                              bundleID, coverage * 100))
                startBrowserCapturing(region: region, screen: screen, driver: driver)
                return
            }
            // The browser is frontmost but the region isn't on it — a chat window
            // parked on top, a second monitor. Driving the browser would scroll a
            // page nobody is photographing.
            ScrollSessionLog.write(String(format:
                "mode = manual stitch (region only %.0f%% inside the %@ window)",
                coverage * 100, bundleID))
            startCapturing(region: region, screen: screen)
            return
        }
        ScrollSessionLog.write("mode = manual stitch")
        startCapturing(region: region, screen: screen)
    }

    /// Largest share of `region` covered by a single ordinary window belonging to
    /// `bundleID`, 0…1.
    ///
    /// The window list is in CoreGraphics coordinates — top-left origin, measured
    /// from the primary display — while `region` is AppKit's bottom-left global
    /// space, so the y axis has to be flipped across the primary screen's height.
    /// Only layer 0 windows count; menus, panels and the Dock live above it.
    private static func windowCoverage(of region: NSRect, bundleID: String) -> CGFloat {
        let area = region.width * region.height
        guard area > 0,
              let app = NSWorkspace.shared.runningApplications
                  .first(where: { $0.bundleIdentifier == bundleID }),
              let primary = NSScreen.screens.first,
              let windows = CGWindowListCopyWindowInfo(
                  [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID)
                  as? [[String: Any]]
        else { return 0 }

        let flipped = CGRect(x: region.minX, y: primary.frame.maxY - region.maxY,
                             width: region.width, height: region.height)
        var best: CGFloat = 0
        for window in windows {
            guard (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value
                    == app.processIdentifier,
                  (window[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: NSNumber],
                  let x = bounds["X"]?.doubleValue, let y = bounds["Y"]?.doubleValue,
                  let w = bounds["Width"]?.doubleValue, let h = bounds["Height"]?.doubleValue
            else { continue }
            let frame = CGRect(x: x, y: y, width: w, height: h)
            let overlap = frame.intersection(flipped)
            guard !overlap.isNull else { continue }
            best = max(best, overlap.width * overlap.height / area)
        }
        return best
    }

    private func startCapturing(region: NSRect, screen: NSScreen) {
        guard state == .selecting else { return }
        state = .capturing
        let grabber = ScrollFrameGrabber(region: region, screen: screen)
        self.grabber = grabber
        captureScale = grabber.scale
        stitcher = ScrollStitcher(maxHeightPixels: Self.maxHeightPixels)

        let panel = ScrollCapturePanel(region: region, screen: screen,
                                       onDone: { [weak self] in self?.finish(settle: true) },
                                       onCancel: { [weak self] in self?.cancel() })
        panel.show()
        self.panel = panel
        observeScreenChanges()

        // Order matters: the panels must exist *before* the first grab, because
        // that's when the grabber snapshots the window list it excludes.
        captureFrame()
        let timer = Timer(timeInterval: Self.frameInterval, repeats: true) { [weak self] _ in
            self?.captureFrame()
        }
        // .common so the timer keeps ticking while the user drags a scrollbar.
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: - Browser session

    /// Hand the region to a browser that will scroll itself. Same windows as the
    /// manual session — the dimmer marks the filmed area and the panel offers a way
    /// out — but the panel counts percent instead of pixels, because with the page's
    /// own total height known the end is actually predictable this time.
    private func startBrowserCapturing(region: NSRect, screen: NSScreen,
                                       driver: BrowserScrollDriver) {
        state = .autoCapturing
        let grabber = ScrollFrameGrabber(region: region, screen: screen)
        self.grabber = grabber
        captureScale = grabber.scale

        let panel = ScrollCapturePanel(region: region, screen: screen,
                                       onDone: {},   // no [Done] in automatic mode
                                       onCancel: { [weak self] in self?.cancelBrowserSession() })
        panel.show(automatic: true)
        self.panel = panel
        observeScreenChanges()

        let session = BrowserScrollSession(driver: driver, grabber: grabber,
                                           regionHeightPixels: region.height * grabber.scale,
                                           maxHeightPixels: Self.maxHeightPixels,
                                           backingScale: grabber.scale)
        browserSession = session
        // Every session bumps this, so a report from one the user has already ended
        // can't reach into the session that replaced it.
        let currentSession = sessionID
        session.run(progress: { [weak self] percent in
            guard let self, currentSession == self.sessionID,
                  self.state == .autoCapturing else { return }
            self.panel?.updatePercent(percent)
        }, completion: { [weak self] outcome in
            guard let self, currentSession == self.sessionID else { return }
            self.browserSession = nil
            self.finishBrowser(outcome, driver: driver, region: region, screen: screen)
        })
    }

    private func finishBrowser(_ outcome: BrowserScrollSession.Outcome,
                               driver: BrowserScrollDriver,
                               region: NSRect, screen: NSScreen) {
        guard state == .autoCapturing else { return }
        switch outcome {
        case .image(let image):
            state = .finishing
            removeScreenObserver()
            panel?.beginSaving()
            let done = onSaved
            onSaved = nil
            grabber = nil
            deliver(image, scale: captureScale, done: done)
        case .cancelled:
            endBrowserSession()
        case .setupRequired(let error):
            ScrollSessionLog.write("browser: setup required — \(error)")
            endBrowserSession(keepingCallback: true)
            // The alert is modal, so the decision is in before anything else runs.
            isPresentingAlert = true
            let continueManually = ScrollCaptureAlerts.browserOnboarding(family: driver.family)
            isPresentingAlert = false
            // Showing an alert had to activate PICkle, which pushed the browser
            // behind us. Put it back before doing anything else: a manual session is
            // the user scrolling that window, and it can't be scrolled from here.
            reactivateTarget()
            if continueManually {
                ScrollSessionLog.write("mode = manual stitch (fallback from browser)")
                state = .selecting          // the manual session's own entry condition
                startCapturing(region: region, screen: screen)
            } else {
                onSaved = nil
            }
        case .failed:
            endBrowserSession()
            ScrollCaptureAlerts.captureFailed()
        }
    }

    /// Bring the app the user was capturing back to the front. PICkle is an
    /// accessory app that deliberately never activates itself — except that showing
    /// a modal alert must, and that leaves the wrong window in front.
    private func reactivateTarget() {
        guard let bundleID = targetBundleID,
              let app = NSWorkspace.shared.runningApplications
                  .first(where: { $0.bundleIdentifier == bundleID }),
              !app.isActive else { return }
        app.activate()
    }

    /// [Cancel] during an automatic session. The session itself does the tearing
    /// down — it has to put the page back where the user left it first — and reports
    /// `.cancelled` when it has.
    private func cancelBrowserSession() {
        guard state == .autoCapturing else { return }
        browserSession?.cancel()
    }

    /// Take the automatic session's windows down and return to idle.
    ///
    /// - Parameter keepingCallback: hold on to `onSaved` because the same shortcut
    ///   press is about to continue as a manual session and will still want to
    ///   deliver a file at the end of it.
    private func endBrowserSession(keepingCallback: Bool = false) {
        state = .idle
        browserSession = nil
        dismissUI()
        grabber = nil
        if !keepingCallback { onSaved = nil }
    }

    /// - Parameter settle: take one extra frame after a short pause before
    ///   composing. A fling that ends the instant [Done] is pressed leaves the
    ///   bottom of the page still painting, and that frame is what replaces the
    ///   blank tail. Only for finishes the user asked for: hitting the size ceiling
    ///   has nobody waiting on it, and a display change has already invalidated the
    ///   region the extra frame would photograph.
    private func finish(settle: Bool) {
        guard state == .capturing else { return }
        state = .finishing
        stopTicking()
        // Filming is over, so the screen undims — but the controls stay, saying
        // "saving", because composing and encoding a very tall image takes seconds
        // and a UI that just disappeared would read as a crash.
        selector.dismiss()
        removeScreenObserver()
        panel?.beginSaving()
        guard settle, let grabber, let stitcher else { composeAndSave(); return }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.settleDelay) { [weak self] in
            guard let self, self.state == .finishing else { return }
            Task { [weak self] in
                let frame = try? await grabber.grab()
                await MainActor.run { [weak self] in
                    guard let self else { return }
                    // Any way this goes, fall through to composing — a session left
                    // in `.finishing` would strand the panel on "saving" forever.
                    guard let frame, self.state == .finishing else { self.composeAndSave(); return }
                    stitcher.settle(with: frame) { [weak self] in self?.composeAndSave() }
                }
            }
        }
    }

    /// Flatten, encode, and hand the file to the caller. Ends the session whatever
    /// happens, so `.finishing` can never be a dead end.
    private func composeAndSave() {
        let done = onSaved
        let scale = captureScale
        let stitcher = self.stitcher
        self.stitcher = nil
        self.grabber = nil
        self.onSaved = nil
        guard let stitcher else { endSaving(); return }
        stitcher.compose { [weak self] result in
            switch result {
            case .empty:
                // Finished before the first frame ever landed. Nothing to save and
                // nothing went wrong — end quietly rather than cry failure.
                self?.endSaving()
            case .failed:
                self?.endSaving()
                ScrollCaptureAlerts.captureFailed()
            case .image(let image):
                self?.deliver(image, scale: scale, done: done)
            }
        }
    }

    /// Write a finished image into the bottle and end the session. Shared by both
    /// paths, so a hand-stitched capture and a browser capture land as the same kind
    /// of file with the same DPI and the same follow-up.
    ///
    /// Encoding a PNG that may be 30,000px tall takes a beat — it happens off the
    /// main thread so the menu bar doesn't freeze while it lands.
    private func deliver(_ image: CGImage, scale: CGFloat, done: ((URL) -> Void)?) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let url = Self.writePNG(image, scale: scale)
            DispatchQueue.main.async {
                self?.endSaving()
                guard let url else { ScrollCaptureAlerts.captureFailed(); return }
                done?(url)
            }
        }
    }

    /// Take the "saving" panel down and return to idle. Every exit from
    /// `.finishing` goes through here, so the panel can never be stranded.
    private func endSaving() {
        panel?.dismiss()
        panel = nil
        state = .idle
    }

    private func cancel() {
        guard state != .idle, state != .finishing else { return }
        state = .idle
        stopTicking()
        dismissUI()
        stitcher?.discard()
        stitcher = nil
        grabber = nil
        onSaved = nil
    }

    /// A grab threw — the display is gone or ScreenCaptureKit refused. Stop the
    /// session rather than spin on a failing timer.
    private func failSession(_ error: Error) {
        guard state == .capturing else { return }
        NSLog("PICkle scroll capture failed: \(error)")
        cancel()
        ScrollCaptureAlerts.captureFailed()
    }

    // MARK: - Frames

    private func captureFrame() {
        guard state == .capturing, !isBusy, let grabber else { return }
        isBusy = true
        let session = sessionID
        // Each hop back to the main actor re-captures `self` weakly rather than
        // reading the Task's captured variable, which Swift 6 rejects.
        Task { [weak self] in
            do {
                let frame = try await grabber.grab()
                await MainActor.run { [weak self] in self?.consume(frame, session: session) }
            } catch {
                await MainActor.run { [weak self] in
                    self?.handleGrabFailure(error, session: session)
                }
            }
        }
    }

    private func consume(_ frame: CGImage, session: Int) {
        // A frame belonging to a session the user has already ended must not touch
        // the current one — nor its `isBusy`, which now belongs to a live grab.
        guard session == sessionID else { return }
        guard state == .capturing, let stitcher else { isBusy = false; return }
        stitcher.append(frame) { [weak self] progress in
            guard let self, session == self.sessionID else { return }
            self.isBusy = false
            guard self.state == .capturing else { return }
            self.stripCount = progress.stripCount
            self.panel?.updateHeight(progress.heightPixels)
            // A seam is the one failure the user can do something about, and only
            // right now — so it's raised the moment it happens rather than reported
            // over a finished image they can no longer improve.
            if progress.seamCount > self.seamCount {
                self.seamCount = progress.seamCount
                self.panel?.flashSeamWarning()
            }
            if progress.reachedLimit { self.finish(settle: false) }
        }
    }

    private func handleGrabFailure(_ error: Error, session: Int) {
        guard session == sessionID else { return }
        isBusy = false
        failSession(error)
    }

    // MARK: - Teardown helpers

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
        isBusy = false
    }

    private func dismissUI() {
        selector.dismiss()
        panel?.dismiss()
        panel = nil
        removeScreenObserver()
    }

    private func removeScreenObserver() {
        guard let screenObserver else { return }
        NotificationCenter.default.removeObserver(screenObserver)
        self.screenObserver = nil
    }

    /// Plugging in a monitor or changing resolution moves the region out from
    /// under us, so the session can't continue. Rather than throw the work away,
    /// save what's already stitched — unless it's barely anything, in which case
    /// a stray file would be more annoying than losing it.
    private func observeScreenChanges() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            switch self.state {
            case .capturing:
                if self.stripCount >= 2 { self.finish(settle: false) } else { self.cancel() }
            // The region has moved out from under the automatic session too, so it
            // can't photograph any more of the page — but every tile it already has
            // is good, so stop where it is rather than discard them.
            case .autoCapturing:
                self.browserSession?.finishEarly()
            default:
                break
            }
        }
    }

    // MARK: - Output

    /// Write the stitched image into the bottle folder, reusing the shared
    /// timestamped naming rule so it sorts alongside every other capture.
    ///
    /// `rep.size` is set in *points*, which is what makes the PNG record 144dpi on
    /// a Retina capture instead of 72. Without it the image is the right number of
    /// pixels but claims to be twice as big, so Preview and our own editor open it
    /// at 2× while every `screencapture` file opens at 1×.
    private static func writePNG(_ image: CGImage, scale: CGFloat) -> URL? {
        let url = CaptureService.shared.newBottleFileURL()
        let rep = NSBitmapImageRep(cgImage: image)
        let points = max(scale, 1)
        rep.size = NSSize(width: CGFloat(image.width) / points,
                          height: CGFloat(image.height) / points)
        guard let data = rep.representation(using: .png, properties: [:]) else {
            NSLog("PICkle scroll capture: PNG encoding failed")
            return nil
        }
        do { try data.write(to: url) }
        catch {
            NSLog("PICkle scroll capture: write failed \(error)")
            return nil
        }
        return url
    }
}
