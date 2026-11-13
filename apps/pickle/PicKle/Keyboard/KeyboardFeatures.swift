import AppKit
import ApplicationServices
import IOKit

/// Coordinates PICkle's two keyboard extras (both opt-in, off by default):
///
///  - **Right ⌘ = Korean/English** (gksdud's method): right ⌘ is remapped to a
///    function key in HID, macOS's "Select the previous input source" shortcut
///    is bound to that key, and the event tap fires the shortcut on press.
///    Right ⌘ stops working as ⌘. If this Mac's shortcut is already on an
///    unmodified F13–F19 key, that key is adopted and nothing in System
///    Settings is touched ("adopted"); otherwise PICkle binds a free F-key and
///    restores the user's shortcut when turned off ("owned").
///  - **Right ⌥ alone = Emoji & Symbols**: a lone right-⌥ tap posts ⌃⌘Space.
///    Right ⌥ keeps working as ⌥.
///
/// Invariant that keeps right ⌘ usable: while the HID mapping exists, the
/// shortcut stays bound to the mapped key. So the shortcut is written before
/// the mapping and restored only after every mapping is gone. Without the tap
/// (no Accessibility permission, secure input) the mapping still switches,
/// just on release.
final class KeyboardFeatures: ObservableObject {
    static let shared = KeyboardFeatures()

    private static let hangulKey = "kbd.rightCmdHangul"
    private static let emojiKey = "kbd.rightOptEmoji"
    private static let targetKey = "kbd.targetKeyCode"
    private static let modeKey = "kbd.shortcutMode"
    private static let noticeKey = "kbd.notice"
    private static let gksdudBundleID = "io.gksdud.inputswitch"
    private static let pizzaClipDomain = "com.jekeun.pizzaClip" as CFString

    @Published private(set) var hangulEnabled: Bool
    @Published private(set) var emojiEnabled: Bool
    @Published private(set) var permissionGranted = AXIsProcessTrusted()
    @Published private(set) var activeKey: FunctionKey?
    @Published private(set) var activeMode: InputSourceShortcut.Mode?
    @Published private(set) var failedKeyboards: [String] = []
    @Published private(set) var errorMessage: String?
    @Published private(set) var notice: String?
    @Published private(set) var otherInstanceRunning = false
    @Published private(set) var pizzaClipToggleOn = false
    @Published private(set) var karabinerPresent = false

    private let tap = KeyEventTap()
    private var started = false
    private var isApplying = false
    private var sessionAway = false
    private var suddenTerminationDisabled = false
    private var permissionTimer: Timer?
    private var integrityTimer: Timer?
    private var hotplugPort: IONotificationPortRef?
    private var hotplugIterator: io_iterator_t = 0

    private init() {
        let defaults = UserDefaults.standard
        hangulEnabled = defaults.bool(forKey: Self.hangulKey)
        emojiEnabled = defaults.bool(forKey: Self.emojiKey)
        notice = defaults.string(forKey: Self.noticeKey)
    }

    // MARK: - Lifecycle

    /// Called once from `applicationDidFinishLaunching`.
    func start() {
        guard !started else { return }
        started = true
        let me = Bundle.main.bundleIdentifier ?? ""
        otherInstanceRunning = NSRunningApplication.runningApplications(withBundleIdentifier: me)
            .contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        // Two copies (say the installed app and a dev build) share these
        // settings; only one may own the keyboard.
        guard !otherInstanceRunning else { return }

        KeyboardRemapper.forgetRecordsFromPreviousBoot()
        installObservers()
        refreshEnvironment()
        if hangulEnabled && gksdudRunning() {
            // gksdud started first (both login items, say): two taps on the
            // same F-key must never run together.
            turnOffHangul(notice: L("settings.input.notice.gksdud"))
        } else if hangulEnabled {
            applyHangul(userInitiated: false)
        } else {
            restoreSystem()   // leftovers from a crash while turning off
        }
        updateTap()
        updateTimers()
    }

    /// Undo system changes on quit (menu Quit, logout, Sparkle relaunch,
    /// SIGTERM). The on/off choices stay saved; the next launch re-applies.
    /// Never blocks quitting.
    func prepareForQuit() {
        tap.stop()
        guard started, !otherInstanceRunning else { return }
        restoreSystem()
    }

    // MARK: - Toggles

    func setHangul(_ on: Bool) {
        guard started, !otherInstanceRunning, on != hangulEnabled else { return }
        setNotice(nil)
        errorMessage = nil
        if on {
            if gksdudRunning() {
                errorMessage = L("settings.input.error.gksdud")
                return
            }
            hangulEnabled = true
            UserDefaults.standard.set(true, forKey: Self.hangulKey)
            applyHangul(userInitiated: true)
            if hangulEnabled && !permissionGranted { requestPermission() }
        } else {
            turnOffHangul(notice: nil)
        }
        updateTap()
        updateTimers()
    }

    func setEmoji(_ on: Bool) {
        guard started, !otherInstanceRunning, on != emojiEnabled else { return }
        emojiEnabled = on
        UserDefaults.standard.set(on, forKey: Self.emojiKey)
        if on && !permissionGranted { requestPermission() }
        updateTap()
        updateTimers()
    }

    // MARK: - Permission

    func requestPermission() {
        let prompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        _ = AXIsProcessTrustedWithOptions([prompt: true] as CFDictionary)
        updateTimers()
    }

    func openAccessibilitySettings() {
        guard let url = URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else { return }
        NSWorkspace.shared.open(url)
    }

    /// Re-read everything shown in Settings (called when the tab appears).
    func refreshEnvironment() {
        checkPermission()
        pizzaClipToggleOn = (CFPreferencesCopyAppValue("rightCommandHangulToggle" as CFString,
                                                       Self.pizzaClipDomain) as? Bool) == true
        karabinerPresent = KeyboardRemapper.karabinerPresent()
    }

    private func checkPermission() {
        // A second instance only shows the tab; it must never start a tap or
        // timers (they would fight the first instance over the keyboard).
        guard started, !otherInstanceRunning else { return }
        let granted = AXIsProcessTrusted()
        guard granted != permissionGranted else { return }
        permissionGranted = granted
        updateTap()
        updateTimers()
    }

    // MARK: - Korean/English: apply / restore

    private var savedTarget: FunctionKey? {
        let code = UserDefaults.standard.object(forKey: Self.targetKey) as? Int
        return code.flatMap(FunctionKey.withKeyCode)
    }

    private var savedMode: InputSourceShortcut.Mode? {
        UserDefaults.standard.string(forKey: Self.modeKey).flatMap(InputSourceShortcut.Mode.init)
    }

    /// Bind the shortcut (owned mode only), then map right ⌘ on every keyboard.
    /// Safe to repeat: everything already in place is left as it is.
    ///
    /// On failure a toggle the user just flipped goes back off; a failure at
    /// launch or on a retry keeps their choice (the 30 s check tries again —
    /// right after login `activateSettings` can fail once).
    private func applyHangul(userInitiated: Bool) {
        guard hangulEnabled, !isApplying, !sessionAway else { return }

        let target: FunctionKey
        let mode: InputSourceShortcut.Mode
        if savedMode == .owned, let key = savedTarget, InputSourceShortcut.isBound(to: key) {
            // Still bound by us from before; choosing again would mistake our
            // own binding for the user's and adopt it.
            (target, mode) = (key, .owned)
        } else if let choice = InputSourceShortcut.chooseTarget(
            usedByMappings: KeyboardRemapper.functionKeysUsedByOtherMappings()) {
            (target, mode) = choice
        } else {
            failToApply(L("settings.input.error.noFreeKey"), userInitiated: userInitiated)
            return
        }

        if savedMode == .owned && mode == .adopted {
            // The user rebound the shortcut to an F-key while PICkle owned it:
            // their new binding stands, the old backup is stale.
            InputSourceShortcut.forgetBackup()
        }

        isApplying = true
        // Saved before the shortcut is written: if PICkle dies mid-write, the
        // next launch must still know the binding is its own (and restore the
        // backup) instead of adopting it as the user's.
        let defaults = UserDefaults.standard
        defaults.set(target.keyCode, forKey: Self.targetKey)
        defaults.set(mode.rawValue, forKey: Self.modeKey)

        if mode == .owned && !InputSourceShortcut.isBound(to: target) {
            do {
                try InputSourceShortcut.bind(to: target)
            } catch {
                isApplying = false
                failToApply(error.localizedDescription, userInitiated: userInitiated)
                return
            }
        }

        // A different key than before (the user rebound the shortcut): the
        // mapping follows it.
        failedKeyboards = KeyboardRemapper.apply(target: target, claimUnrecorded: mode == .owned)
        activeKey = target
        activeMode = mode
        errorMessage = nil
        setSuddenTermination(disabled: true)
        isApplying = false
    }

    /// Re-map keyboards only (hot-plug, wake, a mapping wiped by someone else).
    private func reapplyMappings() {
        guard hangulEnabled, !isApplying, !sessionAway, let key = activeKey else { return }
        failedKeyboards = KeyboardRemapper.apply(target: key, claimUnrecorded: activeMode == .owned)
    }

    /// Remove the mappings, then — only once none is left — put the user's
    /// shortcut back if PICkle had bound it. Returns false if something is
    /// left to retry.
    @discardableResult
    private func restoreSystem(mappingsOnly: Bool = false) -> Bool {
        guard !isApplying else { return false }
        isApplying = true
        defer { isApplying = false }

        guard KeyboardRemapper.restore() else { return false }
        if mappingsOnly { return true }
        if savedMode == .owned {
            do { try InputSourceShortcut.restore(ownedKey: savedTarget) } catch { return false }
        }
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: Self.targetKey)
        defaults.removeObject(forKey: Self.modeKey)
        activeKey = nil
        activeMode = nil
        failedKeyboards = []
        setSuddenTermination(disabled: false)
        return true
    }

    private func turnOffHangul(notice: String?) {
        hangulEnabled = false
        UserDefaults.standard.set(false, forKey: Self.hangulKey)
        updateTap()
        restoreSystem()
        setNotice(notice)
    }

    /// Undo whatever got applied (the shortcut backup, a crash's leftover
    /// mapping) right away, then either turn the toggle off (the user just
    /// flipped it) or keep it on for a later retry.
    private func failToApply(_ message: String, userInitiated: Bool) {
        restoreSystem()
        if userInitiated {
            hangulEnabled = false
            UserDefaults.standard.set(false, forKey: Self.hangulKey)
        }
        errorMessage = message
    }

    private func setNotice(_ text: String?) {
        notice = text
        UserDefaults.standard.set(text, forKey: Self.noticeKey)
    }

    /// While changes are on the system, macOS must not kill PICkle without
    /// letting it restore them (logout uses sudden termination otherwise).
    private func setSuddenTermination(disabled: Bool) {
        guard disabled != suddenTerminationDisabled else { return }
        suddenTerminationDisabled = disabled
        if disabled {
            ProcessInfo.processInfo.disableSuddenTermination()
        } else {
            ProcessInfo.processInfo.enableSuddenTermination()
        }
    }

    // MARK: - Event tap

    private func updateTap() {
        guard started, !otherInstanceRunning else { return }
        let config = KeyTapConfig(
            switchKeyCode: hangulEnabled && !sessionAway ? activeKey?.keyCode : nil,
            emoji: emojiEnabled && !sessionAway)
        guard permissionGranted, !config.isEmpty else { tap.stop(); return }
        if tap.config != config || !tap.isRunning {
            if !tap.start(config) {
                // macOS refused the tap: the permission check was stale.
                permissionGranted = false
            }
        }
    }

    /// A fresh tap forgets any half-seen key (keys released while asleep or
    /// locked never arrive).
    private func restartTap() {
        tap.stop()
        updateTap()
    }

    // MARK: - Timers

    private func updateTimers() {
        guard started, !otherInstanceRunning else { return }
        let wanted = hangulEnabled || emojiEnabled
        if wanted && permissionTimer == nil {
            // Cheap: catches a grant (start the tap) or a revoke (stop it).
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
                self?.checkPermission()
            }
            permissionTimer?.tolerance = 0.5
        } else if !wanted {
            permissionTimer?.invalidate()
            permissionTimer = nil
        }
        // Also while anything is left to undo (a failed restore of mappings
        // or of the user's shortcut), so it gets retried.
        let guarding = hangulEnabled || hasLeftovers
        if guarding && integrityTimer == nil {
            integrityTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
                self?.checkIntegrity()
            }
            integrityTimer?.tolerance = 10
        } else if !guarding {
            integrityTimer?.invalidate()
            integrityTimer = nil
        }
    }

    /// Every 30 s while applied: the shortcut still on our key, and the
    /// mapping still in place (a `hidutil` reset or an HID restart can wipe it).
    /// Mappings or a shortcut binding PICkle still has to undo.
    private var hasLeftovers: Bool { KeyboardRemapper.hasRecords || savedMode != nil }

    private func checkIntegrity() {
        guard !sessionAway, !isApplying else { return }
        if !hangulEnabled {
            if hasLeftovers { restoreSystem() }
            updateTimers()
            return
        }
        guard let key = activeKey else { applyHangul(userInitiated: false); updateTap(); return }
        if !InputSourceShortcut.isBound(to: key) {
            if activeMode == .adopted, InputSourceShortcut.currentlyBoundKey() != nil {
                // The user moved the shortcut to another F-key: follow it.
                applyHangul(userInitiated: false)
                updateTap()
            } else {
                // The shortcut was changed to something else: that's the
                // user's (or another tool's) choice now, so step aside.
                InputSourceShortcut.forgetBackup()
                UserDefaults.standard.removeObject(forKey: Self.modeKey)
                turnOffHangul(notice: L("settings.input.notice.shortcutChanged"))
                updateTimers()
            }
        } else if !KeyboardRemapper.isApplied(target: key) {
            reapplyMappings()
        }
    }

    // MARK: - System observers

    private func installObservers() {
        let workspace = NSWorkspace.shared.notificationCenter
        workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
            self?.restartTap()
            self?.scheduleReapply([0.5, 2, 5])
        }
        workspace.addObserver(forName: NSWorkspace.sessionDidResignActiveNotification, object: nil,
                              queue: .main) { [weak self] _ in
            // Fast user switching: HID mappings apply to every user, so the
            // next user's right ⌘ would be a dead F-key. The shortcut is per
            // user and stays.
            guard let self else { return }
            self.sessionAway = true
            self.tap.stop()
            self.restoreSystem(mappingsOnly: true)
        }
        workspace.addObserver(forName: NSWorkspace.sessionDidBecomeActiveNotification, object: nil,
                              queue: .main) { [weak self] _ in
            guard let self else { return }
            self.sessionAway = false
            self.updateTap()
            self.scheduleReapply([0, 0.5, 2, 5])
        }
        workspace.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil,
                              queue: .main) { [weak self] note in
            let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication
            guard let self, self.hangulEnabled, app?.bundleIdentifier == Self.gksdudBundleID else { return }
            // gksdud does the same job with its own mappings; two would fight.
            self.turnOffHangul(notice: L("settings.input.notice.gksdud"))
            self.updateTimers()
        }

        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(forName: NSNotification.Name("com.apple.screenIsUnlocked"), object: nil,
                                queue: .main) { [weak self] _ in
            self?.restartTap()
            self?.scheduleReapply([0.3, 2])
        }
        distributed.addObserver(forName: NSNotification.Name("com.apple.accessibility.api"), object: nil,
                                queue: .main) { [weak self] _ in
            // TCC writes the change a moment after posting.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self?.checkPermission() }
        }

        installHotplugObserver()
    }

    /// The HID client's service list lags the kernel's, so try a few times.
    private func scheduleReapply(_ delays: [TimeInterval]) {
        for delay in delays {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in self?.reapplyMappings() }
        }
    }

    /// Keyboard plugged in (USB, Bluetooth, a virtual keyboard recreated).
    private func installHotplugObserver() {
        guard let port = IONotificationPortCreate(kIOMainPortDefault) else { return }
        hotplugPort = port
        IONotificationPortSetDispatchQueue(port, .main)
        let matching = IOServiceMatching("IOHIDEventService") as NSMutableDictionary
        matching["DeviceUsagePairs"] = [["DeviceUsagePage": 1, "DeviceUsage": 6]]
        let callback: IOServiceMatchingCallback = { refcon, iterator in
            KeyboardFeatures.drain(iterator)
            guard let refcon else { return }
            let me = Unmanaged<KeyboardFeatures>.fromOpaque(refcon).takeUnretainedValue()
            me.scheduleReapply([0.3, 1.5, 4])
        }
        let refcon = Unmanaged.passUnretained(self).toOpaque()
        if IOServiceAddMatchingNotification(port, kIOFirstMatchNotification, matching, callback, refcon,
                                            &hotplugIterator) == KERN_SUCCESS {
            // Draining arms the notification (and skips keyboards already here).
            KeyboardFeatures.drain(hotplugIterator)
        }
    }

    private static func drain(_ iterator: io_iterator_t) {
        while case let service = IOIteratorNext(iterator), service != 0 { IOObjectRelease(service) }
    }

    private func gksdudRunning() -> Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: Self.gksdudBundleID).isEmpty
    }
}
