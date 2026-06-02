import AppKit
import Carbon
import CoreGraphics
import ApplicationServices

/// Detects a "clean tap" of the right ⌘ key — pressed and released with no
/// other key touched in between — and toggles between the current Hangul
/// (ko) and any Latin keyboard input source via Carbon TIS.
///
/// We use a session-level event tap in listen-only mode so the keystroke
/// still flows to the focused app. Accessibility permission is required;
/// no separate Input Monitoring grant is needed.
///
/// Right ⌘ virtual keycode is 54 (left ⌘ is 55). The device-specific bit
/// for right-cmd in CGEventFlags is `NX_DEVICERCMDKEYMASK` = 0x10.
final class HangulToggler {
    static let shared = HangulToggler()
    private init() {}

    private var tap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private var rightCmdDown = false
    private var dirtied = false

    private var wantsEnabled = false
    private var observersInstalled = false
    private var retryTimer: Timer?

    private static let rightCmdKeyCode: Int64 = 54
    private static let rightCmdFlagBit: UInt64 = 0x10  // NX_DEVICERCMDKEYMASK

    /// True iff the tap is actually running. Distinct from `wantsEnabled`,
    /// which tracks the user's stated preference even when permission is
    /// still missing.
    var isRunning: Bool { tap != nil }

    func setEnabled(_ enabled: Bool) {
        wantsEnabled = enabled
        if enabled {
            if tap == nil { startTap() }
            installPermissionObserversIfNeeded()
            if tap == nil {
                startRetryTimer()
            } else {
                stopRetryTimer()
            }
        } else {
            stopTap()
            stopRetryTimer()
        }
    }

    // MARK: - Permission auto-recovery
    //
    // The tap requires Accessibility (TCC) permission. If the user hasn't
    // granted it yet, `startTap()` silently fails. We watch two signals so
    // the tap auto-installs the moment the grant flips on, sparing the
    // user a second trip through pizzaClip's Settings to re-toggle the
    // checkbox:
    //
    //  • DistributedNotificationCenter `com.apple.accessibility.api` —
    //    undocumented but stable, fired by the system when TCC entries
    //    change. Karabiner-Elements, Hammerspoon etc. rely on it.
    //  • NSWorkspace `didActivateApplicationNotification` — belt and
    //    suspenders, in case the distributed notification doesn't arrive.
    //
    // We also run a 2 s polling timer while in the "wanted but not yet
    // running" state, so even on a machine that delivers neither signal
    // the user sees auto-recovery within a few seconds.
    private func installPermissionObserversIfNeeded() {
        guard !observersInstalled else { return }
        observersInstalled = true
        let handler: (Notification) -> Void = { [weak self] _ in
            self?.recheckPermissionAndRetry()
        }
        DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.apple.accessibility.api"),
            object: nil, queue: .main, using: handler
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil, queue: .main, using: handler
        )
    }

    private func recheckPermissionAndRetry() {
        guard wantsEnabled, tap == nil else { return }
        guard AXIsProcessTrusted() else { return }
        startTap()
        if tap != nil { stopRetryTimer() }
    }

    private func startRetryTimer() {
        guard retryTimer == nil else { return }
        retryTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.recheckPermissionAndRetry()
        }
    }

    private func stopRetryTimer() {
        retryTimer?.invalidate()
        retryTimer = nil
    }

    private func startTap() {
        guard AXIsProcessTrusted() else {
            NSLog("pizzaClip HangulToggler: Accessibility not granted; tap not installed.")
            return
        }
        let mask: CGEventMask =
            (1 << CGEventType.flagsChanged.rawValue) |
            (1 << CGEventType.keyDown.rawValue)
        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        guard let machPort = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: mask,
            callback: { _, type, event, info in
                if let info {
                    let me = Unmanaged<HangulToggler>.fromOpaque(info).takeUnretainedValue()
                    me.handle(type: type, event: event)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: userInfo
        ) else {
            NSLog("pizzaClip HangulToggler: CGEvent.tapCreate failed.")
            return
        }
        self.tap = machPort
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, machPort, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        self.runLoopSource = source
        CGEvent.tapEnable(tap: machPort, enable: true)
    }

    private func stopTap() {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        if let machPort = tap {
            CGEvent.tapEnable(tap: machPort, enable: false)
        }
        runLoopSource = nil
        tap = nil
        rightCmdDown = false
        dirtied = false
    }

    private func handle(type: CGEventType, event: CGEvent) {
        // macOS can silently disable a session tap under heavy input (or if a
        // callback runs long). While it's disabled, mid-gesture events are
        // dropped — so we don't just re-enable it, we also clear any half-seen
        // right-⌘ state. Otherwise a lost key-down/up leaves our bookkeeping
        // out of sync and the *next* clean tap gets eaten. This stale-state
        // trap is the main cause of the "every so often it just doesn't
        // switch" symptom.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            rightCmdDown = false
            dirtied = false
            if let port = tap { CGEvent.tapEnable(tap: port, enable: true) }
            return
        }

        // Trust the event's live device-flag for right ⌘ over our own running
        // state — that way a dropped key-up can never leave us permanently
        // stuck thinking the key is still held.
        let rightCmdHeldNow = (event.flags.rawValue & Self.rightCmdFlagBit) != 0

        switch type {
        case .flagsChanged:
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            if keycode == Self.rightCmdKeyCode {
                if rightCmdHeldNow {
                    // Right ⌘ pressed — arm a fresh gesture.
                    rightCmdDown = true
                    dirtied = false
                } else {
                    // Right ⌘ released — fire only if nothing else was touched
                    // while it was held.
                    let wasCleanTap = rightCmdDown && !dirtied
                    rightCmdDown = false
                    if wasCleanTap {
                        DispatchQueue.main.async { Self.toggleInputSource() }
                    }
                }
            } else {
                // A different modifier changed. If right ⌘ is genuinely held,
                // this turns the gesture into a chord (no toggle). If the live
                // flag says right ⌘ is *not* held but we still think it is, we
                // missed its key-up — drop the stale state without firing.
                if rightCmdHeldNow {
                    dirtied = true
                } else {
                    rightCmdDown = false
                }
            }
        case .keyDown:
            // Any real key pressed while right ⌘ is down → chord, not a tap.
            if rightCmdDown { dirtied = true }
        default:
            break
        }
    }

    // MARK: - Input source switching

    static func toggleInputSource() {
        let filter: [CFString: Any] = [
            kTISPropertyInputSourceCategory: kTISCategoryKeyboardInputSource,
            kTISPropertyInputSourceIsEnabled: true,
            kTISPropertyInputSourceIsSelectCapable: true,
        ]
        guard let listRef = TISCreateInputSourceList(filter as CFDictionary, false) else { return }
        let list = listRef.takeRetainedValue() as! [TISInputSource]
        let current = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        let currentIsKorean = isKorean(current)
        guard let target = list.first(where: { isKorean($0) != currentIsKorean }) else {
            NSLog("pizzaClip HangulToggler: no opposite input source available to toggle to.")
            return
        }
        TISSelectInputSource(target)
    }

    private static func isKorean(_ source: TISInputSource) -> Bool {
        guard let ptr = TISGetInputSourceProperty(source, kTISPropertyInputSourceLanguages) else {
            return false
        }
        let langs = Unmanaged<CFArray>.fromOpaque(ptr).takeUnretainedValue() as? [String] ?? []
        return langs.contains("ko")
    }
}
