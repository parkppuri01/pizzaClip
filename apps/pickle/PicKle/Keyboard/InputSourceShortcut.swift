// Portions adapted from gksdud (https://github.com/codingnoye/gksdud),
// Copyright 2026 CodingNoye, licensed under the Apache License, Version 2.0
// (bundled as Resources/ThirdPartyLicenses/gksdud-LICENSE.txt).
// Modified by Team jAm, 2026: adds "adopted" mode (reuse an F-key the
// shortcut is already bound to, so nothing is written), and drops gksdud's
// next-source shortcut (61) and input-menu handling.

import Foundation

/// macOS's "Select the previous input source" shortcut (symbolic hot key 60).
/// Switching through this shortcut — rather than picking an input source
/// directly — lets the Korean input method finish the syllable being composed
/// and keeps the front app in sync.
enum InputSourceShortcut {
    enum Mode: String { case adopted, owned }

    private static let domain = "com.apple.symbolichotkeys" as CFString
    private static let hotKeysKey = "AppleSymbolicHotKeys" as CFString
    private static let previousSourceID = "60"
    /// macOS adds the function-key identity flag when it saves an unmodified F-key.
    private static let secondaryFn = 0x80_0000

    private static let backupKey = "kbd.shortcutBackup"
    private static let backupAbsentKey = "kbd.shortcutBackupAbsent"
    private static let restorePendingKey = "kbd.shortcutRestorePending"

    /// F-keys the previous-source shortcut can live on (macOS never fires input
    /// source shortcuts on F20).
    private static let adoptable = FunctionKey.all.filter { $0.name != "F20" }
    /// Order tried when PICkle has to bind the shortcut itself. F14/F15 are
    /// display brightness on many keyboards, so they are skipped.
    private static let ownedOrder = ["F19", "F18", "F17", "F16", "F13"]

    // MARK: Reading

    static func readAll() -> [String: Any] {
        CFPreferencesAppSynchronize(domain)
        return CFPreferencesCopyAppValue(hotKeysKey, domain) as? [String: Any] ?? [:]
    }

    /// The F-key an enabled, unmodified hot-key entry is bound to.
    static func boundFunctionKey(_ raw: Any?) -> FunctionKey? {
        guard let entry = raw as? [String: Any],
              (entry["enabled"] as? NSNumber)?.boolValue == true,
              let value = entry["value"] as? [String: Any], value["type"] as? String == "standard",
              let parameters = value["parameters"] as? [NSNumber], parameters.count == 3,
              parameters[0].intValue == 65535,
              [0, secondaryFn].contains(parameters[2].intValue) else { return nil }
        return FunctionKey.withKeyCode(parameters[1].intValue)
    }

    /// The F-key "previous input source" is already on, if it's one PICkle can use.
    static func currentlyBoundKey() -> FunctionKey? {
        boundFunctionKey(readAll()[previousSourceID]).flatMap { key in adoptable.contains(key) ? key : nil }
    }

    /// F-keys other enabled system shortcuts use without modifiers.
    private static func keysUsedByOtherShortcuts(_ all: [String: Any]) -> Set<Int> {
        Set(all.compactMap { id, raw in id == previousSourceID ? nil : boundFunctionKey(raw)?.keyCode })
    }

    // MARK: Choosing

    /// Adopt the existing binding when there is one; otherwise pick a free
    /// F-key for PICkle to bind. nil when every candidate is taken.
    static func chooseTarget(usedByMappings: Set<UInt64>) -> (FunctionKey, Mode)? {
        let all = readAll()
        if let key = boundFunctionKey(all[previousSourceID]), adoptable.contains(key) {
            return (key, .adopted)
        }
        let busy = keysUsedByOtherShortcuts(all)
        for name in ownedOrder {
            guard let key = FunctionKey.all.first(where: { $0.name == name }) else { continue }
            if !busy.contains(key.keyCode) && !usedByMappings.contains(key.usage) { return (key, .owned) }
        }
        return nil
    }

    /// True while "previous input source" still fires on `key`.
    static func isBound(to key: FunctionKey) -> Bool { boundFunctionKey(readAll()[previousSourceID]) == key }

    // MARK: Owned mode — write / restore

    /// Bind "previous input source" to `key`, backing up the user's value first.
    static func bind(to key: FunctionKey) throws {
        var all = readAll()
        let defaults = UserDefaults.standard
        let hasBackup = defaults.object(forKey: backupKey) != nil || defaults.bool(forKey: backupAbsentKey)
        if !hasBackup || boundFunctionKey(all[previousSourceID]) != key {
            // A user edit since our last write becomes the new baseline.
            if let current = all[previousSourceID] {
                defaults.set(current, forKey: backupKey)
                defaults.removeObject(forKey: backupAbsentKey)
            } else {
                defaults.removeObject(forKey: backupKey)
                defaults.set(true, forKey: backupAbsentKey)
            }
        }
        defaults.removeObject(forKey: restorePendingKey)
        all[previousSourceID] = [
            "enabled": true,
            "value": ["type": "standard", "parameters": [65535, key.keyCode, 0]],
        ] as [String: Any]
        try write(all)
        try activate()
    }

    /// Put the user's value back if the shortcut is still ours. Safe to call
    /// repeatedly; a write that succeeded but whose activation failed is
    /// re-activated on the next call.
    static func restore(ownedKey key: FunctionKey?) throws {
        let defaults = UserDefaults.standard
        let backup = defaults.object(forKey: backupKey)
        let absent = defaults.bool(forKey: backupAbsentKey)
        guard backup != nil || absent else { return }
        var all = readAll()
        if let key, boundFunctionKey(all[previousSourceID]) == key {
            all[previousSourceID] = absent ? nil : backup
            defaults.set(true, forKey: restorePendingKey)
            try write(all)
            try activate()
        } else if defaults.bool(forKey: restorePendingKey) {
            try activate()
        }
        forgetBackup()
    }

    /// Drop the backup without writing — used when the user has rebound the
    /// shortcut themselves, so their new value stands.
    static func forgetBackup() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: backupKey)
        defaults.removeObject(forKey: backupAbsentKey)
        defaults.removeObject(forKey: restorePendingKey)
    }

    private static func write(_ all: [String: Any]) throws {
        CFPreferencesSetAppValue(hotKeysKey, all as CFDictionary, domain)
        guard CFPreferencesAppSynchronize(domain) else { throw ShortcutError.write }
    }

    /// Apply session shortcuts now. `-virtualSession` skips re-applying
    /// physical-device preferences (it would reset other apps' per-device
    /// mouse acceleration).
    ///
    /// Waits on a semaphore, not `waitUntilExit()`: that spins the main run
    /// loop, so a quit, a timer or a session change could run in the middle of
    /// a half-finished apply. Blocking the main thread for a few hundred ms is
    /// harmless here — the key tap runs on its own thread.
    private static func activate() throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath:
            "/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings")
        process.arguments = ["-u", "-virtualSession"]
        let finished = DispatchSemaphore(value: 0)
        process.terminationHandler = { _ in finished.signal() }
        try process.run()
        guard finished.wait(timeout: .now() + 5) == .success else {
            process.terminate()
            throw ShortcutError.activate
        }
        guard process.terminationStatus == 0 else { throw ShortcutError.activate }
    }

    enum ShortcutError: LocalizedError {
        case write, activate
        var errorDescription: String? {
            switch self {
            case .write: return L("settings.input.error.shortcutWrite")
            case .activate: return L("settings.input.error.shortcutActivate")
            }
        }
    }
}
