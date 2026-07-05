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

        // Wi-Fi 이름(SSID)은 macOS 14+에서 위치권한이 있어야 읽힌다(Apple DTS 공식 확인).
        // LSUIElement(.accessory) 앱은 시작 시 권한창이 잘 안 뜰 수 있어, 요청 직전에
        // 앱을 잠깐 활성화해 프롬프트가 확실히 표시되게 한다.
        // 요청 자체는 여기서 무조건 쏘지 않고 델리게이트 콜백(권한 상태 분기)에 맡긴다 —
        // delegate 를 붙이면 시작 시 locationManagerDidChangeAuthorization 가 자동 1회 호출된다.
        NSApp.activate(ignoringOtherApps: true)
        locationManager.delegate = self

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
    // delegate 를 붙이면 시작 때 자동 1회 호출되고, 이후 권한이 바뀔 때마다 다시 호출된다.
    // 권한 상태별로 분기하는 게 Apple 공식 권장 패턴.
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .notDetermined:
            // 아직 안 물어봤으면 이때 권한창을 띄운다.
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            // 핵심: 권한 "허용"만으로는 SSID 가 안 채워지고, 위치 서비스가 실제로
            // 가동 중이어야 CWInterface.ssid() 가 이름을 돌려준다(커뮤니티 다수 정황).
            // 위치값 자체는 안 쓰고 SSID 부수효과만 필요하므로 정확도는 최저로 둔다.
            manager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
            manager.startUpdatingLocation()
        case .denied, .restricted:
            break  // SSID 는 팝업에서 "—" 로 안전 폴백 (NetworkSampler 처리됨)
        @unknown default:
            break
        }
    }

    // startUpdatingLocation 을 켰으므로 실패 콜백도 받아둔다(위치값은 안 쓰니 조용히 무시).
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {}
}
