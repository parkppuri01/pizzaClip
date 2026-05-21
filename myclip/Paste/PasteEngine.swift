import AppKit

public final class PasteEngine {
    public init() {}

    public var hasAccessibility: Bool { Accessibility.isTrusted() }

    public func write(_ item: Item, blobStore: BlobStore?) {
        let pb = NSPasteboard.general
        pb.clearContents()
        switch item.type {
        case "text":
            if let text = item.text { pb.setString(text, forType: .string) }
        case "file":
            if let path = item.text {
                let url = URL(fileURLWithPath: path)
                pb.writeObjects([url as NSURL])
            }
        case "image":
            if let path = item.blobPath, let blobs = blobStore {
                let fileURL = blobs.rootDirectory.appendingPathComponent(path)
                if let data = try? Data(contentsOf: fileURL) {
                    pb.setData(data, forType: .png)
                }
            }
        default: break
        }
    }

    public func pasteIntoPreviousApp(bundleID: String?) {
        if let id = bundleID,
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: id).first {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        guard hasAccessibility else {
            NotificationCenter.default.post(name: .myclipNeedsAccessibility, object: nil)
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.sendCommandV() }
    }

    private func sendCommandV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
    }
}

extension Notification.Name {
    static let myclipNeedsAccessibility = Notification.Name("myclipNeedsAccessibility")
}
