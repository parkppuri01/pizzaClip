import AppKit

public final class PasteEngine {
    public init() {}

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
            if let blobPath = item.blobPath, let blobs = blobStore {
                let fileURL = blobs.rootDirectory.appendingPathComponent(blobPath)
                if let data = try? Data(contentsOf: fileURL) {
                    let ext = (blobPath as NSString).pathExtension.lowercased()
                    let originalType = PasteEngine.pasteboardType(forImageExtension: ext)
                    pb.setData(data, forType: originalType)
                    // For non-PNG formats, also add a PNG representation as a
                    // fallback for apps that only accept .png on the pasteboard.
                    // NSImage handles JPG / HEIC / GIF / TIFF / BMP / WebP, so
                    // this round-trip works without app-specific code.
                    if originalType != .png,
                       let img = NSImage(data: data),
                       let tiff = img.tiffRepresentation,
                       let rep = NSBitmapImageRep(data: tiff),
                       let png = rep.representation(using: .png, properties: [:]) {
                        pb.setData(png, forType: .png)
                    }
                }
            }
            // If this image was captured from a Finder file copy, also expose
            // the original file URL so apps that prefer file references
            // (Finder paste, Slack uploads) pick up the file.
            if let originalPath = item.text {
                let fileURL = URL(fileURLWithPath: originalPath)
                if FileManager.default.fileExists(atPath: fileURL.path) {
                    pb.writeObjects([fileURL as NSURL])
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
        // Without Accessibility we still left the payload on the clipboard so
        // the user can ⌘V manually — but the silent no-op was confusing on
        // rebuilds that revoke the TCC grant. Surface an alert so the cause
        // is obvious instead of "paste hotkey just doesn't work."
        guard Accessibility.isTrusted() else {
            PasteEngine.notifyMissingAccessibility(action: "Paste")
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.sendCommandV() }
    }

    /// Paste a sequence of items into the previously frontmost app, one
    /// after the other. Each step: write to pasteboard → synthesize ⌘V,
    /// staggered so the target app finishes processing one paste before the
    /// next pasteboard rewrite arrives. The final pasteboard state is
    /// `items.last`.
    public func pasteSequence(_ items: [Item], blobStore: BlobStore?, bundleID: String?) {
        guard !items.isEmpty else { return }

        if let id = bundleID,
           let app = NSRunningApplication.runningApplications(withBundleIdentifier: id).first {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        // Without Accessibility we can't synthesize ⌘V. Don't silently leave
        // a single item on the pasteboard — that's confusing UX (looks like
        // the feature half-worked). Skip the paste entirely and surface a
        // notification so the user knows to grant the permission.
        guard Accessibility.isTrusted() else {
            PasteEngine.notifyMissingAccessibility(action: "9 → 1 full paste")
            return
        }
        // 0.18s per item is enough for most editors (Notes, TextEdit, VSCode,
        // browsers) to finish processing the previous paste before the next
        // pasteboard write arrives. Tighter values cause some apps to drop
        // intermediate pastes.
        let perItemDelay: TimeInterval = 0.18
        for (i, item) in items.enumerated() {
            let when = DispatchTime.now() + 0.10 + Double(i) * perItemDelay
            DispatchQueue.main.asyncAfter(deadline: when) { [weak self] in
                guard let self else { return }
                self.write(item, blobStore: blobStore)
                // Tiny gap so the pasteboard write commits before the
                // synthesized ⌘V keystroke is dispatched.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    self.sendCommandV()
                }
            }
        }
    }

    /// Alerts the user when a paste action is invoked without the
    /// Accessibility permission needed to synthesize ⌘V. Ad-hoc rebuilds
    /// revoke TCC grants (cdhash changes), so this catches the common case
    /// where the user just installed a new build and forgot to re-grant.
    /// Runs on the next runloop tick so any popup teardown in progress
    /// finishes before the modal alert takes key status.
    private static func notifyMissingAccessibility(action: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "pizzaClip needs Accessibility to paste"
            alert.informativeText = "Couldn't run \"\(action)\" — the paste keystroke requires Accessibility. Grant it in System Settings → Privacy & Security → Accessibility, then quit and relaunch pizzaClip."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Open Settings")
            alert.addButton(withTitle: "Cancel")
            if alert.runModal() == .alertFirstButtonReturn {
                Accessibility.openSystemSettings()
            }
        }
    }

    private func sendCommandV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        // Explicitly press and release the CMD key around V. Setting only
        // `event.flags = .maskCommand` without ever emitting a real cmd-down
        // event works for a single paste, but rapid-succession ⌘V (e.g. the
        // 9 → 1 full-paste sequence) drops the 2nd+ event because macOS
        // tracks modifier-key state internally and the synthetic V keystrokes
        // never look like real ⌘-V to it.
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: true)   // left ⌘
        let vDown = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true)
        vDown?.flags = .maskCommand
        let vUp = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
        vUp?.flags = .maskCommand
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: false)
        cmdDown?.post(tap: .cghidEventTap)
        vDown?.post(tap: .cghidEventTap)
        vUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)
    }

    private static func pasteboardType(forImageExtension ext: String) -> NSPasteboard.PasteboardType {
        switch ext.lowercased() {
        case "png":           return .png
        case "jpg", "jpeg":   return NSPasteboard.PasteboardType("public.jpeg")
        case "heic", "heif":  return NSPasteboard.PasteboardType("public.heic")
        case "gif":           return NSPasteboard.PasteboardType("com.compuserve.gif")
        case "tiff", "tif":   return .tiff
        case "bmp":           return NSPasteboard.PasteboardType("com.microsoft.bmp")
        case "webp":          return NSPasteboard.PasteboardType("public.webp")
        default:              return .png   // best-effort fallback
        }
    }
}
