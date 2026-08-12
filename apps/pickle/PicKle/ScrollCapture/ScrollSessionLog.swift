import Foundation

/// A plain text log for scrolling-capture sessions, written to
/// `~/Library/Logs/PICkle/scroll.log`.
///
/// **Why a file and not just `NSLog`.** Measured on this macOS: third-party
/// `NSLog` output is redacted to `<private>` in the unified log, so a user's
/// `log show` transcript of a failed session is a wall of placeholders and
/// diagnoses nothing. Console.app shows it live, but only if the user had it open
/// before the session — which is never. A file the user can attach afterwards is
/// the only channel that actually carries the numbers.
///
/// Both capture paths write here: the general (manual stitcher) one and the
/// browser one. `NSLog` is kept alongside so a developer with Console open still
/// sees the stream in real time.
///
/// Listed in the plan's pre-release removal list along with the P3 counters.
enum ScrollSessionLog {

    /// Trim point, checked once per session. A session writes a few kilobytes, so
    /// this holds many sessions' worth of history while staying mailable.
    private static let maxBytes = 1_048_576

    /// Serial: the manual path logs from the stitcher's own queue, the browser path
    /// from a Task, and the coordinator from main. One writer keeps lines whole.
    private static let queue = DispatchQueue(label: "com.Team-jAm.PICkle.scroll-log", qos: .utility)

    private static let timestamp: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return df
    }()

    static var fileURL: URL {
        let logs = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent("Logs/PICkle", isDirectory: true)
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Logs/PICkle",
                                                                              isDirectory: true)
        return logs.appendingPathComponent("scroll.log")
    }

    /// Open a session: trim the file if it has grown past `maxBytes`, then write a
    /// banner. Trimming here rather than on every line keeps a running session's
    /// writes to a single append each.
    static func startSession(_ description: String) {
        queue.async {
            truncateIfNeeded()
            appendLine("=== session start — \(description) ===")
        }
        NSLog("PICkle scroll: session start — \(description)")
    }

    /// One line, to the file and to `NSLog`.
    static func write(_ message: String) {
        queue.async { appendLine(message) }
        NSLog("PICkle scroll: \(message)")
    }

    // MARK: - File (serial queue only)

    /// Set once the log directory has proved unusable, so a broken Logs folder
    /// costs one line of console output instead of one per write.
    private static var reportedDirectoryFailure = false

    private static func appendLine(_ message: String) {
        let line = "[\(timestamp.string(from: Date()))] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        let url = fileURL
        let manager = FileManager.default
        do {
            try manager.createDirectory(at: url.deletingLastPathComponent(),
                                        withIntermediateDirectories: true)
        } catch {
            // Without this the file logger fails completely silently, and the first
            // anyone knows of it is an empty attachment on a bug report.
            if !reportedDirectoryFailure {
                reportedDirectoryFailure = true
                NSLog("PICkle scroll: cannot create \(url.deletingLastPathComponent().path) "
                    + "— file logging is off for this run (\(error))")
            }
            return
        }
        guard manager.fileExists(atPath: url.path) else {
            try? data.write(to: url)
            return
        }
        guard let handle = try? FileHandle(forWritingTo: url) else { return }
        defer { try? handle.close() }
        _ = try? handle.seekToEnd()
        try? handle.write(contentsOf: data)
    }

    /// Drop the whole file once it passes the cap. Keeping the tail would mean
    /// reading a megabyte back in; a session's own lines are what matter, and the
    /// banner makes the reset obvious.
    private static func truncateIfNeeded() {
        let url = fileURL
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attributes[.size] as? NSNumber, size.intValue > maxBytes else { return }
        try? FileManager.default.removeItem(at: url)
    }
}
