import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                   accessibilityDescription: "myclip")
        }

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Popup",
                                action: #selector(openPopup),
                                keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings…",
                                action: #selector(openSettings),
                                keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit myclip",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: ""))
        statusItem.menu = menu
    }

    @objc private func openPopup() {
        // wired in Task 11
        NSSound.beep()
    }

    @objc private func openSettings() {
        // wired in Task 15
        NSSound.beep()
    }
}
