import AppKit
import SwiftUI

final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if let w = window {
            w.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        let host = NSHostingController(rootView: SettingsView())
        let w = NSWindow(contentViewController: host)
        w.title = "myclip Settings"
        w.styleMask = [.titled, .closable, .miniaturizable]
        w.setContentSize(NSSize(width: 540, height: 420))
        w.center()
        w.isReleasedWhenClosed = false
        self.window = w
        w.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
