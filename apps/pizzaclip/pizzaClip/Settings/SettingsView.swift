import SwiftUI
import AppKit
import ApplicationServices
import KeyboardShortcuts

struct SettingsView: View {
    @AppStorage("historyCap") private var historyCap: Int = 9
    @AppStorage("blacklist") private var blacklistJoined: String =
        "com.1password.1password,com.agilebits.onepassword7,com.bitwarden.desktop,com.apple.keychainaccess"
    @AppStorage(AppPaths.storageDirectoryDefaultsKey) private var customStorageDirectory: String = ""
    @AppStorage("rightCommandHangulToggle") private var rightCommandHangulToggle = false
    // Shares Sparkle's own default key, so toggling here directly drives the
    // updater (it reads automaticallyDownloadsUpdates live from this key).
    @AppStorage("SUAutomaticallyUpdate") private var automaticallyDownloadUpdates = true
    // 언어 선택 (system / en / ko). 시작 시 1회 적용되므로 변경 시 재시작 안내.
    @AppStorage(AppLocale.defaultsKey) private var appLanguage: String = AppLanguage.system.rawValue

    var body: some View {
        TabView {
            generalTab
                .tabItem { Label(L("General", "일반"), systemImage: "gear") }
            shortcutsTab
                .tabItem { Label(L("Shortcuts", "단축키"), systemImage: "keyboard") }
            privacyTab
                .tabItem { Label(L("Privacy", "개인정보"), systemImage: "hand.raised") }
            storageTab
                .tabItem { Label(L("Storage", "저장공간"), systemImage: "internaldrive") }
        }
        .frame(width: 560, height: 460)
        .background(WindowAccessor { window in
            window.title = L("pizzaClip Settings", "pizzaClip 설정")
        })
    }

    // MARK: - General

    private var generalTab: some View {
        Form {
            Section(L("Language", "언어")) {
                Picker(L("Language", "언어"), selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang.rawValue)
                    }
                }
                .onChange(of: appLanguage) { _ in showLanguageRestartAlert() }
                Text(L("Changes take effect after you restart pizzaClip.",
                       "변경사항은 pizzaClip을 다시 시작하면 적용됩니다."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section(L("History", "기록")) {
                LabeledContent(L("History cap", "기록 개수 제한")) {
                    HStack(spacing: 8) {
                        Stepper(value: $historyCap, in: 1...20, step: 1) {
                            Text(L("\(historyCap) items", "\(historyCap)개"))
                                .frame(minWidth: 70, alignment: .leading)
                                .monospacedDigit()
                        }
                    }
                }
                Text(L("When the number of non-pinned items exceeds this cap, the oldest entries are deleted automatically. Pinned items are never auto-deleted.",
                       "고정하지 않은 항목 수가 이 한도를 넘으면 오래된 항목부터 자동으로 삭제됩니다. 고정된 항목은 자동 삭제되지 않습니다."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section(L("Updates", "업데이트")) {
                LabeledContent(L("Current version", "현재 버전"), value: appVersionString)
                Toggle(isOn: $automaticallyDownloadUpdates) {
                    Text(L("Download updates automatically", "자동으로 업데이트 다운로드"))
                }
                Text(L("When on, new versions download in the background and install on quit. When off, pizzaClip only notifies you and you click Install yourself. Updates are checked once a day either way — or any time via the menu bar's “Check for Updates…”.",
                       "켜면 새 버전을 백그라운드에서 내려받아 종료 시 설치합니다. 끄면 알림만 주고 설치는 직접 누릅니다. 어느 쪽이든 하루 한 번 자동 확인하며, 메뉴바의 “업데이트 확인…”으로 언제든 확인할 수 있습니다."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
    }

    private var appVersionString: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    // MARK: - Shortcuts

    private var shortcutsTab: some View {
        Form {
            Section(L("Popup", "팝업")) {
                KeyboardShortcuts.Recorder(L("Open popup:", "팝업 열기:"), name: .togglePopup)
            }
            Section(L("Input source", "입력 소스")) {
                Toggle(isOn: $rightCommandHangulToggle) {
                    Text(L("Switch input source when right ⌘ is tapped",
                           "오른쪽 ⌘를 누르면 입력 소스 전환"))
                }
                .onChange(of: rightCommandHangulToggle) { newValue in
                    if newValue && !AXIsProcessTrusted() {
                        rightCommandHangulToggle = false
                        promptForAccessibilityForHangulToggle()
                        return
                    }
                    NotificationCenter.default.post(
                        name: .pizzaClipHangulToggleChanged,
                        object: NSNumber(value: newValue)
                    )
                }
                Text(L("Cleanly tap the right Command key — no other keys held — to switch between Hangul and a Latin keyboard. Requires Accessibility permission and at least one Korean input source enabled in System Settings → Keyboard → Input Sources.",
                       "다른 키를 누르지 않고 오른쪽 Command 키만 깔끔하게 한 번 누르면 한글과 영문 키보드를 전환합니다. 손쉬운 사용 권한과, 시스템 설정 → 키보드 → 입력 소스에 한국어 입력 소스가 하나 이상 켜져 있어야 합니다."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Section(L("Direct paste — nth most-recent non-pinned",
                      "바로 붙여넣기 — 고정 안 한 항목 중 N번째 최신")) {
                ForEach(1..<10) { n in
                    KeyboardShortcuts.Recorder(L("Slot \(n):", "슬롯 \(n):"), name: .slot(n))
                }
            }
        }
        .formStyle(.grouped)
    }

    private func promptForAccessibilityForHangulToggle() {
        let alert = NSAlert()
        alert.messageText = L("Accessibility permission required", "손쉬운 사용 권한 필요")
        alert.informativeText = L(
            "pizzaClip needs Accessibility access to observe the right ⌘ key. Grant it in System Settings → Privacy & Security → Accessibility, then re-enable this toggle.",
            "pizzaClip이 오른쪽 ⌘ 키를 감지하려면 손쉬운 사용 접근 권한이 필요합니다. 시스템 설정 → 개인정보 보호 및 보안 → 손쉬운 사용에서 권한을 준 뒤 이 항목을 다시 켜 주세요.")
        alert.addButton(withTitle: L("Open System Settings", "시스템 설정 열기"))
        alert.addButton(withTitle: L("Cancel", "취소"))
        if alert.runModal() == .alertFirstButtonReturn {
            Accessibility.openSystemSettings()
        }
    }

    // MARK: - Privacy

    private var privacyTab: some View {
        Form {
            Section(L("Apps to ignore", "기록하지 않을 앱")) {
                Text(L("Anything you copy from these apps is never saved to your history. Add sensitive apps like password managers.",
                       "여기 등록한 앱에서 복사한 내용은 기록에 저장되지 않아요. 비밀번호 관리자처럼 민감한 앱을 넣어두면 좋아요."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                BlacklistEditor(csv: $blacklistJoined)
            }
            Section {
                Label(L("Passwords and other concealed clipboard items are always ignored, even if the app isn't in this list.",
                        "비밀번호 등 숨김 처리된 클립보드 항목은 이 목록에 없어도 항상 무시돼요."),
                      systemImage: "checkmark.shield")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Storage

    private var storageTab: some View {
        Form {
            Section(L("Location", "위치")) {
                Text(AppPaths.supportDirectory.path)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.primary)
                    .lineLimit(3)
                    .truncationMode(.middle)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 10) {
                    Button(L("Change…", "변경…"), action: changeStorageFolder)
                    Button(L("Reset to default", "기본값으로 초기화"), action: resetStorageFolder)
                        .disabled(customStorageDirectory.isEmpty)
                    Spacer()
                    Button {
                        NSWorkspace.shared.open(AppPaths.supportDirectory)
                    } label: {
                        Label(L("Open in Finder", "Finder에서 열기"), systemImage: "folder")
                    }
                }
            }
            Section(L("History", "기록")) {
                HStack(spacing: 10) {
                    Button {
                        NotificationCenter.default.post(name: .pizzaClipExportHistory, object: nil)
                    } label: {
                        Label(L("Export to text…", "텍스트로 내보내기…"), systemImage: "square.and.arrow.up")
                    }
                    Spacer()
                    Button(role: .destructive, action: confirmClearAll) {
                        Label(L("Clear all history", "모든 기록 지우기"), systemImage: "trash")
                    }
                }
                Text(L("Clearing wipes both database rows and image files, including pinned items.",
                       "지우면 데이터베이스 항목과 이미지 파일이 모두 삭제됩니다(고정한 항목 포함)."))
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: - Actions

    private func changeStorageFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = L("Choose", "선택")
        panel.message = L("Pick a folder where pizzaClip will store db.sqlite and blobs/.",
                          "pizzaClip이 db.sqlite와 blobs/를 저장할 폴더를 선택하세요.")
        guard panel.runModal() == .OK, let url = panel.url else { return }
        customStorageDirectory = url.path
        showRestartAlert(message: L("Storage location set to \(url.path).",
                                    "저장 위치를 \(url.path) (으)로 설정했습니다."))
    }

    private func resetStorageFolder() {
        customStorageDirectory = ""
        showRestartAlert(message: L("Storage location reset to the default.",
                                    "저장 위치를 기본값으로 되돌렸습니다."))
    }

    private func showRestartAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = L("Restart required", "재시작 필요")
        alert.informativeText = L(
            """
            \(message)

            Quit and relaunch pizzaClip for the change to take effect. Existing data is not moved automatically — copy db.sqlite and blobs/ manually if you want to keep your history.
            """,
            """
            \(message)

            변경사항을 적용하려면 pizzaClip을 종료 후 다시 실행하세요. 기존 데이터는 자동으로 옮겨지지 않습니다 — 기록을 유지하려면 db.sqlite와 blobs/를 직접 복사하세요.
            """)
        alert.runModal()
    }

    /// 언어 변경 시 재시작 안내. (시작 시 1회 적용 방식이라 즉시 반영하지 않음)
    private func showLanguageRestartAlert() {
        let alert = NSAlert()
        alert.messageText = L("Restart required", "재시작 필요")
        alert.informativeText = L(
            "Quit and relaunch pizzaClip for the language change to take effect.",
            "언어 변경을 적용하려면 pizzaClip을 종료 후 다시 실행하세요.")
        alert.runModal()
    }

    private func confirmClearAll() {
        let alert = NSAlert()
        alert.messageText = L("Clear all clipboard history?", "모든 클립보드 기록을 지울까요?")
        alert.alertStyle = .warning
        alert.addButton(withTitle: L("Clear", "지우기"))
        alert.addButton(withTitle: L("Cancel", "취소"))
        if alert.runModal() == .alertFirstButtonReturn {
            NotificationCenter.default.post(name: .pizzaClipClearAll, object: nil)
        }
    }
}

/// Tiny shim so we can poke the underlying NSWindow once SwiftUI mounts the view
/// (e.g. to set its title — SwiftUI's Settings scene uses "PizzaClipApp" by default).
private struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            if let window = v.window { configure(window) }
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {
        if let window = nsView.window { configure(window) }
    }
}

extension Notification.Name {
    static let pizzaClipClearAll = Notification.Name("pizzaClipClearAll")
    static let pizzaClipExportHistory = Notification.Name("pizzaClipExportHistory")
    static let pizzaClipOpenSettings = Notification.Name("pizzaClipOpenSettings")
    static let pizzaClipHangulToggleChanged = Notification.Name("pizzaClipHangulToggleChanged")
}
