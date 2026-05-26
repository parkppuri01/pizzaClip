import AppKit
import ApplicationServices

enum Accessibility {
    private static let didPromptKey = "didShowAccessibilityPrompt"

    /// Live trust check; never shows a prompt.
    static func isTrusted() -> Bool {
        AXIsProcessTrusted()
    }

    /// Shows the system Accessibility prompt at most once — ever — per install.
    /// Subsequent launches (or repeated calls in the same session) are no-ops.
    /// If the user denies, they can grant later from the menu's
    /// "Grant Accessibility…" item, which goes straight to System Settings
    /// without re-prompting.
    static func promptOnceIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: didPromptKey) else { return }
        UserDefaults.standard.set(true, forKey: didPromptKey)
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }
}
