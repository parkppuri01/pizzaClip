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

    private static let rightCmdKeyCode: Int64 = 54
    private static let rightCmdFlagBit: UInt64 = 0x10  // NX_DEVICERCMDKEYMASK

    var isEnabled: Bool { tap != nil }

    func setEnabled(_ enabled: Bool) {
        if enabled {
            if tap == nil { startTap() }
        } else {
            stopTap()
        }
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
        // macOS disables long-blocking taps. Re-enable if the system kicks us.
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let port = tap { CGEvent.tapEnable(tap: port, enable: true) }
            return
        }
        switch type {
        case .flagsChanged:
            let keycode = event.getIntegerValueField(.keyboardEventKeycode)
            if keycode == Self.rightCmdKeyCode {
                let isRightCmdHeld = (event.flags.rawValue & Self.rightCmdFlagBit) != 0
                if isRightCmdHeld {
                    rightCmdDown = true
                    dirtied = false
                } else {
                    let wasCleanTap = rightCmdDown && !dirtied
                    rightCmdDown = false
                    if wasCleanTap {
                        DispatchQueue.main.async { Self.toggleInputSource() }
                    }
                }
            } else if rightCmdDown {
                // Some other modifier changed while right ⌘ was held; treat as chord.
                dirtied = true
            }
        case .keyDown:
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
