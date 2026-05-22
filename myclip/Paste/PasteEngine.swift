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
        // Without Accessibility we still left the payload on the clipboard, the
        // user can ⌘V manually. They grant the permission from the menu bar's
        // "Grant Accessibility…" item.
        guard Accessibility.isTrusted() else { return }
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
