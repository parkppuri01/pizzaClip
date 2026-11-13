import SwiftUI
import AppKit

/// Settings → 입력: right ⌘ Korean/English and right ⌥ emoji, plus the
/// Accessibility permission both need.
struct InputSettingsTab: View {
    @ObservedObject private var features = KeyboardFeatures.shared

    var body: some View {
        Form {
            if features.otherInstanceRunning {
                Section {
                    Label(L("settings.input.otherInstance"), systemImage: "exclamationmark.triangle.fill")
                        .font(.caption).foregroundStyle(.orange)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section(L("settings.input.permission.section")) {
                HStack {
                    if features.permissionGranted {
                        Label(L("settings.input.permission.granted"), systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        Label(L("settings.input.permission.missing"), systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                    Spacer()
                    if !features.permissionGranted {
                        Button(L("settings.input.permission.request")) { features.requestPermission() }
                        Button(L("settings.input.permission.open")) { features.openAccessibilitySettings() }
                    }
                }
                Text(L("settings.input.permission.desc"))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section(L("settings.input.hangul.section")) {
                Toggle(L("settings.input.hangul.toggle"), isOn: Binding(
                    get: { features.hangulEnabled },
                    set: { features.setHangul($0) }))
                Text(L("settings.input.hangul.desc"))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                hangulStatus
            }

            Section(L("settings.input.emoji.section")) {
                Toggle(L("settings.input.emoji.toggle"), isOn: Binding(
                    get: { features.emojiEnabled },
                    set: { features.setEmoji($0) }))
                Text(L("settings.input.emoji.desc"))
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                HStack(alignment: .firstTextBaseline) {
                    Text(L("settings.input.credit"))
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button(L("settings.input.license")) { openLicense() }
                        .buttonStyle(.link).font(.caption)
                }
            }
        }
        .formStyle(.grouped)
        .disabled(features.otherInstanceRunning)
        .onAppear { features.refreshEnvironment() }
    }

    /// Status lines under the Korean/English toggle, most important first.
    @ViewBuilder private var hangulStatus: some View {
        if let error = features.errorMessage {
            statusLine(error, icon: "xmark.octagon.fill", color: .red)
        }
        if let notice = features.notice {
            statusLine(notice, icon: "info.circle.fill", color: .orange)
        }
        if features.hangulEnabled, let key = features.activeKey {
            let format = features.activeMode == .owned
                ? L("settings.input.hangul.status.owned") : L("settings.input.hangul.status.adopted")
            statusLine(String(format: format, key.name), icon: "keyboard", color: .secondary)
            if !features.permissionGranted {
                statusLine(L("settings.input.hangul.status.noPermission"),
                           icon: "exclamationmark.circle", color: .orange)
            }
            if !features.failedKeyboards.isEmpty {
                statusLine(String(format: L("settings.input.hangul.status.failed"),
                                  features.failedKeyboards.joined(separator: ", ")),
                           icon: "exclamationmark.circle", color: .orange)
            }
        }
        if features.pizzaClipToggleOn {
            statusLine(L("settings.input.warning.pizzaClip"), icon: "exclamationmark.triangle.fill", color: .orange)
        }
        if features.karabinerPresent {
            statusLine(L("settings.input.warning.karabiner"), icon: "exclamationmark.triangle", color: .secondary)
        }
    }

    private func statusLine(_ text: String, icon: String, color: Color) -> some View {
        Label(text, systemImage: icon)
            .font(.caption).foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func openLicense() {
        guard let url = Bundle.main.url(forResource: "gksdud-LICENSE", withExtension: "txt") else { return }
        NSWorkspace.shared.open(url)
    }
}
