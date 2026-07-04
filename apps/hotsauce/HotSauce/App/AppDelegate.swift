import AppKit
import SwiftUI
import Sparkle
import CoreLocation

/// 조립 담당(composition root): 지표 엔진, 메뉴바 아이템, 설정 창, 자동 업데이트.
@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static var shared: AppDelegate!

    private let engine = MetricsEngine()
    private var statusItemController: StatusItemController?
    private let settingsController = SettingsWindowController()
    private var updaterController: SPUStandardUpdaterController?
    private let locationManager = CLLocationManager()

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
        // 완전 자동 업데이트: 자동 확인 + 자동 다운로드/설치를 코드로도 못박는다
        // (Info.plist 의 SUEnableAutomaticChecks / SUAutomaticallyUpdate 와 이중 안전장치).
        updaterController?.updater.automaticallyChecksForUpdates = true
        updaterController?.updater.automaticallyDownloadsUpdates = true

        // Wi-Fi 이름(SSID)은 macOS 14+에서 위치권한이 있어야 읽힌다. 켤 때 한 번 요청.
        // 허용하면 팝업 네트워크 섹션에 이름이 뜨고, 거부하면 "—"로 안전하게 표시된다.
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()

        let statusItemController = StatusItemController(engine: engine)
        statusItemController.onOpenSettings = { [weak self] in
            self?.settingsController.show()
        }
        statusItemController.onCheckForUpdates = { [weak self] in
            self?.updaterController?.checkForUpdates(nil)
        }
        self.statusItemController = statusItemController

        settingsController.onCheckForUpdates = { [weak self] in
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

extension AppDelegate: CLLocationManagerDelegate {
    // 델리게이트가 있어야 권한 요청 프롬프트가 뜬다. 권한이 허용되면 다음 네트워크
    // 샘플부터 SSID 가 자연히 채워지므로 별도 처리는 필요 없다.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {}
}
