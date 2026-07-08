import AppKit
import SwiftUI
import Sparkle

/// 조립 담당(composition root): 지표 엔진, 메뉴바 아이템, 설정 창, 자동 업데이트.
@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var shared: AppDelegate!

    private let engine = MetricsEngine()
    private var statusItemController: StatusItemController?
    private let settingsController = SettingsWindowController()
    private var updaterController: SPUStandardUpdaterController?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        shared = delegate  // app.delegate 는 weak 이므로 강한 참조 유지
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        // 자동 업데이트: 백그라운드 확인은 항상 켠다. 자동 다운로드/설치 여부는
        // SUAutomaticallyUpdate 기본값(true 로 출하 · 설정 → 일반 "자동 다운로드"
        // 토글에 연동)이 결정한다. 여기서 다운로드를 강제하지 않으므로, 사용자가
        // 토글을 끄면 다음 실행에도 꺼진 상태가 유지된다.
        updaterController?.updater.automaticallyChecksForUpdates = true

        let statusItemController = StatusItemController(engine: engine)
        statusItemController.onOpenSettings = { [weak self] in
            self?.settingsController.show()
        }
        statusItemController.onCheckForUpdates = { [weak self] in
            self?.updaterController?.checkForUpdates(nil)
        }
        self.statusItemController = statusItemController

        // Settings → "Check for Updates…" → run a manual update check.
        NotificationCenter.default.addObserver(
            forName: .hotsauceCheckForUpdates, object: nil, queue: .main
        ) { [weak self] _ in
            self?.updaterController?.checkForUpdates(nil)
        }

        engine.start()

        // 디버그용: HOTSAUCE_SHOW_POPUP=1 로 실행하면 팝업을 바로 띄운다
        // (LSUIElement 앱은 밖에서 클릭을 흉내내기 어렵기 때문)
        if ProcessInfo.processInfo.environment["HOTSAUCE_SHOW_POPUP"] == "1" {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
                self?.statusItemController?.togglePopup()
            }
        }

        // 디버그용: HOTSAUCE_SNAPSHOT=<경로> 로 실행하면 팝업을 PNG 로 저장하고 종료.
        // 화면 캡처 권한 없이 디자인 검증을 하기 위한 훅.
        if let snapshotPath = ProcessInfo.processInfo.environment["HOTSAUCE_SNAPSHOT"] {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
                self?.saveSnapshot(to: snapshotPath)
                NSApp.terminate(nil)
            }
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
