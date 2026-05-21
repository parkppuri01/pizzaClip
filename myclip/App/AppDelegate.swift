import AppKit
import GRDB
import KeyboardShortcuts

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private(set) var store: HistoryStore!
    private var monitor: ClipboardMonitor!
    private var popupController: PopupPanelController!
    private var pasteEngine = PasteEngine()
    private var viewModel: PopupViewModel!
    private var blobStore: BlobStore?
    private let settings = SettingsWindowController()
    private var hasShownAccessibilityPrompt = false

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
        if !Accessibility.isTrusted(prompt: true) {
            NSLog("Accessibility permission not granted; auto-paste disabled until granted.")
        }
        NotificationCenter.default.addObserver(
            forName: .myclipNeedsAccessibility, object: nil, queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            // Re-check trust so a grant during this session silences future prompts
            // without restart, and rate-limit to once per session so a user who
            // dismissed the dialog isn't nagged on every paste.
            if Accessibility.isTrusted() { return }
            if self.hasShownAccessibilityPrompt { return }
            self.hasShownAccessibilityPrompt = true

            let alert = NSAlert()
            alert.messageText = "Enable Accessibility for auto-paste"
            alert.informativeText = "myclip needs Accessibility access to type ⌘V into the previous app. The clipboard already holds your selection — you can ⌘V manually too."
            alert.addButton(withTitle: "Open System Settings")
            alert.addButton(withTitle: "Later")
            if alert.runModal() == .alertFirstButtonReturn {
                Accessibility.openSystemSettings()
            }
        }
        NotificationCenter.default.addObserver(forName: .myclipClearAll, object: nil, queue: .main) { [weak self] _ in
            try? self?.store.clearAll()
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
        statusItem.button?.image = NSImage(systemSymbolName: "doc.on.clipboard",
                                           accessibilityDescription: "myclip")
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Open Popup",
                                action: #selector(openPopup), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Settings…",
                                action: #selector(openSettings), keyEquivalent: ","))
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit myclip",
                                action: #selector(NSApplication.terminate(_:)),
                                keyEquivalent: ""))
        statusItem.menu = menu
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
            self?.popupController.toggle()
        }
        for n in 1...9 {
            KeyboardShortcuts.onKeyDown(for: .slot(n)) { [weak self] in
                self?.popupController.pasteDirect(slot: n)
            }
        }
    }

    @objc private func openPopup() { popupController.toggle() }
    @objc private func openSettings() { settings.show() }
}
