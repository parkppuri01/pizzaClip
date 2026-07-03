import AppKit
import GRDB
import KeyboardShortcuts
import Sparkle

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var contextMenu: NSMenu!
    // Auto-update. Starts the updater immediately; checks run on the
    // SUScheduledCheckInterval (24h) against SUFeedURL. Whether a found
    // update downloads+installs silently vs. only notifies is driven by
    // `automaticallyDownloadsUpdates`, which Sparkle reads live from the
    // SUAutomaticallyUpdate default — bound to the Settings checkbox.
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
    private(set) var store: HistoryStore!
    private var monitor: ClipboardMonitor!
    private var popupController: PopupPanelController!
    private var pasteEngine = PasteEngine()
    private var viewModel: PopupViewModel!
    private var blobStore: BlobStore?

    private var historyCap: Int {
        let v = UserDefaults.standard.integer(forKey: "historyCap")
        return v == 0 ? 9 : v
    }
    private var blacklistFromDefaults: Set<String> {
        let raw = UserDefaults.standard.string(forKey: "blacklist") ?? ""
        return Set(raw.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty })
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.register(defaults: [
            "historyCap": 9,
            "blacklist": "com.1password.1password,com.agilebits.onepassword7,com.bitwarden.desktop,com.apple.keychainaccess",
        ])
        // Migrations for users coming from previous default values:
        //  - >20: clamp to 20 (Settings stepper now caps at 20)
        //  - 10 once: previous default we shipped; nudge to the new 9 default
        //    a single time so users who never customized see the new value.
        //    A guarded flag prevents re-applying if a user later sets it back
        //    to 10 on purpose.
        let cap = UserDefaults.standard.integer(forKey: "historyCap")
        if cap > 20 { UserDefaults.standard.set(20, forKey: "historyCap") }
        if cap == 10, !UserDefaults.standard.bool(forKey: "didMigrateCapTo9") {
            UserDefaults.standard.set(9, forKey: "historyCap")
        }
        UserDefaults.standard.set(true, forKey: "didMigrateCapTo9")
        setUpStorage()
        setUpStatusItem()
        setUpMonitor()
        setUpPopup()
        // First-run-only system prompt. Subsequent launches never re-prompt.
        Accessibility.promptOnceIfNeeded()
        // One-time 0.1.5 → 0.1.6 migration alert: code-signing identity changed
        // from self-signed `projectJAM1s` to Developer ID, which forces TCC to
        // treat pizzaClip as a "different app" — existing users have to remove
        // the old Accessibility entry and re-add. Guide them through it once.
        showDeveloperIDMigrationAlertIfNeeded()
        NotificationCenter.default.addObserver(forName: .pizzaClipClearAll, object: nil, queue: .main) { [weak self] _ in
            try? self?.store.clearAll()
        }
        NotificationCenter.default.addObserver(forName: .pizzaClipExportHistory, object: nil, queue: .main) { [weak self] _ in
            self?.exportHistoryToTextFile()
        }
        NotificationCenter.default.addObserver(forName: .pizzaClipOpenSettings, object: nil, queue: .main) { [weak self] _ in
            self?.showSwiftUISettingsWindow()
        }
        // Status bar pizza reflects the current item count. Re-render every
        // time the store changes (insert / delete / pin / clearAll all fire
        // `.pizzaClipHistoryChanged`). `prune` is silent but always runs right
        // after insert from the monitor's onCapture closure, so by the time
        // the notification reaches us the count is post-prune.
        refreshStatusIcon()
        NotificationCenter.default.addObserver(forName: .pizzaClipHistoryChanged,
                                               object: nil, queue: .main) { [weak self] _ in
            self?.refreshStatusIcon()
        }
        // Right ⌘ → Hangul/Latin toggle. Off by default; user opts in from
        // Settings → Shortcuts. The toggle change fires a notification so we
        // can flip the event tap live without restarting.
        if UserDefaults.standard.bool(forKey: "rightCommandHangulToggle") {
            HangulToggler.shared.setEnabled(true)
        }
        NotificationCenter.default.addObserver(forName: .pizzaClipHangulToggleChanged,
                                               object: nil, queue: .main) { notification in
            guard let value = notification.object as? NSNumber else { return }
            HangulToggler.shared.setEnabled(value.boolValue)
        }
    }

    private func refreshStatusIcon() {
        let count = (try? store.count()) ?? 0
        statusItem.button?.image = PizzaIcon.image(forCount: count)
    }

    /// Opens the SwiftUI `Settings` scene by synthesizing the Cmd+, keystroke
    /// that macOS handles natively. We tried `NSApp.sendAction("showSettingsWindow:")`
    /// first, but recent macOS releases log a "use SettingsLink" warning and
    /// treat the selector as a no-op. The synthesized key event goes through
    /// the same native dispatch as a real Cmd+, press, which we know works.
    private func showSwiftUISettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async {
            guard let event = NSEvent.keyEvent(
                with: .keyDown,
                location: .zero,
                modifierFlags: .command,
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: 0,
                context: nil,
                characters: ",",
                charactersIgnoringModifiers: ",",
                isARepeat: false,
                keyCode: 0x2B   // virtual code for comma
            ) else { return }
            NSApp.postEvent(event, atStart: false)
        }
    }

    private func exportHistoryToTextFile() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "pizzaClip-history.txt"
        panel.allowedContentTypes = [.plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            let items = try store.topNRespectingPins(10_000)
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd HH:mm:ss"
            var out = "# pizzaClip history export · \(df.string(from: Date())) · \(items.count) items\n\n"
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
            alert.messageText = L("Export failed", "내보내기 실패")
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
            NSLog("pizzaClip storage init failed: \(error). Falling back to in-memory.")
            let queue = try! DatabaseQueue()
            store = try! HistoryStore(queue: queue, blobStore: nil)
        }
    }

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        guard let button = statusItem.button else { return }
        button.image = PizzaIcon.image(forCount: 0)
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        // Receive both mouse buttons so we can route left = popup, right = menu.
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])

        contextMenu = NSMenu()
        contextMenu.addItem(NSMenuItem(title: L("Open Popup", "팝업 열기"),
                                       action: #selector(openPopup), keyEquivalent: ""))
        contextMenu.addItem(NSMenuItem(title: L("Settings…", "설정…"),
                                       action: #selector(openSettings),
                                       keyEquivalent: ","))
        let checkForUpdatesItem = NSMenuItem(
            title: L("Check for Updates…", "업데이트 확인…"),
            action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: "")
        // Target = the updater controller; it auto-enables/disables this item
        // via canCheckForUpdates (e.g. greyed out while a check is in flight).
        checkForUpdatesItem.target = updaterController
        contextMenu.addItem(checkForUpdatesItem)
        contextMenu.addItem(.separator())
        contextMenu.addItem(NSMenuItem(title: L("Grant Accessibility…", "손쉬운 사용 권한 부여…"),
                                       action: #selector(grantAccessibility),
                                       keyEquivalent: ""))
        contextMenu.addItem(.separator())
        contextMenu.addItem(NSMenuItem(title: L("Quit pizzaClip", "pizzaClip 종료"),
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
                    NSLog("pizzaClip insert failed: \(error)")
                }
                // Easter egg: only the literal single word "pizza" (case
                // insensitive) or the Korean "피자" (exact, no case folding
                // needed for Hangul) triggers the burst. Substring matching
                // was too eager — any sentence mentioning pizza in passing
                // kept hijacking the popup.
                if let text = item.text {
                    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.lowercased() == "pizza" || trimmed == "피자" {
                        self.popupController.showWithPizzaBurst(anchorRect: self.statusItemFrame)
                    }
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

    private func showDeveloperIDMigrationAlertIfNeeded() {
        let migrateKey = "didMigrateToDeveloperID"
        let prevPromptKey = "didShowAccessibilityPrompt"
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: migrateKey) else { return }
        defaults.set(true, forKey: migrateKey)
        // Fresh installs go through the normal Accessibility.promptOnceIfNeeded
        // path — skip the migration alert for them.
        guard defaults.bool(forKey: prevPromptKey) else { return }

        let alert = NSAlert()
        alert.messageText = L("Accessibility re-approval required (0.1.5 → 0.1.6)",
                              "권한 재승인이 필요합니다 (0.1.5 → 0.1.6)")
        alert.informativeText = L(
            """
            The code signature was upgraded from self-signed to an Apple Developer ID.
            macOS security policy requires you to grant Accessibility permission once more.

            1. Click "Open System Settings" below
            2. In the Accessibility list, select the old pizzaClip entry → remove it with "−"
            3. Re-add pizzaClip with "+" (or the automatic dialog) → turn the toggle ON

            This is only needed once. Later versions keep the permission automatically.
            """,
            """
            코드 서명을 자체서명 → Apple Developer ID 로 업그레이드했습니다.
            macOS 보안 정책상 손쉬운 사용 권한을 1회 다시 부여해야 합니다.

            1. 아래 "시스템 설정 열기" 클릭
            2. 손쉬운 사용 목록에서 기존 pizzaClip 항목 선택 → "−" 로 제거
            3. "+" 또는 자동 다이얼로그로 pizzaClip 다시 추가 → 토글 ON

            이번 1회만 필요합니다. 이후 버전은 자동으로 유지됩니다.
            """)
        alert.addButton(withTitle: L("Open System Settings", "시스템 설정 열기"))
        alert.addButton(withTitle: L("Later", "나중에"))
        if alert.runModal() == .alertFirstButtonReturn {
            Accessibility.openSystemSettings()
        }
    }
}
