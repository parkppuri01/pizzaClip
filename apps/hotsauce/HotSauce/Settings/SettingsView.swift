import SwiftUI
import ServiceManagement

/// 설정 창 내용 — 세 앱 공통 '일반' 레이아웃.
/// 위쪽은 앱 정체성(아이콘/이름/소개/버전) 배너, 아래쪽은 grouped 폼(일반=로그인
/// 시작 / 언어 / 업데이트). pizzaClip·PICkle 과 같은 구조라 한 디자인으로 보인다.
/// 설정 창 크기 — 뷰와 NSWindow 가 같은 값을 쓰도록 한 곳에 둔다.
///
/// 앱스토어 빌드는 '업데이트' 섹션이 없지만 **높이는 줄이지 않는다.**
/// 500×420 은 세 앱(피자·피클·핫소스) 설정창 통일 규격이자 실제 배포로 검증된 값이고,
/// 아래가 조금 비는 건 무해하지만 섹션이 잘리는 건 치명적이라 여유 쪽을 택했다.
/// (한때 MAS 를 330 으로 줄였다가 언어 섹션이 잘려 되돌렸다.)
enum SettingsWindowMetrics {
    // 높이는 "섹션이 잘리지 않는 최소값"으로 렌더해가며 맞춘 값이다.
    // 섹션이 반쯤 잘려 보이는 건 아래가 조금 비는 것보다 훨씬 나쁘다(세션 9 결론).
    #if MAS
    // 일반 + 모양 + 언어. '모양' 섹션(얼굴 아이콘 Picker + 미리보기)이 들어오면서
    // 420 으로는 '언어' 가 통째로 잘렸다. 언어 아래 안내 문구까지 다 보이는 값이 550.
    static let size = NSSize(width: 500, height: 550)
    #else
    // 직접배포 빌드에는 App Store 이전 안내 박스(~92pt)와 '업데이트' 섹션이 더 있다.
    // 채널은 마감됐지만 개발 중 이 빌드로 테스트하므로 잘리지 않게 맞춰 둔다.
    static let size = NSSize(width: 500, height: 610)
    #endif
}

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage = "system"
    /// 팝업 하단 사이트 배너 표시 여부. PopupView·DS 가 같은 키를 읽는다.
    /// 끄면 배너 블록만 빠지고 팝업이 원래 높이대로 짧아진다(푸터 여백은 유지).
    @AppStorage("showSiteBanner") private var showSiteBanner = true
    /// 팝업 얼굴 아이콘 세트. PopupView 가 같은 키를 보고 즉시 반영한다.
    @AppStorage("faceIconSet") private var faceIconSet = FaceIconSet.fallback.rawValue
    #if !MAS
    // Sparkle reads this default live: unchecking it turns off silent background
    // download/install. Ships true, so updates auto-apply by default.
    @AppStorage("SUAutomaticallyUpdate") private var autoDownloadUpdates = true
    #endif
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)
    @State private var loginToggleError: String?

    private var version: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        return "v\(short) (build \(build))"
    }

    /// 앱 언어에 맞는 개인정보처리방침. /privacy 는 미들웨어 자동 언어분기 대상이 아니라
    /// 여기서 고른 주소가 그대로 열린다.
    private var privacyURL: URL {
        URL(string: AppLocale.isKorean
            ? "https://pizza-clip.com/privacy"
            : "https://pizza-clip.com/en/privacy")!
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
                // 버전 옆에 붙여 한 줄로 — 창 높이를 늘리지 않고 방침을 노출한다.
                // (앱스토어 심사자가 설정에서 바로 찾을 수 있어야 한다)
                HStack(spacing: 6) {
                    Text(version)
                    Text("·")
                    // focusable(false) 가 없으면 이 Link 가 창의 첫 응답자로 잡혀서
                    // 설정을 열자마자 '개인정보처리방침'에 포커스 링이 걸린다.
                    // (SwiftUI Link 는 macOS 에서 버튼으로 만들어져 기본 포커스 대상이 된다)
                    Link(L("Privacy Policy", "개인정보처리방침"), destination: privacyURL)
                        .focusable(false)
                }
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 20)
            .padding(.bottom, 10)

            // 직접배포 채널 마감 안내 — 실행 시 1회 뜨는 알림(AppStoreMigration)을
            // 놓쳤거나 나중에 다시 찾는 사용자를 위한 상설 안내다.
            // 앱스토어 빌드에는 없다(이미 App Store 판이라 안내할 것이 없다).
            #if !MAS
            VStack(spacing: 5) {
                Text(L("This is the last version delivered outside the Mac App Store.",
                       "직접 다운로드로 받는 마지막 버전이에요."))
                    .font(.system(size: 11, weight: .semibold))
                Text(L("Updates now come from the App Store. Installing it replaces this copy — then quit and reopen HotSauce, and set your preferences once more.",
                       "앞으로의 업데이트는 App Store에서 받습니다. 설치하면 이 앱을 그대로 대신해요 — 설치 후 한 번 종료했다 켜고, 설정만 다시 맞춰주세요."))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                // 개인정보처리방침 Link 와 같은 이유로 focusable(false) —
                // 없으면 설정을 열자마자 이 링크에 포커스 링이 걸린다.
                // storeURL(웹) 이 아니라 storeAppURL — 브라우저를 거치지 않고
                // App Store 앱이 바로 열린다(AppStoreMigration 주석 참고).
                Link(L("Get it on the Mac App Store", "Mac App Store에서 받기"),
                     destination: AppStoreMigration.storeAppURL)
                    .focusable(false)
                    .font(.system(size: 11, weight: .semibold))
            }
            .multilineTextAlignment(.center)
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.13),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(.horizontal, 20)
            .padding(.bottom, 6)
            #endif

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
                    Toggle(L("Show site banner in popup", "팝업 하단 사이트 배너 표시"),
                           isOn: $showSiteBanner)
                }

                Section(L("Appearance", "모양")) {
                    Picker(L("Face icons", "얼굴 아이콘"), selection: $faceIconSet) {
                        ForEach(FaceIconSet.allCases) { set in
                            Text(set.label).tag(set.rawValue)
                        }
                    }
                    // 이름만으론 어떻게 생겼는지 알 수 없어서 고른 세트를 바로 보여준다.
                    // 순서는 팝업과 같게 쾌적 → 중부하 → 고부하.
                    HStack(spacing: 12) {
                        ForEach([LoadState.good, .normal, .bad], id: \.self) { state in
                            Image(nsImage: Assets.image(
                                FaceIconSet.resolve(faceIconSet).assetName(for: state)))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                        }
                        Spacer()
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

                // 앱스토어 빌드는 업데이트를 App Store 가 담당하므로 이 섹션이 없다.
                #if !MAS
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
                #endif
            }
            .formStyle(.grouped)
        }
        .frame(width: SettingsWindowMetrics.size.width,
               height: SettingsWindowMetrics.size.height)
    }
}

#if !MAS
extension Notification.Name {
    /// Settings → "Check for Updates…" button → ask the updater to check now.
    static let hotsauceCheckForUpdates = Notification.Name("hotsauceCheckForUpdates")
}
#endif

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
            window.setContentSize(SettingsWindowMetrics.size)
            window.isReleasedWhenClosed = false
            window.center()
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
        // 창을 열자마자 아무 컨트롤에도 포커스 링이 걸리지 않게 한다.
        // SwiftUI 가 첫 레이아웃에서 첫 응답자를 잡은 "뒤"라야 먹히므로 한 턴 미룬다.
        // (이게 혹시 안 먹어도 Link 는 focusable(false) 라 포커스가 '로그인 시 자동 시작'
        //  토글에 걸릴 뿐, 개인정보처리방침으로 돌아가지는 않는다.)
        DispatchQueue.main.async { [weak self] in
            self?.window?.makeFirstResponder(nil)
        }
    }
}
