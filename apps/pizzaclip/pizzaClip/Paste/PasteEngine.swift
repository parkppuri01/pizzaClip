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
            PasteEngine.notifyMissingAccessibility(action: L("Paste", "붙여넣기"))
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { self.sendCommandV() }
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
            alert.messageText = L("pizzaClip needs Accessibility to paste",
                                  "붙여넣으려면 손쉬운 사용 권한이 필요합니다")
            alert.informativeText = L(
                "Couldn't run \"\(action)\" — the paste keystroke requires Accessibility. Grant it in System Settings → Privacy & Security → Accessibility, then quit and relaunch pizzaClip.",
                "\"\(action)\" 동작을 실행할 수 없습니다 — 붙여넣기 입력에는 손쉬운 사용 권한이 필요합니다. 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 권한을 준 뒤 pizzaClip을 종료 후 다시 실행하세요.")
            alert.alertStyle = .warning
            alert.addButton(withTitle: L("Open Settings", "설정 열기"))
            alert.addButton(withTitle: L("Cancel", "취소"))
            if alert.runModal() == .alertFirstButtonReturn {
                Accessibility.openSystemSettings()
            }
        }
    }

    private func sendCommandV() {
        let src = CGEventSource(stateID: .combinedSessionState)
        // Explicitly press and release the CMD key around V. Setting only
        // `event.flags = .maskCommand` without ever emitting a real cmd-down
        // event works for a single paste, but rapid-succession ⌘V drops the
        // 2nd+ event because macOS tracks modifier-key state internally and the
        // synthetic V keystrokes never look like real ⌘-V to it.
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
