#if !MAS
import AppKit
import SwiftUI

/// 직접배포(Developer ID + Sparkle) 채널 마감 안내.
///
/// 배경: 1.3.0 이 직접 다운로드로 배포하는 **마지막 버전**이다. 이후 업데이트는
/// Mac App Store 가 담당한다. 그런데 사용자가 스스로 설치하러 가야 하고,
/// 설정도 넘어가지 않는다 — 번들 ID 는 같아도 App Store 판은 샌드박스라
/// 저장 위치가 다르다(`~/Library/Preferences/` ↔ `~/Library/Containers/`, 실측 확인).
/// 그래서 "조용히 업데이트되고 끝"이면 아무도 이전 사실을 모른 채 남는다.
///
/// 도달 경로가 마땅치 않다는 게 핵심이다. Sparkle 자동 다운로드가 기본 ON 이라
/// 릴리스노트를 지나칠 수 있고, 팝업 배너는 설정에서 끌 수 있다. 앱을 켜면 반드시
/// 지나가는 이 한 번의 창만이 도달을 보장한다. 설정 창에도 같은 안내를 상설로 둔다.
///
/// 📌 앱 파일 자체는 **자동으로 대체된다**(2026-08-26 실측): 양쪽 다 이름이
///    `HotSauce.app` 이고 App Store 도 `/Applications` 에 설치하므로 같은 자리를
///    덮어쓴다. 실제로 이 맥의 직접배포 1.3.0 이 App Store 판으로 교체됐고
///    휴지통에 흔적이 없었다. 그래서 "옛 앱을 지우라"고 안내하지 않는다 — 지울 게 없다.
///    대신 **재실행**을 안내한다: 파일이 교체돼도 메모리에 떠 있던 옛 프로세스는
///    계속 살아서, 종료 전까지 옛 버전이 돌거나 병이 두 개로 보인다.
///    (옛 앱을 `/Applications` 밖에 두고 쓴 사용자는 진짜로 두 개가 공존한다.)
///
/// 🚨 **NSAlert 를 쓰면 안 된다**(2026-08-26 실기기 확인). `NSAlert.runModal()` 로
///    띄우면 창은 화면에 보이지만 **버튼이 눌리지 않는다** — 두 버튼 다 무반응이었다.
///    LSUIElement(`.accessory`) 앱이라 모달 세션이 제대로 서지 않아 창이 이벤트를
///    받지 못하는 것으로 보인다. 같은 창이 `CGWindowList` 와 `screencapture` 에도
///    안 잡혔는데, 전부 같은 원인을 가리킨다.
///    그래서 설정 창이 쓰는 "NSWindow + makeKeyAndOrderFront" 경로를 따른다 —
///    이쪽은 실제 배포로 오래 검증된 길이다.
///
/// 앱스토어 빌드(MAS)에는 통째로 들어가지 않는다 — 이미 App Store 판이라 안내할 것이 없다.
enum AppStoreMigration {
    /// 앱 언어에 맞는 스토어 **웹** 페이지(브라우저에서 열린다).
    /// 실제 버튼은 `openStore()` 를 거쳐 `storeAppURL` 을 먼저 쓰고, 이건 폴백이다.
    /// - 미국·한국 2개국에만 출시했으므로 국가 코드를 명시한다. 국가 없는 주소
    ///   (`/app/id…`)는 접속 지역으로 자동 분기하는데, 미출시 지역에서는
    ///   "사용할 수 없음"이 뜬다.
    /// - `mt=12` 는 Mac App Store 지정. 빼면 iOS App Store 로 해석될 수 있다.
    static var storeURL: URL {
        URL(string: "https://apps.apple.com/\(storeCountry)/app/hotsauce/id6801170433?mt=12")!
    }

    /// Mac App Store 앱을 **바로** 여는 주소.
    ///
    /// ⚠️ https:// 주소를 열면 App Store 가 아니라 브라우저가 뜬다(2026-08-26 실측).
    ///    거기서 "Mac App Store에서 보기"를 한 번 더 눌러야 앱으로 넘어간다 —
    ///    한 클릭이면 될 일이 세 클릭이 된다. `macappstore://` 는 LaunchServices 에
    ///    /System/Applications/App Store.app 으로 등록돼 있어 곧장 열린다(확인함).
    static var storeAppURL: URL {
        URL(string: "macappstore://apps.apple.com/\(storeCountry)/app/hotsauce/id6801170433?mt=12")!
    }

    /// 앱 언어에 맞는 스토어 국가. 미국·한국 2개국에만 출시했다.
    private static var storeCountry: String { AppLocale.isKorean ? "kr" : "us" }

    /// 안내를 이미 봤는지. 한 번 보면 다시 뜨지 않는다.
    private static let seenKey = "didShowAppStoreMigrationNotice"

    /// 창이 닫힐 때까지 살려 두는 강한 참조(지역 변수로 두면 바로 해제된다).
    private static var controller: AppStoreMigrationWindowController?

    static func openStore() {
        // App Store 앱을 먼저 시도하고, 열지 못하면 웹으로 떨어진다.
        // (스토어 앱이 지워진 맥은 사실상 없지만, 링크가 죽는 것보단 낫다.)
        if !NSWorkspace.shared.open(storeAppURL) {
            NSWorkspace.shared.open(storeURL)
        }
    }

    /// 실행 직후 1회만 안내 창을 띄운다. 이미 봤으면 아무 일도 하지 않는다.
    static func presentIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: seenKey) else { return }
        // 창을 띄우기 "전에" 기록한다 — 도중에 뭔가 잘못돼도 매 실행마다
        // 다시 뜨는 상황(사용자 입장에서 최악)만은 막는다.
        UserDefaults.standard.set(true, forKey: seenKey)

        let controller = AppStoreMigrationWindowController()
        self.controller = controller
        controller.onClose = { self.controller = nil }
        controller.show()
    }
}

/// 안내 창 내용. 설정 창과 같은 톤(아이콘 → 제목 → 설명 → 버튼)으로 맞췄다.
private struct AppStoreMigrationView: View {
    var onGetIt: () -> Void
    var onLater: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable().scaledToFit().frame(width: 72, height: 72)

            Text(L("HotSauce is moving to the Mac App Store",
                   "HotSauce가 Mac App Store로 옮겨갑니다"))
                .font(.system(size: 15, weight: .bold))
                .multilineTextAlignment(.center)
                .padding(.top, 12)

            VStack(spacing: 9) {
                Text(L("This 1.3.0 update is the last one delivered this way. From now on, HotSauce is updated through the Mac App Store.",
                       "이번 1.3.0이 이 방식으로 받는 마지막 버전이에요. 앞으로 HotSauce는 Mac App Store에서 업데이트됩니다."))
                Text(L("The App Store version replaces this one in place — there's nothing to delete. After installing, quit HotSauce from the menu bar and open it again, otherwise the old copy keeps running. (Two bottles up there means the old one is still running — just quit one.)",
                       "App Store 버전은 지금 쓰던 앱을 그대로 대신해요 — 따로 지우실 건 없습니다. 설치한 뒤에는 메뉴바의 핫소스 병을 한 번 종료했다 켜주세요. 그러지 않으면 옛 버전이 계속 돌아갑니다. (병이 두 개 보이면 옛 앱이 아직 떠 있는 거예요. 하나만 종료하면 됩니다.)"))
                Text(L("Your settings — language and launch at login — don't carry over, so you'll set them once more. It's still free, and it works exactly the same.",
                       "설정(언어·로그인 시 자동 시작)은 넘어가지 않아 한 번만 다시 맞춰주세요. 그대로 무료이고, 하는 일도 똑같습니다."))
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 12))
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 12)

            HStack(spacing: 10) {
                // focusable(false) — 이게 없으면 창을 열자마자 '나중에' 에
                // 포커스 링이 걸린다(이 맥은 키보드 탐색이 켜져 있어 더 잘 보인다).
                // 설정 창의 개인정보처리방침 Link 와 같은 처방이다.
                Button(L("Later", "나중에")) { onLater() }
                    .focusable(false)
                // 기본 버튼(Return) + 시스템 강조색 채움 — 사용자 결정대로
                // 브랜드 색을 따로 칠하지 않고 macOS 표준 강조를 쓴다.
                // focusable(false) 여도 keyboardShortcut 은 그대로 동작한다.
                Button(L("Get it on the App Store", "App Store에서 받기")) { onGetIt() }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .focusable(false)
            }
            .controlSize(.large)
            .padding(.top, 20)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 24)
        .frame(width: 420)
    }
}

/// 안내 창 관리 — 설정 창(SettingsWindowController)과 같은 검증된 경로를 쓴다.
/// LSUIElement 앱에서 신뢰할 수 있는 유일한 방식이다(위 NSAlert 주석 참고).
final class AppStoreMigrationWindowController {
    private var window: NSWindow?
    var onClose: (() -> Void)?

    func show() {
        let view = AppStoreMigrationView(
            onGetIt: { [weak self] in
                AppStoreMigration.openStore()
                self?.close()
            },
            onLater: { [weak self] in self?.close() })

        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "HotSauce"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false

        // ⚠️ SwiftUI 레이아웃을 먼저 확정시킨다. 이걸 건너뛰고 크기를 정하면
        //    창이 미확정 크기로 배치돼 화면 밖에 놓인다(설정 창이 멀쩡한 이유는
        //    거기선 setContentSize 로 크기를 못 박기 때문이다).
        hosting.view.layoutSubtreeIfNeeded()
        window.setContentSize(hosting.view.fittingSize)
        placeAtScreenCenter(window)
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)

        // 한 턴 미뤄서 두 가지를 마무리한다.
        //  ① 위치 재확정 — 창을 표시하면 SwiftUI 가 레이아웃을 한 번 더 돌면서
        //     프레임이 바뀌고, 표시 "전"에 잡아둔 좌표가 어긋난다(실측: 화면 밖으로
        //     밀려났다). 표시가 끝난 뒤 다시 가운데로 놓아야 확실하다.
        //  ② 포커스 링 해제 — SwiftUI 가 첫 응답자를 잡은 뒤라야 먹힌다
        //     (설정 창 SettingsWindowController.show() 와 같은 처방).
        DispatchQueue.main.async { [weak self] in
            guard let self, let window = self.window else { return }
            self.placeAtScreenCenter(window)
            window.makeFirstResponder(nil)
        }
    }

    /// 화면 가운데 배치.
    ///
    /// ⚠️ `NSWindow.center()` 를 쓰지 않는다 — 이 앱에서 실제로 창이 화면 밖
    ///    (y ≈ -1049) 에 놓였다(2026-08-26 실측). LSUIElement 앱은 키 윈도우가
    ///    없어 `NSScreen.main` 이 기대대로 잡히지 않을 수 있어서, 화면을 직접
    ///    골라 좌표를 계산한다. 마지막에 화면 안으로 한 번 더 밀어 넣는다.
    private func placeAtScreenCenter(_ window: NSWindow) {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        let visible = screen.visibleFrame
        let size = window.frame.size
        var origin = NSPoint(x: visible.midX - size.width / 2,
                             y: visible.midY - size.height / 2)
        // 화면 밖으로 벗어나지 않게 클램프(다중 디스플레이·해상도 변화 대비).
        origin.x = min(max(origin.x, visible.minX), visible.maxX - size.width)
        origin.y = min(max(origin.y, visible.minY), visible.maxY - size.height)
        window.setFrameOrigin(origin)
    }

    private func close() {
        window?.close()
        window = nil
        onClose?()
    }
}
#endif
