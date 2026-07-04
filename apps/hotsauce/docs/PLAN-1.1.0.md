# HotSauce 1.1.0 작업 계획서

> 작성일 2026-07-05 · 대상 버전 **1.1.0** (현재 1.0.0 / build 2 → **1.1.0 / build 3**)
> 이 문서는 "무엇을 / 왜 / 어디를" 담은 **실행 대본**이다. 다음 세션(Opus 실행)에서 이 문서만 보고 바로 구현할 수 있게 파일·줄번호·코드 스케치까지 적어 둔다.

## 0. 이번에 할 일 4가지

1. **네트워크 이름(Wi-Fi SSID) 한 줄 추가** — 팝업 네트워크 섹션에 접속한 Wi-Fi 이름 표시
2. **자물쇠 잠금(팝업 고정)** — 잠그면 다른 곳 클릭해도 팝업이 안 닫힘
3. **병 폭발 이스터에그** — 항목 4개 이상이 빨강(위험)이면 핫소스 병이 팝업에서 폭죽처럼 터짐
4. **완전 자동 업데이트 적용 + 1.1.0 배포** — 사용자가 아무것도 안 해도 새 버전이 알아서 받아지고 깔림

> 참고: 프로젝트 규칙상 "계획=Fable, 실행=Opus". 이 계획서 자체는 토큰 절약을 위해 조사 완료 상태에서 직접 정리했다. **실제 구현은 다음 세션에서 Opus로** 진행한다.

---

## 1. 지금 코드 상태 (조사 결과 요약)

| 기능 | 관련 파일 | 현재 상태 |
|---|---|---|
| 네트워크 | `HotSauce/Metrics/Snapshot.swift:99` `NetworkSnapshot` | `localIP, signalBars, upload/download, isConnected` 있음. **`ssid` 없음** |
| 네트워크 샘플러 | `HotSauce/Metrics/NetworkSampler.swift:81` `signalBars()` | 이미 `CWWiFiClient.shared().interface()`로 Wi-Fi 잡고 `interface.ssid()`도 호출 중. **값을 버리고 신호세기만 씀** |
| 팝업 네트워크 UI | `HotSauce/Popup/PopupView.swift:169` `networkSection()` | 제목(762.5) + [로컬IP · 신호](802.8) + [업로드 · 다운로드](831.2) + 얼굴. **한 줄 더 넣을 자리 있음** |
| 팝업 패널(닫힘 로직) | `HotSauce/MenuBar/FocusablePanel.swift:11` `resignKey()` | 포커스 잃으면 `orderOut` + `onClose` → **무조건 닫힘**. ESC도 닫힘 |
| 팝업 생성/관리 | `HotSauce/MenuBar/StatusItemController.swift:106` `makePanel()` | 패널 1개 캐시해 재사용. `engine.isPopupVisible` 토글 |
| 지표 엔진 | `HotSauce/Metrics/MetricsEngine.swift:42` `tick()` | 1초마다 스냅샷 갱신. 각 항목 `.state`(good/normal/bad) 존재 |
| 자동 업데이트 | `HotSauce/App/AppDelegate.swift:24` + `Resources/Info.plist:38` | **Sparkle 이미 완비**: `SUAutomaticallyUpdate=true`(=자동 다운로드+설치), 자동확인 on, 하루 간격, feed·공개키 설정됨 |
| 릴리스 스크립트 | `scripts/sparkle-appcast.sh` | DMG EdDSA 서명 → `dist/appcast.xml` 생성까지 자동. 웹 복사·push는 수동 |
| 버전 | `project.yml:10` | `MARKETING_VERSION "1.0.0"`, `CURRENT_PROJECT_VERSION "2"` |

**중요한 발견 두 가지**
- 자동 업데이트는 **설정상 이미 "완전 자동 다운로드"** 상태다. 남은 건 "새 버전을 실제로 appcast에 올려서 내보내는 것".
- 폭발 이스터에그용 **전용 폭탄 이미지는 없다**. (형제앱은 `BombPizza`/`PickleBomb` 에셋 사용) → 기존 병 PNG(`menubar_1` 등)를 재활용하거나 사용자가 새 아트를 넣어야 함.

---

## 2. 형제앱 이스터에그 참고 (이미 파악 완료)

- `apps/pizzaclip/pizzaClip/Popup/PizzaBurst.swift`, `apps/pickle/PicKle/Editor/PickleBurst.swift`
- 구조: `trigger: UUID?` 를 바꾸면 파티클 34~48개가 **바닥에서 위로 튀어올랐다가 중력으로 떨어지는** SwiftUI 오버레이.
- `.task(id: trigger)` 로 트리거 바뀔 때마다 새 폭발. `allowsHitTesting(false)`로 클릭 방해 안 함.
- **`PickleBurst`가 개선판**이다: `isBursting` 플래그로 폭발 끝나면 `TimelineView`를 내려 CPU 0으로 복귀. → **이걸 베끼는 걸 추천.**
- 트리거 연결: 형제앱은 `PopupViewModel.pizzaBurstID = UUID()` → `PopupView` 안 `PizzaBurst(trigger:)`. 우리는 `MetricsEngine`에 `burstID`를 두고 같은 방식으로 연결.

---

## 3. 기능별 상세 계획

### F1. 네트워크 이름(Wi-Fi SSID) 한 줄 추가

**목적**: 팝업 네트워크 섹션에 "지금 붙어 있는 Wi-Fi 이름"을 한 줄 보여준다.

**건드릴 파일 3개**

1) `HotSauce/Metrics/Snapshot.swift` — `NetworkSnapshot`에 필드 추가 (line 99~ 부근)
```swift
struct NetworkSnapshot {
    var localIP: String? = nil
    var ssid: String? = nil          // ← 추가: 접속 Wi-Fi 이름 (유선/불명이면 nil)
    var signalBars: Int = 0
    ...
}
```

2) `HotSauce/Metrics/NetworkSampler.swift` — 이미 잡은 인터페이스에서 SSID도 같이 꺼낸다.
`signalBars(isConnected:)`(line 81)를 **bars+ssid 둘 다 반환**하도록 바꾸고, `sample()`의 line 76을 교체:
```swift
// sample() 안, 기존:  snapshot.signalBars = signalBars(isConnected: snapshot.isConnected)
let wifi = wifiInfo(isConnected: snapshot.isConnected)
snapshot.signalBars = wifi.bars
snapshot.ssid = wifi.ssid

// 아래 메서드로 교체
private func wifiInfo(isConnected: Bool) -> (bars: Int, ssid: String?) {
    guard isConnected else { return (0, nil) }
    if let itf = CWWiFiClient.shared().interface(), itf.powerOn(),
       itf.ssid() != nil || itf.rssiValue() != 0 {
        let bars: Int
        switch itf.rssiValue() {
        case (-55)...: bars = 5
        case (-65)...: bars = 4
        case (-72)...: bars = 3
        case (-80)...: bars = 2
        default:       bars = 1
        }
        return (bars, itf.ssid())   // ssid()는 nil일 수 있음(아래 리스크 참고)
    }
    return (5, nil)   // 유선 등: 신호 최대, 이름 없음
}
```

3) `HotSauce/Popup/PopupView.swift` — `networkSection()`(line 169)에 한 줄 추가:
```swift
statText(L("Wi-Fi", "네트워크 이름") + " : " + (network.ssid ?? "—"),
         left: 242, centerY: 860)   // 업로드/다운로드(831.2) 아래 새 줄
```
- 세로 여유: 다운로드 줄 831.2 → 다음 구분선 914.5 사이 공간 충분(권장 y=860).
- **주의**: 팝업은 화면 캡처가 안 되니, 구현 후 반드시 `HOTSAUCE_SNAPSHOT`(§5)으로 PNG 렌더해서 줄 안 겹치는지 눈으로 확인. 안 맞으면 y값만 미세조정.

**리스크(결정 필요) — macOS 14(Sonoma)+ 위치권한**
- `interface.rssiValue()`(신호세기)는 권한 없이 되지만, **`interface.ssid()`(이름)는 macOS 14부터 "위치 서비스" 권한이 있어야 값이 나온다.** 없으면 `nil`.
- **옵션 A(추천)**: 권한 요청 안 하고 best-effort. 이름 못 읽으면 `—` 표시. 추가 권한 팝업 없음, 구현 간단. 시스템 모니터앱엔 이게 자연스러움.
- **옵션 B**: `CoreLocation` 권한을 요청해 SSID를 확실히 읽기. 대신 첫 실행 때 위치권한 팝업이 뜬다(모니터앱치곤 부담).
- → 사용자 결정 필요. (기본값은 A로 진행 권장)

---

### F2. 자물쇠 잠금 (팝업 고정)

**목적**: 팝업을 "핀 고정"하면 다른 앱을 클릭해도 안 닫히고 계속 지표를 볼 수 있다.

**동작 원칙**: 잠금 ON = "포커스 잃어도 안 닫힘"만 막는다. 메뉴바 병 다시 클릭(`togglePopup`)이나 ESC 같은 **명시적 닫기는 그대로 동작**.

**건드릴 파일 3개**

1) `HotSauce/MenuBar/FocusablePanel.swift` — 잠금 플래그 + 닫힘 가드
```swift
final class FocusablePanel: NSPanel {
    var onClose: (() -> Void)?
    var isLocked = false            // ← 추가

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    override func resignKey() {
        super.resignKey()
        if isLocked { return }      // ← 잠금이면 포커스 잃어도 안 닫음
        orderOut(nil)
        onClose?()
    }
    // cancelOperation(ESC)는 그대로 두어 ESC로는 항상 닫히게 함(선택).
}
```

2) `HotSauce/Popup/PopupView.swift` — 헤더 우상단에 자물쇠 토글 (SF Symbol, 새 에셋 불필요)
```swift
struct PopupView: View {
    @ObservedObject var engine: MetricsEngine
    var onOpenSettings: () -> Void = {}
    var onLockChanged: (Bool) -> Void = {}     // ← 추가
    @State private var isLocked = false        // ← 추가
    ...
    // body의 ZStack 안(header 근처)에 추가:
    Image(systemName: isLocked ? "lock.fill" : "lock.open")
        .font(.system(size: DS.u(26)))
        .foregroundColor(DS.text)
        .placedCenter(845, 41.4, w: 30, h: 30)   // 헤더 우상단(빈 공간). 스냅샷으로 위치 확인
        .contentShape(Rectangle())
        .onTapGesture {
            isLocked.toggle()
            onLockChanged(isLocked)
        }
}
```

3) `HotSauce/MenuBar/StatusItemController.swift` — `makePanel()`(line 106)에서 토글을 패널에 연결
```swift
private func makePanel() -> FocusablePanel {
    var panelRef: FocusablePanel?           // 클로저가 나중 생성될 panel을 잡도록
    let content = PopupView(
        engine: engine,
        onOpenSettings: { [weak self] in
            self?.panel?.orderOut(nil)
            self?.engine.isPopupVisible = false
            self?.onOpenSettings?()
        },
        onLockChanged: { locked in panelRef?.isLocked = locked }   // ← 연결
    )
    let hosting = NSHostingView(rootView: content)
    hosting.frame = NSRect(origin: .zero, size: DS.popupSize)

    let panel = FocusablePanel(/* 기존 그대로 */)
    ...
    panelRef = panel                        // ← content 클로저가 이 패널을 잠금
    return panel
}
```

**주의 / 결정 필요**
- `AppDelegate.saveSnapshot()`(line 61)도 `PopupView(engine:)`를 만든다 → 새 인자에 **기본값**을 줬으니 그대로 컴파일된다(수정 불필요).
- 패널은 캐시 재사용 → `@State isLocked`가 다음 열림에도 유지된다(잠근 채 닫았다 열면 여전히 잠김). 이게 자연스러우면 그대로, "열 때마다 초기화"를 원하면 `showPopup()`에서 `panel.isLocked=false`로 리셋. → 기본은 "유지" 권장.

---

### F3. 병 폭발 이스터에그 (항목 4개+ 위험)

**목적**: CPU·메모리·디스크·배터리·네트워크 5개 얼굴 중 **4개 이상이 빨강(.bad)** 이 되는 극단 상황에서, 팝업에 핫소스 병이 폭죽처럼 터진다. (재미 + "니 맥 큰일났다" 신호)

**트리거 규칙**: 5개 `.state` 중 `.bad` 개수 ≥ 4. **올라가는 순간(rising edge)에 1회**만 발동(매초 도배 방지). 4-빨강은 매우 드물어서 이스터에그로 적정.

**건드릴 파일 3개(+ 신규 1)**

1) 신규 `HotSauce/Popup/HotSauceBurst.swift` — `PickleBurst.swift`를 복제해 이미지만 교체.
- 파티클 이미지: 우리 앱은 에셋카탈로그가 아니라 **낱장 PNG**를 `Assets.image(name)`로 로드한다. 따라서:
```swift
// PickleBurst의  Image("PickleBomb")  →  아래로 교체
Image(nsImage: Assets.image("menubar_1"))   // 빨간 핫소스 병 재활용(전용 폭탄 에셋 생기면 이름만 교체)
    .resizable()
    .interpolation(.high)
    .frame(width: p.size, height: p.size)
    .rotationEffect(.radians(Double(angle)))
    .position(x: x, y: y)
    .opacity(opacity)
```
- `gravity`는 PickleBurst가 640pt 캔버스 기준 600. 우리 팝업 높이 = `DS.popupSize.height = u(1000) ≈ 520pt` → **gravity ≈ 500 정도로 낮춰** 튀는 높이 균형 맞추고 스냅샷으로 확인.
- `isBursting` 게이트(폭발 끝나면 타이머 내림)까지 그대로 가져오기.

2) `HotSauce/Metrics/MetricsEngine.swift` — 트리거 발행
```swift
@Published private(set) var burstID: UUID?     // ← 추가 (PopupView가 구독)
private var wasOverloaded = false
private let overloadThreshold = 4

// tick() 끝부분(스냅샷 다 채운 뒤)에 추가:
let badCount = [snapshot.cpu.state, snapshot.memory.state, snapshot.disk.state,
                snapshot.battery.state, snapshot.network.state]
                .filter { $0 == .bad }.count
let overloaded = badCount >= overloadThreshold
if overloaded {
    if !wasOverloaded { burstID = UUID() }   // 위험 진입 순간 1회 폭발
} else {
    burstID = nil                            // 정상 복귀 시 초기화
}
wasOverloaded = overloaded
```

3) `HotSauce/Popup/PopupView.swift` — ZStack 맨 위에 오버레이 한 줄
```swift
// body의 ZStack 마지막(footer 다음)에:
HotSauceBurst(trigger: engine.burstID)
    .frame(width: DS.popupSize.width, height: DS.popupSize.height)
    .allowsHitTesting(false)
```

**동작 메모 / 결정 필요**
- 폭발은 **팝업이 열려 있을 때만 보인다.** 위험이 계속되는 동안 팝업을 새로 열면 `.task(id:)`가 마운트 시 발동 → "위험 중 팝업 열면 터짐". 자연스러움. 위험 아닐 땐 `burstID=nil`이라 안 터짐.
- 옵션(과함): 위험 진입 시 팝업을 **자동으로 띄우고** 터뜨리기. → 갑자기 창이 떠서 방해될 수 있어 기본은 "열려 있을 때만" 권장.
- **파티클 아트 결정 필요**: (A) 기존 병 PNG 재활용(`menubar_1` 빨강 / `menubar_3` 레인보우 / `hotsauce_mainicon`) 즉시 출시 가능 vs (B) 사용자가 "폭탄 핫소스" 전용 PNG 제작 후 이름만 교체. → 기본 A(추천: 위험이니 `menubar_1` 빨강 병).

---

### F4. 완전 자동 업데이트 적용 + 1.1.0 배포

**핵심 사실**: `Info.plist`에 `SUAutomaticallyUpdate=true`(자동 다운로드+설치), `SUEnableAutomaticChecks=true`(자동 확인)가 **이미 켜져 있다.** 즉 "완전 자동 다운로드"는 설정상 이미 완성. 첫 실행 때 묻는 팝업도 이 키들이 설정돼 있어 안 뜬다.

그래도 **확실히 못박는 하드닝(선택) + 실제 배포(필수)** 를 한다.

**(선택) 코드로 한 번 더 못박기** — `HotSauce/App/AppDelegate.swift` line 24 직후
```swift
updaterController = SPUStandardUpdaterController(
    startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
updaterController?.updater.automaticallyChecksForUpdates = true    // ← 확인
updaterController?.updater.automaticallyDownloadsUpdates = true    // ← 완전 자동 다운로드 못박기
```

**(선택) 설정창에 토글 노출** — `HotSauce/Settings/SettingsView.swift` 업데이트 섹션(line 54)에 "자동 업데이트" 스위치를 추가하면 사용자가 상태를 눈으로 확인 가능. (updater 참조를 넘겨야 해서 배선 약간 필요 — 여유 있을 때)

**(필수) 1.1.0 실제 배포 — 이걸 해야 기존 1.0.0 사용자가 자동으로 받는다**
1. `project.yml:10` 버전 올리기: `MARKETING_VERSION "1.0.0" → "1.1.0"`, `CURRENT_PROJECT_VERSION "2" → "3"`.
2. `dist/notes-1.1.0.md` 릴리스 노트 작성(별표 `*` 금지 — 스크립트 마크다운 제약). 예:
   ```
   # HotSauce 1.1.0
   - 네트워크 이름(Wi-Fi) 표시 추가
   - 팝업 잠금(고정) 기능 추가
   - 시스템 과부하 시 깜짝 이스터에그
   ```
3. `xcodegen generate` → 릴리스 빌드 → DMG 생성 → (필요시) 노터라이즈.
4. `DOWNLOAD_BASE_URL=https://pizza-clip.com/hotsauce ./scripts/sparkle-appcast.sh <DMG>` 실행 → `dist/appcast.xml` 생성.
5. **DMG + `appcast.xml`을 `web/public/hotsauce/`에 복사** → git push → Vercel 자동 배포.
6. 확인: `https://pizza-clip.com/hotsauce/appcast.xml` 열어 1.1.0 item 보이면 완료. 기존 사용자는 하루 안(또는 다음 확인)에 자동 수신.

---

## 4. 권장 구현 순서

1. **F1 SSID** (가장 쉬움, 파일 3곳) → 스냅샷 확인
2. **F2 자물쇠** (독립적) → 수동 확인(다른 앱 클릭해도 유지)
3. **F3 폭발** (신규 파일 + 엔진 1곳 + 팝업 1줄) → 디버그로 트리거해 확인
4. 여기까지 한 덩어리로 **빌드 통과 + 눈 확인**
5. **F4 하드닝 → 버전업 → appcast 배포** (마지막에 한 번에)

> F1~F3은 서로 독립적이라 순서 바뀌어도 됨. F4(배포)는 반드시 맨 마지막.

---

## 5. 검증 방법 (화면 캡처 없이 팝업 확인하는 법)

- **팝업을 PNG로 렌더**(가장 유용): `AppDelegate`에 `HOTSAUCE_SNAPSHOT` 훅이 이미 있다(line 52).
  빌드한 앱을 `HOTSAUCE_SNAPSHOT=/tmp/popup.png ./HotSauce.app/Contents/MacOS/HotSauce` 로 실행하면 팝업을 PNG로 저장하고 종료 → 그 PNG를 Read로 열어 **SSID 줄·자물쇠 위치**를 눈으로 검증.
- **팝업 바로 띄우기**: `HOTSAUCE_SHOW_POPUP=1` 로 실행(line 44).
- **폭발 테스트**: 4-빨강을 실제로 만들기 어려우니, 테스트 시 임시로 `overloadThreshold`를 1로 낮추거나 `HOTSAUCE_FORCE_BURST=1` 같은 디버그 훅을 잠깐 넣어 확인 후 되돌린다.
- **자물쇠 테스트**: 팝업 열고 자물쇠 클릭 → 다른 앱 클릭 → 팝업 유지되면 OK. 다시 눌러 해제 → 포커스 잃으면 닫힘.
- **빌드**: `xcodegen generate` 후 `xcodebuild -project HotSauce.xcodeproj -scheme HotSauce -configuration Debug build` (또는 기존 빌드 스크립트).

---

## 6. 결정이 필요한 것들 (사용자 확인)

| # | 항목 | 옵션 | 기본 추천 |
|---|---|---|---|
| 1 | **SSID 위치권한** | A) 권한 없이 best-effort(못 읽으면 `—`) / B) CoreLocation 권한 요청 | **A** |
| 2 | **폭발 파티클 아트** | A) 기존 병 PNG 재활용(`menubar_1`) / B) 전용 "폭탄 핫소스" PNG 제작 | **A**(나중에 B로 교체 쉬움) |
| 3 | **폭발 발동 범위** | A) 팝업 열려 있을 때만 / B) 위험 시 팝업 자동으로 띄우고 터뜨림 | **A** |
| 4 | **자물쇠 유지** | A) 닫았다 열어도 잠금 유지 / B) 열 때마다 해제 | **A** |
| 5 | **자동업데이트 하드닝/설정토글** | 코드로 못박기 + 설정창 토글 넣을지 | 코드 못박기 O, 설정토글은 여유되면 |

---

## 7. 배포 체크리스트 (F4)

- [ ] `project.yml` 버전 1.1.0 / build 3
- [ ] `dist/notes-1.1.0.md` 작성(별표 금지)
- [ ] `xcodegen generate` → 릴리스 빌드 → DMG (+노터라이즈)
- [ ] `sparkle-appcast.sh` 실행 → `dist/appcast.xml` 생성 확인
- [ ] DMG + `appcast.xml` → `web/public/hotsauce/` 복사
- [ ] git push → Vercel 배포
- [ ] `https://pizza-clip.com/hotsauce/appcast.xml` 에 1.1.0 노출 확인
- [ ] (가능하면) 1.0.0 설치본에서 자동 업데이트 수신 확인
