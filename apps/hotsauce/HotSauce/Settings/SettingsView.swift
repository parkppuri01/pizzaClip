import SwiftUI
import ServiceManagement

/// 설정 창 내용 — 세 앱 공통 '일반' 레이아웃.
/// 위쪽은 앱 정체성(아이콘/이름/소개/버전) 배너, 아래쪽은 grouped 폼(일반=로그인
/// 시작 / 언어 / 업데이트). pizzaClip·PICkle 과 같은 구조라 한 디자인으로 보인다.
struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = "system"
    // Sparkle reads this default live: unchecking it turns off silent background
    // download/install. Ships true, so updates auto-apply by default.
    @AppStorage("SUAutomaticallyUpdate") private var autoDownloadUpdates = true
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    @State private var loginToggleError: String?

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(short) (build \(build))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Identity banner (shared across pizzaClip / PICkle / HotSauce). Uses
            // the app's own icon from the system so no extra asset is needed.
            VStack(spacing: 6) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable().scaledToFit().frame(width: 64, height: 64)
                Text("HotSauce").font(.system(size: 18, weight: .bold))
                Text(L("System stats in your menu bar", "메뉴바 시스템 모니터"))
                    .font(.system(size: 12)).foregroundStyle(.secondary)
                Text(version).font(.system(size: 11)).foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 10)

            Form {
                Section(L("General", "일반")) {
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

                Section(L("Language", "언어")) {
                    Picker(L("Language", "언어"), selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { language in
                            Text(language.label).tag(language.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    Text(L("Takes effect after relaunching the app.",
                           "언어는 앱을 다시 실행하면 적용돼요."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(L("Updates", "업데이트")) {
                    Toggle(L("Automatically download updates", "업데이트 자동 다운로드"),
                           isOn: $autoDownloadUpdates)
                    Text(L("New versions are downloaded automatically and applied the next time you launch.",
                           "새 버전이 나오면 자동으로 내려받아 다음 실행 때 적용됩니다."))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    Button(L("Check for Updates…", "지금 업데이트 확인…")) {
                        NotificationCenter.default.post(name: .hotsauceCheckForUpdates, object: nil)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 500, height: 420)
    }
}

extension Notification.Name {
    /// Settings → "Check for Updates…" button → ask the updater to check now.
    static let hotsauceCheckForUpdates = Notification.Name("hotsauceCheckForUpdates")
}

/// 설정 창 관리 — SwiftUI Settings 씬 대신 직접 NSWindow 를 관리한다.
/// (LSUIElement 앱에서 Settings 씬 열기는 macOS 버전별로 신뢰할 수 없음)
final class SettingsWindowController {
    private var window: NSWindow?

    func show() {
        if window == nil {
            let hosting = NSHostingController(rootView: SettingsView())
            let window = NSWindow(contentViewController: hosting)
            window.title = L("HotSauce Settings", "HotSauce 설정")
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.setContentSize(NSSize(width: 500, height: 420))
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}
