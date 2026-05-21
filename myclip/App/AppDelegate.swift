import AppKit
import GRDB
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var contextMenu: NSMenu!
    private(set) var store: HistoryStore!
    private var monitor: ClipboardMonitor!
    private var popupController: PopupPanelController!
    private var pasteEngine = PasteEngine()
    private var viewModel: PopupViewModel!
    private var blobStore: BlobStore?

    private var historyCap: Int {
        let v = UserDefaults.standard.integer(forKey: "historyCap")
        return v == 0 ? 200 : v
    }
    private var blacklistFromDefaults: Set<String> {
        let raw = UserDefaults.standard.string(forKey: "blacklist") ?? ""
        return Set(raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            "historyCap": 200,
            "blacklist": "com.1password.1password,com.agilebits.onepassword7,com.bitwarden.desktop,com.apple.keychainaccess",
        ])
        setUpStorage()
        setUpStatusItem()
        setUpMonitor()
        setUpPopup()
        // First-run-only system prompt. Subsequent launches never re-prompt.
        Accessibility.promptOnceIfNeeded()
        NotificationCenter.default.addObserver(forName: .myclipClearAll, object: nil, queue: .main) { [weak self] _ in
            try? self?.store.clearAll()
        }
        NotificationCenter.default.addObserver(forName: .myclipExportHistory, object: nil, queue: .main) { [weak self] _ in
            self?.exportHistoryToTextFile()
        }
        NotificationCenter.default.addObserver(forName: .myclipOpenSettings, object: nil, queue: .main) { [weak self] _ in
            self?.showSwiftUISettingsWindow()
        }
    }

    /// Triggers SwiftUI's built-in `Settings` scene. The action must be
    /// dispatched on the next runloop tick — calling it synchronously during
    /// a menu close or panel teardown loses the responder chain that SwiftUI
    /// registered for `showSettingsWindow:`.
    private func showSwiftUISettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            // macOS 14 renamed the selector. Try the new name first, fall back
            // to the legacy one so we work on macOS 13 too.
            let s1 = Selector(("showSettingsWindow:"))
            let s2 = Selector(("showPreferencesWindow:"))
            if NSApp.sendAction(s1, to: nil, from: nil) { return }
            _ = NSApp.sendAction(s2, to: nil, from: nil)
        }
    }

    private func exportHistoryToTextFile() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "myclip-history.txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let items = try store.topNRespectingPins(10_000)
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            var out = "# myclip history export · \(df.string(from: Date())) · \(items.count) items\n\n"
            for item in items {
                let date = Date(timeIntervalSince1970: Double(item.createdAt) / 1000)
                var header = "--- \(df.string(from: date)) [\(item.type)]"
                if item.pinned { header += " 📌" }
                if let src = item.sourceBundle { header += " from \(src)" }
                header += " ---\n"
                out += header
                switch item.type {
                case "text": out += (item.text ?? "") + "\n\n"
                case "file": out += "File: \(item.text ?? "")\n\n"
                case "image": out += "Image blob: \(item.blobPath ?? "")\n\n"
                default: out += "\n"
                }
            }
            try out.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            let alert = NSAlert()
            alert.messageText = "Export failed"
            alert.informativeText = error.localizedDescription
            alert.runModal()
        }
    }

    private func setUpStorage() {
        do {
            let queue = try DatabaseQueue(path: AppPaths.databaseURL.path)
            let blobs = BlobStore(rootDirectory: AppPaths.blobsDirectory)
            store = try HistoryStore(queue: queue, blobStore: blobs)
        } catch {
            NSLog("myclip storage init failed: \(error). Falling back to in-memory.")
            let queue = try! DatabaseQueue()
            store = try! HistoryStore(queue: queue, blobStore: nil)
        }
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = NSImage(systemSymbolName: "doc.on.clipboard",
                               accessibilityDescription: "myclip")
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        // Receive both mouse buttons so we can route left = popup, right = menu.
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        contextMenu = NSMenu()
        contextMenu.addItem(NSMenuItem(title: "Open Popup",
                                       action: #selector(openPopup), keyEquivalent: ""))
        // Dispatch the standard `showSettingsWindow:` selector via the responder
        // chain (target = nil). SwiftUI registers a responder for it on NSApp
        // when the Settings scene is declared, so this opens our SettingsView.
        let settingsItem = NSMenuItem(title: "Settings…",
                                      action: Selector(("showSettingsWindow:")),
                                      keyEquivalent: ",")
        settingsItem.target = nil
        contextMenu.addItem(settingsItem)
        contextMenu.addItem(.separator())
        contextMenu.addItem(NSMenuItem(title: "Grant Accessibility…",
                                       action: #selector(grantAccessibility),
                                       keyEquivalent: ""))
        contextMenu.addItem(.separator())
        contextMenu.addItem(NSMenuItem(title: "Quit myclip",
                                       action: #selector(NSApplication.terminate(_:)),
                                       keyEquivalent: ""))
    }

    private func setUpMonitor() {
        monitor = ClipboardMonitor(
            pasteboard: NSPasteboard.general,
            frontmostBundleID: { NSWorkspace.shared.frontmostApplication?.bundleIdentifier },
            blacklistedBundleIDs: { [weak self] in self?.blacklistFromDefaults ?? [] },
            onCapture: { [weak self] item in
                guard let self else { return }
                do {
                    try self.store.insert(item)
                    try self.store.prune(cap: self.historyCap)
                } catch {
                    NSLog("myclip insert failed: \(error)")
                }
            }
        )
        monitor.start()
    }

    private func setUpPopup() {
        let blobs = BlobStore(rootDirectory: AppPaths.blobsDirectory)
        self.blobStore = blobs
        self.viewModel = PopupViewModel(store: store)
        self.popupController = PopupPanelController(
            store: store,
            viewModel: viewModel,
            pasteEngine: pasteEngine,
            blobStore: blobs
        )

        KeyboardShortcuts.onKeyDown(for: .togglePopup) { [weak self] in
            self?.popupController.toggle(anchorRect: self?.statusItemFrame)
        }
        for n in 1...9 {
            KeyboardShortcuts.onKeyDown(for: .slot(n)) { [weak self] in
                self?.popupController.pasteDirect(slot: n)
            }
        }
    }

    /// Screen-space rect of the status bar icon button — used to anchor the popup.
    private var statusItemFrame: NSRect? {
        statusItem.button?.window?.frame
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        let isContextClick = event.type == .rightMouseUp
            || event.modifierFlags.contains(.control)
        if isContextClick {
            // Temporarily attach the menu so NSStatusBar pops it under the icon,
            // then detach so the next left-click reaches our action again.
            statusItem.menu = contextMenu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            popupController.toggle(anchorRect: statusItemFrame)
        }
    }

    @objc private func openPopup() { popupController.toggle(anchorRect: statusItemFrame) }
    @objc private func openSettings() { showSwiftUISettingsWindow() }
    @objc private func grantAccessibility() {
        // Go straight to System Settings; never re-trigger the system prompt.
        Accessibility.openSystemSettings()
    }
}
