// Portions adapted from gksdud (https://github.com/codingnoye/gksdud),
// Copyright 2026 CodingNoye, licensed under the Apache License, Version 2.0
// (bundled as Resources/ThirdPartyLicenses/gksdud-LICENSE.txt).
// Modified by Team jAm, 2026: the switch-on-press pulse and its press gate
// (a fresh non-repeat press always switches, so a lost key-up can't eat the
// next press), on a dedicated thread; plus PICkle's own right-⌥ emoji gate.

import AppKit
import Carbon
import CoreGraphics

/// What the tap should do. A new configuration means a new tap.
struct KeyTapConfig: Equatable {
    /// Key code of the F-key right ⌘ is mapped to; nil = Korean/English off.
    var switchKeyCode: Int?
    var emoji: Bool

    var isEmpty: Bool { switchKeyCode == nil && !emoji }
}

/// Right ⌥ pressed and released alone, quickly → open Emoji & Symbols.
/// Pure state so it can be exercised without a keyboard.
struct RightOptionGate {
    static let rightOptionKeyCode: Int64 = 61
    static let rightOptionDeviceBit: UInt64 = 0x40   // NX_DEVICERALTKEYMASK
    static let leftOptionDeviceBit: UInt64 = 0x20    // NX_DEVICELALTKEYMASK
    static let maxHold: TimeInterval = 0.5
    static let cooldown: TimeInterval = 0.35

    private var pressedAt: TimeInterval?
    private var cancelled = false
    private var lastFire: TimeInterval = -.infinity

    mutating func reset() { pressedAt = nil; cancelled = false }

    /// Anything else happening while right ⌥ is down turns it into a chord.
    mutating func cancel() { if pressedAt != nil { cancelled = true } }

    /// Feed a flagsChanged event. Returns true when the emoji window should open.
    mutating func flagsChanged(keyCode: Int64, flags: CGEventFlags, now: TimeInterval) -> Bool {
        guard keyCode == Self.rightOptionKeyCode else { cancel(); return false }
        let raw = flags.rawValue
        if raw & Self.rightOptionDeviceBit != 0 {
            let others: CGEventFlags = [.maskCommand, .maskControl, .maskShift, .maskSecondaryFn]
            let alone = flags.intersection(others).isEmpty && raw & Self.leftOptionDeviceBit == 0
            pressedAt = alone ? now : nil
            cancelled = !alone
            return false
        }
        defer { reset() }
        guard let pressedAt, !cancelled,
              now - pressedAt <= Self.maxHold,
              now - lastFire >= Self.cooldown else { return false }
        lastFire = now
        return true
    }
}

/// Swallows the mapped F-key's physical press and re-posts a down+up pair at
/// the HID level, so macOS's input-source shortcut fires on press instead of
/// release. Repeats and the matching release are swallowed too.
struct SwitchKeyGate {
    private var held = false

    mutating func reset() { held = false }

    enum Action { case pass, swallow, switchNow }

    mutating func handle(isDown: Bool, isRepeat: Bool) -> Action {
        if isDown {
            if isRepeat { return held ? .swallow : .pass }
            held = true
            return .switchNow
        }
        // Only swallow a release whose press we took. If the tap missed the
        // press (it was briefly disabled), the native shortcut needs this
        // release to switch.
        guard held else { return .pass }
        held = false
        return .swallow
    }
}

/// The session event tap, run on its own thread: an active keyboard tap holds
/// every keystroke on the Mac until its callback returns, so it must never wait
/// on PICkle's main thread (an open editor, a modal panel, the debugger).
final class KeyEventTap {
    private final class State {
        let config: KeyTapConfig
        let marker: Int64
        var port: CFMachPort?
        var switchGate = SwitchKeyGate()
        var optionGate = RightOptionGate()
        init(config: KeyTapConfig, marker: Int64) { self.config = config; self.marker = marker }
    }

    /// Hands the tap thread's run loop back to `start()` (written before the
    /// semaphore is signalled, read after it is waited on).
    private final class RunLoopBox { var loop: CFRunLoop? }

    private var state: State?
    private var runLoop: CFRunLoop?
    private var thread: Thread?

    /// Random per launch, written into every event PICkle posts so the tap
    /// lets its own events through untouched.
    private let marker = Int64.random(in: 1...Int64.max)

    private(set) var config: KeyTapConfig?
    var isRunning: Bool { state?.port.map(CFMachPortIsValid) ?? false }

    /// Start (or restart) with `config`. Returns false if macOS refused the tap
    /// (no Accessibility permission).
    @discardableResult
    func start(_ config: KeyTapConfig) -> Bool {
        stop()
        guard !config.isEmpty else { return true }
        let state = State(config: config, marker: marker)
        var mask = (CGEventMask(1) << CGEventType.keyDown.rawValue)
            | (CGEventMask(1) << CGEventType.keyUp.rawValue)
            | (CGEventMask(1) << CGEventType.flagsChanged.rawValue)
        if config.emoji {
            for type in [CGEventType.leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel] {
                mask |= CGEventMask(1) << type.rawValue
            }
        }
        // Only the Korean/English key needs to swallow events; emoji alone
        // just watches.
        let options: CGEventTapOptions = config.switchKeyCode != nil ? .defaultTap : .listenOnly
        guard let port = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: options,
            eventsOfInterest: mask, callback: KeyEventTap.callback,
            userInfo: Unmanaged.passUnretained(state).toOpaque()
        ) else { return false }
        state.port = port
        self.state = state
        self.config = config

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        let ready = DispatchSemaphore(value: 0)
        let loopBox = RunLoopBox()
        // The thread holds `state` until its run loop ends, so a callback still
        // running while `stop()` is called never sees freed memory.
        let thread = Thread {
            let retained = state
            let loop = CFRunLoopGetCurrent()
            loopBox.loop = loop
            CFRunLoopAddSource(loop, source, .commonModes)
            CGEvent.tapEnable(tap: port, enable: true)
            ready.signal()
            CFRunLoopRun()
            withExtendedLifetime(retained) {}
        }
        thread.name = "PICkle.KeyEventTap"
        thread.qualityOfService = .userInteractive
        self.thread = thread
        thread.start()
        ready.wait()
        runLoop = loopBox.loop
        return true
    }

    func stop() {
        if let port = state?.port {
            CGEvent.tapEnable(tap: port, enable: false)
            CFMachPortInvalidate(port)
        }
        if let runLoop { CFRunLoopStop(runLoop) }
        runLoop = nil
        thread = nil
        state = nil
        config = nil
    }

    // MARK: Callback (tap thread)

    private static let callback: CGEventTapCallBack = { _, type, event, info in
        guard let info else { return Unmanaged.passUnretained(event) }
        let state = Unmanaged<State>.fromOpaque(info).takeUnretainedValue()

        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            // Events were dropped while disabled: start from a clean slate.
            state.switchGate.reset()
            state.optionGate.reset()
            if let port = state.port { CGEvent.tapEnable(tap: port, enable: true) }
            return Unmanaged.passUnretained(event)
        }
        if event.getIntegerValueField(.eventSourceUserData) == state.marker {
            return Unmanaged.passUnretained(event)
        }

        let config = state.config
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        let now = ProcessInfo.processInfo.systemUptime

        switch type {
        case .flagsChanged:
            if config.emoji, state.optionGate.flagsChanged(keyCode: keyCode, flags: event.flags, now: now) {
                // Under secure input (password fields, Terminal's Secure
                // Keyboard Entry) the tap sees modifiers but not letters, so a
                // ⌥+letter would look like a lone tap.
                if !IsSecureEventInputEnabled() { postEmojiShortcut(marker: state.marker) }
            }
        case .keyDown, .keyUp:
            if type == .keyDown { state.optionGate.cancel() }
            // Only the keyboard's own events (no posting process). Another
            // tap that re-posts this F-key (gksdud, a second PICkle) would
            // otherwise bounce pulses back and forth without end.
            if let switchCode = config.switchKeyCode, keyCode == Int64(switchCode),
               event.getIntegerValueField(.eventSourceUnixProcessID) == 0 {
                let isRepeat = event.getIntegerValueField(.keyboardEventAutorepeat) != 0
                switch state.switchGate.handle(isDown: type == .keyDown, isRepeat: isRepeat) {
                case .pass:
                    return Unmanaged.passUnretained(event)
                case .swallow:
                    return nil
                case .switchNow:
                    // Fall back to the native shortcut if the pulse can't be built.
                    guard postSwitchPulse(from: event, marker: state.marker) else {
                        state.switchGate.reset()
                        return Unmanaged.passUnretained(event)
                    }
                    return nil
                }
            }
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            state.optionGate.cancel()
        case .scrollWheel:
            // Momentum keeps scrolling after the fingers lift; only a scroll
            // the user is actively making counts as using ⌥ with it.
            if event.getIntegerValueField(.scrollWheelEventMomentumPhase) == 0 { state.optionGate.cancel() }
        default:
            break
        }
        return Unmanaged.passUnretained(event)
    }

    /// Post the F-key's down+up at the HID level, ahead of the system's
    /// shortcut handling. Held modifiers are stripped; the F-key identity
    /// flags and Caps Lock are kept so the shortcut still matches.
    private static func postSwitchPulse(from event: CGEvent, marker: Int64) -> Bool {
        guard let down = event.copy(), let up = event.copy() else { return false }
        down.type = .keyDown
        up.type = .keyUp
        let flags = event.flags.intersection([.maskSecondaryFn, .maskNumericPad, .maskAlphaShift])
        for pulse in [down, up] {
            pulse.flags = flags
            pulse.setIntegerValueField(.keyboardEventAutorepeat, value: 0)
            pulse.setIntegerValueField(.eventSourceUserData, value: marker)
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
        return true
    }

    private static let emojiQueue = DispatchQueue(label: "PICkle.EmojiShortcut", qos: .userInteractive)

    /// ⌃⌘Space — macOS's "Emoji & Symbols" shortcut. Posted a moment after
    /// the ⌥ release so the app sees that release first.
    private static func postEmojiShortcut(marker: Int64) {
        emojiQueue.asyncAfter(deadline: .now() + .milliseconds(15)) {
            let space = CGKeyCode(kVK_Space)
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: space, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: space, keyDown: false) else { return }
            for event in [down, up] {
                event.flags = [.maskControl, .maskCommand]
                event.setIntegerValueField(.eventSourceUserData, value: marker)
            }
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }
    }
}
