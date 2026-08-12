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

    /// A timestamped path in the bottle folder, guaranteed not to collide with an
    /// existing file (two captures in the same second get ` (2)`, ` (3)`, …).
    /// Internal (not private) so other capture paths — e.g. scrolling capture,
    /// which writes its stitched PNG itself — land on the same naming rule.
    func newBottleFileURL() -> URL {
        let dir = AppPaths.bottleDirectory
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
        let base = "PICkle \(df.string(from: Date()))"

        var url = dir.appendingPathComponent("\(base).png")
        var n = 2
        while FileManager.default.fileExists(atPath: url.path) {
            url = dir.appendingPathComponent("\(base) (\(n)).png")
            n += 1
        }
        return url
    }
}
