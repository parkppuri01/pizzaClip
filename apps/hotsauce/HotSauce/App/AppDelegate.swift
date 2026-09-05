import AppKit
import ServiceManagement
import SwiftUI
#if !MAS
// 앱스토어 빌드(MAS)는 자체 업데이트가 금지라 Sparkle 을 아예 링크하지 않는다.
import Sparkle
#endif

/// 조립 담당(composition root): 지표 엔진, 메뉴바 아이템, 설정 창, 자동 업데이트.
@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var shared: AppDelegate!

    private let engine = MetricsEngine()
    private var statusItemController: StatusItemController?
    private let settingsController = SettingsWindowController()
    #if !MAS
    private var updaterController: SPUStandardUpdaterController?
    #endif

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        shared = delegate  // app.delegate 는 weak 이므로 강한 참조 유지
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if !MAS
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        // 자동 업데이트: 백그라운드 확인은 항상 켠다. 자동 다운로드/설치 여부는
        // SUAutomaticallyUpdate 기본값(true 로 출하 · 설정 → 일반 "자동 다운로드"
        // 토글에 연동)이 결정한다. 여기서 다운로드를 강제하지 않으므로, 사용자가
        // 토글을 끄면 다음 실행에도 꺼진 상태가 유지된다.
        updaterController?.updater.automaticallyChecksForUpdates = true
        #endif

        let statusItemController = StatusItemController(engine: engine)
        statusItemController.onOpenSettings = { [weak self] in
            self?.settingsController.show()
        }
        self.statusItemController = statusItemController

        #if !MAS
        statusItemController.onCheckForUpdates = { [weak self] in
            self?.updaterController?.checkForUpdates(nil)
        }

        // Settings → "Check for Updates…" → run a manual update check.
        NotificationCenter.default.addObserver(
            forName: .hotsauceCheckForUpdates, object: nil, queue: .main
        ) { [weak self] _ in
            self?.updaterController?.checkForUpdates(nil)
        }
        #endif

        applyFirstLaunchDefaults()
        engine.start()

        #if !MAS
        // 직접배포 채널 마감 안내 — 1.3.0 이 이 경로로 받는 마지막 버전이다.
        // 메뉴바 아이콘이 자리를 잡은 뒤에 띄운다(안내부터 뜨면 "그래서 그 앱이
        // 어디 있는데?" 가 된다). 디버그 훅이 걸린 실행에서는 건너뛴다 — runModal
        // 이 블로킹이라 스냅샷 검증이 그 자리에서 멈춘다.
        if !isDebugHookRun {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                AppStoreMigration.presentIfNeeded()
            }
        }
        #endif

        // 디버그용: HOTSAUCE_SHOW_POPUP=1 로 실행하면 팝업을 바로 띄운다
        // (LSUIElement 앱은 밖에서 클릭을 흉내내기 어렵기 때문)
        if ProcessInfo.processInfo.environment["HOTSAUCE_SHOW_POPUP"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.statusItemController?.togglePopup()
            }
        }

        // 디버그용: HOTSAUCE_SNAPSHOT=<경로> 로 실행하면 팝업을 PNG 로 저장하고 종료.
        // 화면 캡처 권한 없이 디자인 검증을 하기 위한 훅. 두 빌드 모두에 남긴다 —
        // 앱스토어 빌드도 UI 검증이 필요하고, 샌드박스에서도 컨테이너 안 경로면
        // 정상 저장된다(환경변수를 안 주면 아무 일도 안 하므로 심사에도 무해).
        if let snapshotPath = ProcessInfo.processInfo.environment["HOTSAUCE_SNAPSHOT"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.saveSnapshot(to: snapshotPath)
                NSApp.terminate(nil)
            }
        }
    }

    /// 첫 실행 때 한 번만 기본값을 켠다.
    ///
    /// 팝업 배너(`showSiteBanner`)는 `@AppStorage` 기본값이 이미 true 라 여기서
    /// 손댈 게 없다. 문제는 로그인 항목인데, 이건 UserDefaults 가 아니라
    /// **시스템에 실제로 등록**해야 켜진다 — 메뉴바 앱은 로그인 때 떠 있는 게
    /// 자연스러운 기본값이라 첫 실행에 등록해 준다.
    ///
    /// ⚠️ 딱 한 번만 한다. 사용자가 설정에서 끈 것을 다음 실행에 되살리면
    ///    "꺼도 자꾸 켜지는 앱"이 되어 훨씬 나쁘다.
    /// ⚠️ 실패해도 조용히 넘어간다. 등록은 편의일 뿐이고, 실패하면 설정 창의
    ///    토글로 사용자가 직접 켜면 된다(그쪽은 실패 사유를 표시한다).
    /// 스냅샷·팝업 디버그 훅으로 띄운 실행인지.
    ///
    /// 이때는 **사용자 환경을 바꾸는 동작을 전부 건너뛴다** — 로그인 항목 등록,
    /// 1회성 안내 창처럼 "실제 사용자가 앱을 처음 켰을 때"에만 해야 할 일들이다.
    /// ⚠️ 실제로 당한 적 있다(2026-08-26): 팝업 PNG 를 뽑으려고 빌드 폴더의 앱을
    ///    잠깐 실행했을 뿐인데 `build/.../HotSauce.app` 이 사용자 로그인 항목에
    ///    등록됐다. 렌더 한 번에 남의 맥 설정이 바뀌면 안 된다.
    private var isDebugHookRun: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["HOTSAUCE_SNAPSHOT"] != nil || env["HOTSAUCE_SHOW_POPUP"] != nil
    }

    private func applyFirstLaunchDefaults() {
        guard !isDebugHookRun else { return }
        let key = "didApplyFirstLaunchDefaults"
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)

        if SMAppService.mainApp.status != .enabled {
            try? SMAppService.mainApp.register()
        }
    }

    private func saveSnapshot(to path: String) {
        let view = NSHostingView(rootView: PopupView(engine: engine))
        view.frame = NSRect(origin: .zero, size: DS.popupSize)

        let window = NSWindow(
            contentRect: view.frame, styleMask: [.borderless],
            backing: .buffered, defer: false)
        window.contentView = view
        window.colorSpace = .sRGB
        view.layoutSubtreeIfNeeded()

        guard let rep = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
        view.cacheDisplay(in: view.bounds, to: rep)
        if let data = rep.representation(using: .png, properties: [:]) {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        engine.stop()
    }
}
