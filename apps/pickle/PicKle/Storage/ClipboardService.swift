import AppKit

/// Copies a screenshot to the system clipboard, and knows whether the sibling
/// app pizzaClip is installed (so we can tailor the confirmation message —
/// pizzaClip watches the clipboard, so a copy effectively lands in its history).
enum ClipboardService {
    /// Bundle id of the sibling clipboard-history app.
    static let pizzaClipBundleID = "com.jekeun.pizzaClip"
    /// PizzaClip product page — where the 🍕 button sends users who don't have the
    /// app installed yet, so they can get it.
    static let pizzaClipPageURL = URL(string: "https://pizza-clip.com/pizzaclip/")!

    /// Write the screenshot to the general pasteboard as both an image and a
    /// file URL, so target apps can take whichever they prefer.
    static func copy(_ url: URL) {
        let pb = NSPasteboard.general
        pb.clearContents()
        var objects: [NSPasteboardWriting] = []
        if let image = NSImage(contentsOf: url) { objects.append(image) }
        objects.append(url as NSURL)
        pb.writeObjects(objects)
    }

    /// True only if pizzaClip is **currently running** on this Mac — i.e. it's
    /// actually watching the clipboard and will catch this copy. Evaluated live
    /// on each user's machine, so every user gets the right message.
    static var isPizzaClipRunning: Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == pizzaClipBundleID
        }
    }

    /// True if PizzaClip is **installed** on this Mac (whether or not it's running),
    /// via a LaunchServices bundle-id lookup. This — not `isPizzaClipRunning` —
    /// gates the 🍕 button: if PizzaClip is installed, a clipboard copy ends up in
    /// its history, so we copy straight away.
    static var isPizzaClipInstalled: Bool {
        NSWorkspace.shared.urlForApplication(withBundleIdentifier: pizzaClipBundleID) != nil
    }

    /// Open the PizzaClip product page in the default browser.
    static func openPizzaClipPage() {
        NSWorkspace.shared.open(pizzaClipPageURL)
    }

    /// The confirmation message to show after a copy.
    static var copyConfirmation: String {
        isPizzaClipRunning
            ? L("clipboard.copied.pizzaClip")
            : L("clipboard.copied.plain")
    }
}
