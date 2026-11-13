// Portions adapted from gksdud (https://github.com/codingnoye/gksdud),
// Copyright 2026 CodingNoye, licensed under the Apache License, Version 2.0
// (bundled as Resources/ThirdPartyLicenses/gksdud-LICENSE.txt).
// Modified by Team jAm, 2026: reduced to one mapping (right ⌘ → a function key)
// on every local keyboard, with per-keyboard undo records instead of gksdud's
// per-keyboard settings.

import Foundation
import IOKit
import IOKit.hid

/// A function key PICkle can route right ⌘ to. `keyCode` is the virtual key
/// code the event tap sees; `usage` is the HID usage written into
/// `UserKeyMapping` (page 7, F13 = 0x68 … F20 = 0x6F).
struct FunctionKey: Equatable {
    let name: String
    let keyCode: Int
    let usage: UInt64

    static let all: [FunctionKey] = zip(13...20, [105, 107, 113, 106, 64, 79, 80, 90]).map {
        FunctionKey(name: "F\($0.0)", keyCode: $0.1, usage: 0x7_0000_0068 + UInt64($0.0 - 13))
    }

    static func withKeyCode(_ code: Int) -> FunctionKey? { all.first { $0.keyCode == code } }
    static func withUsage(_ usage: UInt64) -> FunctionKey? { all.first { $0.usage == usage } }
}

typealias KeyMapping = [String: NSNumber]

/// One keyboard as the HID event system sees it. A service must not outlive
/// the client that listed it, so the client is kept alongside.
final class HIDKeyboard {
    private let client: IOHIDEventSystemClient
    private let service: IOHIDServiceClient
    let registryID: String
    let name: String

    init(client: IOHIDEventSystemClient, service: IOHIDServiceClient) {
        self.client = client
        self.service = service
        let id = (IOHIDServiceClientGetRegistryID(service) as? NSNumber)?.uint64Value ?? 0
        registryID = String(id)
        name = IOHIDServiceClientCopyProperty(service, "Product" as CFString) as? String ?? "Keyboard"
    }

    /// nil when the property holds something we can't read (treated as a failure).
    func readMappings() -> [KeyMapping]? {
        guard let value = IOHIDServiceClientCopyProperty(service, "UserKeyMapping" as CFString) else { return [] }
        return value as? [KeyMapping]
    }

    func writeMappings(_ mappings: [KeyMapping]) -> Bool {
        IOHIDServiceClientSetProperty(service, "UserKeyMapping" as CFString, mappings as CFArray)
    }
}

/// Maps right ⌘ to a function key on every local keyboard and undoes exactly
/// what it wrote. Undo records live in UserDefaults so a crash or relaunch can
/// still restore; they are dropped after a reboot, which clears HID mappings
/// and lets registry IDs be reused by other devices.
enum KeyboardRemapper {
    static let rightCommand: UInt64 = 0x7_0000_00E7
    static let srcKey = "HIDKeyboardModifierMappingSrc"
    static let dstKey = "HIDKeyboardModifierMappingDst"

    private static let recordsKey = "kbd.hidRecords"
    private static let bootKey = "kbd.hidBoot"
    private static let none = "none"

    /// registry ID → ["original": dst-or-"none", "target": dst we wrote].
    private static var records: [String: [String: String]] {
        get { UserDefaults.standard.dictionary(forKey: recordsKey) as? [String: [String: String]] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: recordsKey) }
    }

    static var hasRecords: Bool { !records.isEmpty }

    // MARK: Discovery

    /// Keyboards attached to this Mac. Universal Control brings another Mac's
    /// keyboards in as HID services the kernel doesn't know; those are left out
    /// (their keys are that Mac's to map, and macOS refuses mappings on them).
    /// nil when the HID system can't be asked — callers must treat that as a
    /// failure, never as "no keyboards" (that would drop undo records).
    static func localKeyboards() -> [HIDKeyboard]? {
        let client = IOHIDEventSystemClientCreateSimpleClient(kCFAllocatorDefault)
        guard let services = IOHIDEventSystemClientCopyServices(client) as? [IOHIDServiceClient] else { return nil }
        let kernel = kernelKeyboardIDs()
        return services
            .filter { IOHIDServiceClientConformsTo($0, 1, 6) != 0 }
            .filter { service in
                guard let kernel else { return true }
                let id = (IOHIDServiceClientGetRegistryID(service) as? NSNumber)?.uint64Value
                return id.map(kernel.contains) ?? false
            }
            .map { HIDKeyboard(client: client, service: $0) }
    }

    private static func kernelKeyboardIDs() -> Set<UInt64>? {
        let matching = IOServiceMatching("IOHIDEventService") as NSMutableDictionary
        matching["DeviceUsagePairs"] = [["DeviceUsagePage": 1, "DeviceUsage": 6]]
        var iterator: io_iterator_t = 0
        guard IOServiceGetMatchingServices(kIOMainPortDefault, matching as CFDictionary, &iterator) == KERN_SUCCESS else {
            return nil
        }
        defer { IOObjectRelease(iterator) }
        var ids: Set<UInt64> = []
        while case let service = IOIteratorNext(iterator), service != 0 {
            var id: UInt64 = 0
            if IORegistryEntryGetRegistryEntryID(service, &id) == KERN_SUCCESS { ids.insert(id) }
            IOObjectRelease(service)
        }
        return ids
    }

    /// Function keys other mappings (not ours) already produce, on any keyboard.
    static func functionKeysUsedByOtherMappings() -> Set<UInt64> {
        var used: Set<UInt64> = []
        for keyboard in localKeyboards() ?? [] {
            for mapping in keyboard.readMappings() ?? [] where mapping[srcKey]?.uint64Value != rightCommand {
                if let dst = mapping[dstKey]?.uint64Value, FunctionKey.withUsage(dst) != nil { used.insert(dst) }
            }
        }
        return used
    }

    /// True when a keyboard looks like Karabiner-Elements' virtual one, whose
    /// own rules may also act on right ⌘.
    static func karabinerPresent() -> Bool {
        (localKeyboards() ?? []).contains { $0.name.hasPrefix("Karabiner DriverKit VirtualHIDKeyboard") }
    }

    // MARK: Boot bookkeeping

    /// Call once at launch: a reboot wiped every mapping, so old records would
    /// only point at registry IDs another device may now own.
    static func forgetRecordsFromPreviousBoot() {
        let defaults = UserDefaults.standard
        guard let boot = bootSessionID() else { return }
        if let previous = defaults.string(forKey: bootKey), previous != boot {
            defaults.removeObject(forKey: recordsKey)
        }
        defaults.set(boot, forKey: bootKey)
    }

    private static func bootSessionID() -> String? {
        var size = 0
        guard sysctlbyname("kern.bootsessionuuid", nil, &size, nil, 0) == 0, size > 1 else { return nil }
        var value = [CChar](repeating: 0, count: size)
        guard sysctlbyname("kern.bootsessionuuid", &value, &size, nil, 0) == 0 else { return nil }
        return String(cString: value)
    }

    // MARK: Apply / restore

    /// Map right ⌘ → `target` on every local keyboard. The undo record is saved
    /// before each write. Returns the names of keyboards that failed (retried
    /// on the next trigger).
    ///
    /// An identical mapping PICkle has no record of isn't PICkle's (records
    /// outlive crashes; reboots clear both). With `claimUnrecorded` false —
    /// adopted mode, where the user's own setup may already route right ⌘ to
    /// the shortcut's key — it is left alone and never removed. In owned mode
    /// the key was picked as free, so such a mapping is claimed and removed
    /// on restore, keeping "mapping present ⇒ shortcut bound" true.
    @discardableResult
    static func apply(target: FunctionKey, claimUnrecorded: Bool) -> [String] {
        guard let keyboards = localKeyboards() else { return ["HID"] }
        var failed: [String] = []
        var saved = records
        for keyboard in keyboards {
            guard let current = keyboard.readMappings() else { failed.append(keyboard.name); continue }
            let existing = current.first { $0[srcKey]?.uint64Value == rightCommand }?[dstKey]?.uint64Value
            if existing == target.usage {
                if saved[keyboard.registryID] == nil && claimUnrecorded {
                    saved[keyboard.registryID] = ["original": none, "target": String(target.usage)]
                }
                continue
            }
            var record = saved[keyboard.registryID] ?? ["original": existing.map(String.init) ?? none]
            record["target"] = String(target.usage)
            saved[keyboard.registryID] = record
            records = saved

            var merged = current.filter { $0[srcKey]?.uint64Value != rightCommand }
            merged.append([srcKey: NSNumber(value: rightCommand), dstKey: NSNumber(value: target.usage)])
            let readBack = keyboard.writeMappings(merged) ? keyboard.readMappings() : nil
            let applied = readBack?.contains {
                $0[srcKey]?.uint64Value == rightCommand && $0[dstKey]?.uint64Value == target.usage
            } ?? false
            if !applied { failed.append(keyboard.name) }
        }
        records = saved
        return failed
    }

    /// Undo what `apply` wrote. A keyboard that's gone only drops its record; an
    /// entry someone else changed since is left alone. Returns false if any
    /// write failed — the caller must then keep the input-source shortcut, so
    /// a remaining mapping still switches.
    @discardableResult
    static func restore() -> Bool {
        var saved = records
        guard !saved.isEmpty else { return true }
        guard let keyboards = localKeyboards() else { return false }
        let present = Dictionary(keyboards.map { ($0.registryID, $0) }, uniquingKeysWith: { first, _ in first })
        let kernel = kernelKeyboardIDs()
        var ok = true
        for (id, record) in saved {
            guard let keyboard = present[id] else {
                // Gone from the kernel too → unplugged, its mapping went with
                // it. Still in the kernel (the HID list lags) or unknown →
                // keep the record and retry.
                if let kernel, let number = UInt64(id), !kernel.contains(number) {
                    saved[id] = nil
                } else {
                    ok = false
                }
                continue
            }
            guard let current = keyboard.readMappings() else { ok = false; continue }
            let target = UInt64(record["target"] ?? "")
            guard let index = current.firstIndex(where: { $0[srcKey]?.uint64Value == rightCommand }),
                  current[index][dstKey]?.uint64Value == target else {
                saved[id] = nil
                continue
            }
            var mappings = current
            mappings.remove(at: index)
            if let original = record["original"].flatMap(UInt64.init) {
                mappings.append([srcKey: NSNumber(value: rightCommand), dstKey: NSNumber(value: original)])
            }
            guard keyboard.writeMappings(mappings),
                  keyboard.readMappings()?.contains(where: {
                      $0[srcKey]?.uint64Value == rightCommand && $0[dstKey]?.uint64Value == target
                  }) == false else { ok = false; continue }
            saved[id] = nil
        }
        records = saved
        return ok
    }

    /// True when every local keyboard currently maps right ⌘ → `target`.
    static func isApplied(target: FunctionKey) -> Bool {
        guard let keyboards = localKeyboards() else { return false }
        return !keyboards.isEmpty && keyboards.allSatisfy { keyboard in
            keyboard.readMappings()?.contains {
                $0[srcKey]?.uint64Value == rightCommand && $0[dstKey]?.uint64Value == target.usage
            } == true
        }
    }
}
