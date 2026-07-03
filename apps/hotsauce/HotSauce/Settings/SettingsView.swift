import SwiftUI
import ServiceManagement

/// 설정 창 내용: 로그인 시 자동 시작 / 언어 / 업데이트 / 버전 정보.
struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = "system"
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    @State private var loginToggleError: String?

    var onCheckForUpdates: () -> Void = {}

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }

    var body: some View {
        Form {
            Section {
                Toggle(L("Launch at login", "로그인 시 자동 시작"), isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { enabled in
                        do {
                            if enabled {
                                try SMAppService.mainApp.register()
                            } else {
                                try SMAppService.mainApp.unregister()
                            }
                            loginToggleError = nil
                        } catch {
                            loginToggleError = error.localizedDescription
                            launchAtLogin = (SMAppService.mainApp.status == .enabled)
                        }
                    }
                if let loginToggleError {
                    Text(loginToggleError)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }

            Section {
                Picker(L("Language", "언어"), selection: $appLanguage) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.label).tag(language.rawValue)
                    }
                }
                Text(L("Takes effect after relaunching the app.",
                       "언어는 앱을 다시 실행하면 적용돼요."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                HStack {
                    Text(L("Version", "버전") + " \(version)")
                        .foregroundColor(.secondary)
                    Spacer()
                    Button(L("Check for Updates…", "업데이트 확인…")) {
                        onCheckForUpdates()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380)
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// 설정 창 관리 — SwiftUI Settings 씬 대신 직접 NSWindow 를 관리한다.
/// (LSUIElement 앱에서 Settings 씬 열기는 macOS 버전별로 신뢰할 수 없음)
final class SettingsWindowController {
    private var window: NSWindow?
    var onCheckForUpdates: () -> Void = {}

    func show() {
        if window == nil {
            let view = SettingsView(onCheckForUpdates: { [weak self] in
                self?.onCheckForUpdates()
            })
            let hosting = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: hosting)
            window.title = L("HotSauce Settings", "HotSauce 설정")
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
