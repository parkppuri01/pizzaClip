import AppKit

/// What to do with a captured region — fixed by which shortcut was pressed
/// (⇧⌥A clipboard · ⇧⌥S save · ⇧⌥D editor).
enum CaptureMode {
    case clipboard   // → straight to the clipboard, NOT saved to the bottle
    case save        // → saved to the bottle folder
    case editor      // → saved, then opened in the editor
}

/// Interactive screen capture for PICkle. We shell out to macOS's own
/// `screencapture -i` (driven by WindowServer) rather than opening our own
/// selection overlay: any app-owned window would dismiss whatever menu or
/// status-bar popup is showing, but the OS capture leaves them open — just like
/// ⌘⇧4. And because `-i` is user-driven (the user drags the region themselves),
/// the OS grants it without our spawned process needing to inherit PICkle's
/// Screen Recording TCC grant (the reason a non-interactive `-R` shell-out fails).
/// The pointer's live pixel dimensions and Space-to-move come built into the OS UI.
final class CaptureService {
    static let shared = CaptureService()
    private init() {}

    /// `screencapture -i` to a new file in the bottle folder. Cancel (Esc / no
    /// drag) leaves no file → completion(nil).
    func interactiveCaptureToFile(completion: @escaping (URL?) -> Void) {
        let url = newBottleFileURL()
        runScreencapture(["-i", url.path], fileURL: url, completion: completion)
    }

    /// `screencapture -i -c` straight to the clipboard (nothing saved).
    func interactiveCaptureToClipboard() {
        runScreencapture(["-i", "-c"], fileURL: nil) { _ in }
    }

    /// Launch `screencapture` asynchronously (its `-i` UI blocks until the user
    /// finishes, so we must NOT run it on the main thread). `terminationHandler`
    /// fires when the user commits or cancels. In file mode, screencapture only
    /// writes the file if a region was actually chosen, so "file exists" = success
    /// and "no file" = the user pressed Esc / clicked without dragging.
    private func runScreencapture(_ args: [String], fileURL: URL?, completion: @escaping (URL?) -> Void) {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        proc.arguments = args
        proc.terminationHandler = { _ in
            DispatchQueue.main.async {
                guard let fileURL else { completion(nil); return }
                let ok = FileManager.default.fileExists(atPath: fileURL.path)
                completion(ok ? fileURL : nil)
            }
        }
        do { try proc.run() }
        catch {
            NSLog("PICkle screencapture launch failed: \(error)")
            DispatchQueue.main.async { completion(nil) }
        }
    }

    /// Highest number handed out per day prefix. A path is chosen *before* its file
    /// exists — `screencapture -i` only writes once the user finishes dragging — so
    /// the folder alone can't tell a second capture started meanwhile (a scrolling
    /// capture saving, another shortcut) that the number is taken.
    private var issued: [String: Int] = [:]
    private let issueLock = NSLock()

    /// A new path in the bottle folder named `ScreenShot_YYMMDD_NNN.png` — no
    /// spaces and no dots except the extension (names like
    /// `PICkle 2026-07-03 at 14.30.12.png` tripped up other tools). NNN is a
    /// per-day counter: one past the highest number already used today, on disk or
    /// handed out to a capture still in progress, so a deleted file never causes a
    /// collision and two overlapping captures never share a name. Internal (not
    /// private) so other capture paths — e.g. scrolling capture, which writes its
    /// stitched PNG itself — land on the same naming rule.
    func newBottleFileURL() -> URL {
        let dir = AppPaths.bottleDirectory
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyMMdd"
        let prefix = "ScreenShot_\(df.string(from: Date()))_"

        issueLock.lock()
        defer { issueLock.unlock() }
        let existing = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        let used = existing.compactMap { name -> Int? in
            guard name.hasPrefix(prefix) else { return nil }
            let rest = (name.dropFirst(prefix.count) as Substring).split(separator: ".").first ?? ""
            // A hand-renamed file with an absurd number must not overflow `+ 1`.
            return Int(rest).flatMap { $0 < 1_000_000 ? $0 : nil }
        }
        var n = max(used.max() ?? 0, issued[prefix] ?? 0) + 1
        var url = dir.appendingPathComponent(String(format: "%@%03d.png", prefix, n))
        while FileManager.default.fileExists(atPath: url.path) {
            n += 1
            url = dir.appendingPathComponent(String(format: "%@%03d.png", prefix, n))
        }
        issued = [prefix: n]   // older days can never be issued again
        return url
    }
}
