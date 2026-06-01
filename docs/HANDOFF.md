# Session Handoff — pizzaClip

마지막 업데이트: 2026-05-30 (**🎉 v1.0.0 정식 출시 완료**: 빌드→공증 2라운드(.app+DMG, 둘 다 Accepted+staple)→GitHub 릴리스 v1.0.0→`pizza-clip.com/appcast.xml` 라이브→`/Applications` 설치까지 끝. 다운로드 버튼=고정이름 `pizzaClip.dmg` 직접다운로드, Sparkle 자동업데이트 라이브(설치본 build 10=최신, **다음 릴리스 build 11+부터 자동 적용**). 웹사이트(pizza-clip.com)는 **2026-05-30 개편 완료** — 웹 핸드오프는 [`web/HANDOFF.md`](../web/HANDOFF.md) 로 분리)

이 문서는 새 Claude 세션에서 작업을 이어갈 때 한 번 읽으면 컨텍스트가 잡히도록 만들어졌습니다.

## 0. 웹사이트(`web/`)는 별도 핸드오프로 분리 🌐

랜딩 사이트(pizza-clip.com) 관련 **현황·구조·작업 기록·교훈·남은 task 는 모두 [`web/HANDOFF.md`](../web/HANDOFF.md) 로 옮겼습니다.** 웹 작업은 그 문서를 보세요.

- 2026-05-30 사이트 개편 완료(카피 전면 교체 · INFO 페이지 신설 · 전역 90% 스케일 · 정렬 버그 수정 · 네비/버튼 폰트 확대 · 하단/GitHub 버튼 정리 · 네비 무줄바꿈) → master 푸시 → Vercel 라이브.
- 진입: "pizza-clip.com 수정하자" → `cd web && npm run build` 통과 → master 푸시 = 자동배포.

(아래 §1 부터는 **앱(Swift) 핸드오프**입니다.)

---

## 0.5 다음 앱 업데이트 예정사항 (TODO — **앱 수정 세션에서 처리**) 🔔

> 사용자가 v1.0.0 출시 직후 요청(2026-05-30). **다음에 앱 코드를 만질 때 이 두 가지를 같이 처리하고, 세션 시작 시 사용자에게 먼저 상기시킬 것.** (바로 다음 예정 세션은 웹이라, 웹 끝나고 앱 손볼 때 적용.)

1. **릴리스 노트 보여주기** — 지금은 Sparkle 업데이트 알림창에 버전 숫자만 뜸(appcast `<item>`에 설명 없음). 업데이트 팝업에 "이번에 바뀐 점"이 보이도록:
   - `scripts/release.sh`의 appcast `<item>` 생성부에 `<description><![CDATA[ …HTML… ]]></description>` 또는 `<sparkle:releaseNotesLink>` 추가.
   - 노트 소스: `dist/notes-<버전>.md`(이미 생성됨) 또는 CHANGELOG → HTML 변환. (어디서 가져올지 결정 필요.)

2. **⌘P = "핀"이 아니라 "1번 슬롯 고정"으로 변경** — 현재 ⌘P는 pin(상단 부유 + 핀 아이콘, 슬롯 1~9 번호에서 제외). 요청: **⌘P 누르면 그 항목을 슬롯 1번에 고정**하고, 그 뒤로 복사되는 항목은 **2번부터** 쌓이도록(고정 항목이 1번 자리에서 안 밀려남).
   - ⚠️ 구현 전 사용자에게 확인할 것: ① 고정은 **1개만**(1번 전용)인지 여러 개 가능(1,2,3…)인지 — 표현상 1개 같지만 확인. ② 기존 pin 개념을 완전히 대체할지(핀 아이콘/부유 동작 제거?). ③ 직접붙여넣기 `⌘⌥⌃1~9` / `0=9→1 전체붙여넣기`와의 상호작용. ④ 시각 표시(1번 배지 강조? 자물쇠 아이콘?).
   - 관련 파일: `Popup/PopupPanelController.swift`(handleKey: ⌘P→togglePin), `Popup/PopupViewModel.swift`, `Storage/HistoryStore.swift`(pin/topN/슬롯 로직), `Storage/Item.swift`(pinned 필드), `Popup/PopupView.swift`·`PopupRow.swift`(슬롯 번호/핀 표시).

---

## 1. 프로젝트 한 줄 요약

macOS 메뉴바 클립보드 히스토리 앱. SwiftUI + AppKit, GRDB SQLite, KeyboardShortcuts, **Sparkle 2 자동업데이트** (0.1.7). 개인 사용 + 랜딩페이지 배포 목적, **Apple Developer ID 서명 + hardened runtime + notarize + staple** (0.1.6), Universal binary, macOS 13+.

- **위치**: `/Users/parkjaekeun/DEV/ProjectJAM/pizzaClip`
- **현재 버전**: **1.0.0 (정식 출시)** (`project.yml` MARKETING 1.0.0, CURRENT 10)
- **브랜치**: `master` (단일 브랜치 운영)
- **빌드 스크립트**: `./scripts/release.sh` (테스트 → Release 빌드 → **Sparkle 임베드 헬퍼 Developer ID 재서명** → .app notarize → staple → DMG sign → DMG notarize → DMG staple → **/Applications 설치** → **ZIP EdDSA 서명 + appcast `<item>` 생성**. 0.1.6 Developer ID + 2-round notary, 0.1.7 Sparkle 추가)

## 2. 첫 진입 시 읽어야 할 것

| 우선순위 | 파일 |
|---|---|
| 1 | 이 파일 (`docs/HANDOFF.md`) — 최신 상태 |
| 2 | `git log --oneline` — 시간순 진행 기록 |
| 3 | `docs/qa/checklist.md` — 현재 동작 명세 (실행 가능한 형태) |
| 4 | `docs/superpowers/specs/2026-05-21-pizzaClip-design.md` — 초기 설계 의도 (역사적) |
| 5 | `docs/superpowers/plans/2026-05-21-pizzaClip.md` — 초기 16-task 구현 플랜 (역사적, 이미 모두 완료) |

## 3. 현재 기능 상태

### 작동 검증된 동작

- 자동 캡처: 텍스트 / 이미지 (스크린샷) / Finder 파일 / **Finder 이미지 파일** (원본 포맷 보존)
- 글로벌 단축키: ⌘⇧V (팝업), ⌘⌥⌃1~9 (직접 붙여넣기)
- 팝업 내부: ↑↓ 키보드 네비게이션, ↵ 또는 숫자 1~9 붙여넣기, **0 = 9→1 full paste (slot 9부터 1까지 순차 붙여넣기)**, ⌫ 삭제, ⌘P 핀, ⎋ 닫기
- 마우스: hover로 highlight (스크롤 안 함), 휠 스크롤, 클릭으로 picking
- 팝업 라이브 갱신: 열려있는 동안 다른 앱에서 ⌘C해도 즉시 반영
- **팝업 포커스 잃으면 자동 close** (다른 창 클릭 시 — 0.1.1)
- 상태바 아이콘: 좌클릭=팝업(슬라이드 다운 애니메이션), 우클릭=메뉴
- **상태바 피자 아이콘 PNG 단계 표시** (0.1.6: 10단계로 정리): 사용자 제공 PNG 10단계를 `pizzaClip/Resources/Assets.xcassets/PizzaIcon0~9.imageset` 으로 번들. 히스토리 0개 → PizzaIcon0, 1~7개 → PizzaIcon1~7 (슬라이스 1~7개), 8개 → PizzaIcon8 (피자박스 한 개, 뚜껑 열린 상태), 9개+ → PizzaIcon9 (피자박스 쌓인 이미지). 이전 Core Graphics 직접 드로잉은 제거됨. `template-rendering-intent: original` 로 painted 컬러 유지. (0.1.5 까지의 "슬라이스 8개" 아이콘은 제거 — 8개 자리에 곧바로 박스 표시)
- **앱 아이콘 PNG → .icns 자동 빌드** (0.1.3): 사용자 제공 1024px `assets/pizzaClipAppIcon.png` 를 `sips`+`iconutil` 로 10개 사이즈 iconset → `pizzaClip/AppIcon.icns` 생성. Info.plist `CFBundleIconFile=AppIcon` 그대로
- **팝업 타이틀바 아이콘 = 🍕 이모지 + "pizzaClip — Clipboard History"** (0.1.3에서 텍스트 rename)
- **9 → 1 full paste 버튼** (0.1.2): 검색 박스 자리. 클릭 또는 바 0 키 → top-9 비핀 항목을 slot 9(오래된 것)부터 slot 1(최신)까지 순차로 이전 앱에 붙여넣기 (각 paste 사이 0.18s stagger)
- **🍕 이스터에그** (0.1.4: exact match): 클립보드 텍스트가 **정확히 `pizza` 한 단어** (대소문자/주변 공백 무시) 일 때만 팝업 자동 오픈 + 🍕 이모지 48개가 팝콘 터지듯 바닥에서 튀어 올랐다가 중력으로 떨어지는 burst 애니메이션 (총 2.4초). 0.1.3 의 substring 매치는 너무 자주 발동해서 제거. 또한 팝업 재오픈 시 stale `pizzaBurstID` 재생되던 버그 fix — `show()` 진입 시 viewModel.pizzaBurstID = nil. SwiftUI `ForEach` + `.position` + `.rotationEffect`, `TimelineView(.animation)` 매 프레임 갱신, `.task(id:)` 로 트리거
- **오른쪽 ⌘ 탭 → 한/영 토글** (0.1.5, 옵트인): Settings → Shortcuts → "Input source" 섹션 체크박스 ON 시 활성화. 오른쪽 ⌘ 키만 단독으로 눌렀다 뗐을 때 (다른 키·모디파이어 동반 없음) Carbon TIS API 로 한국어 ↔ Latin 키보드 입력 소스 전환. 우⌘+C 같은 chord 사용은 영향 없음. 체감 딜레이 ~10ms 이하 (Karabiner-Elements 수준)
- **권한 자동 복구** (0.1.6): 우⌘ 토글 ON 인 상태에서 Accessibility 권한이 없으면 tap 생성 실패 → 사용자가 시스템 설정에서 권한 부여하는 순간 자동으로 tap 재생성. 신호 3종: (1) DistributedNotificationCenter `com.apple.accessibility.api` 노티, (2) NSWorkspace 앱 activation, (3) 2초 폴링 (앞 둘이 안 와도 안전망). 사용자가 pizzaClip Settings 로 돌아와서 체크박스 재토글할 필요 없음
- **Developer ID 마이그레이션 알림** (0.1.6, 1회): 기존 0.1.5 사용자가 0.1.6 처음 켤 때 NSAlert 1회 — "권한 재승인이 필요합니다" + "시스템 설정 열기" 버튼. UserDefaults `didMigrateToDeveloperID` 로 다시 안 뜸. `didShowAccessibilityPrompt` 가 false (= 신규 설치) 면 알림 스킵하고 그냥 표시 플래그만 set
- **🍕 한글 '피자' 트리거** (0.1.6): 기존 영문 "pizza" exact match 외에 한국어 "피자" exact match 도 burst 발동 (부분 매치는 여전히 안 함 — "피자 먹자" 같은 문장은 트리거 X)
- Settings: ⌘, / 상태바 우클릭 / 팝업 푸터 클릭 모두 동일한 SwiftUI Settings 창 ("pizzaClip Settings" 타이틀)
- **팝업 푸터 Clear all 버튼** (0.1.1): 휴지통 + 라벨, 클릭 시 NSAlert 확인 후 wipe
- 검색: HistoryStore 레이어는 FTS5 그대로 유지(테스트도 통과). 팝업 UI 검색 박스는 cap≤20이라 의미가 없어 제거됨
- 자동 정리: cap 초과 시 오래된 비핀부터 삭제 (블롭 파일까지 정리)
- **파일 경로 해결** (0.1.1): Finder `.file/id=…` reference URL을 `NSURL.filePathURL`로 실제 경로로 해결. 해결 실패 시 capture 거부
- **content-signature dedup** (0.1.1): monitor 레벨에서 같은 내용 연속 emit 차단 (macOS가 한 copy에 changeCount 두 번 올리는 경우 / 같은 파일 재캡처)

### 설계 결정 (논의 후 확정)

| 결정 사항 | 이유 |
|---|---|
| **이미지 원본 포맷 보존** (옵션 B) | JPG→PNG 재인코딩 시 용량 10배, HEIC 비효율, GIF 애니메이션 손실. Finder 이미지는 raw bytes 그대로 저장 + paste 시 원본 UTType + PNG fallback |
| **History cap 기본 9, 최대 20** | 200은 오버스펙. 일상 사용에 9개로 충분 |
| **Settings 열기 = Cmd+, 합성** | `NSApp.sendAction("showSettingsWindow:")`이 deprecated + no-op. NSEvent.postEvent으로 ⌘, 키 이벤트 합성해 NSApp 큐에 던짐 |
| **팝업이 Settings 열 때 close(restorePreviousApp: false)** | 일반 close는 이전 앱 재활성화 → Settings 포커스 빼앗김 방지 |
| **hover → scroll 분리** | 키보드 nav에만 `scrollTo`, hover는 highlight만. 0.25s hover-ignore window로 키보드 직후 마우스 흔들림 방지 |
| **FocusablePanel 서브클래스** | 기본 NSPanel은 borderless + nonactivatingPanel 조합에서 SwiftUI 입력 못 받음. `canBecomeKey/canBecomeMain` 강제 override |
| **NSStatusItem 좌/우클릭 분기** | `statusItem.menu` 영구 attach 안 함. button action에서 currentEvent.type 검사해 분기 |
| **Accessibility 권한 1회 prompt** | `prompt: true` 호출은 UserDefaults `didShowAccessibilityPrompt` 플래그로 가드. 이후 "Grant Accessibility…" 메뉴는 시스템 설정 직행 |
| **앱 아이콘 위치** (0.1.3 갱신) | 소스 PNG는 `assets/pizzaClipAppIcon.png` (앱 번들 외부, xcodegen sources 제외). `.icns`는 release 시 `sips`+`iconutil` 로 빌드되어 `pizzaClip/AppIcon.icns` 에 들어감 |
| **상태바 피자 아이콘 = 미리 그린 PNG** (0.1.3 변경) | 0.1.1의 Core Graphics 동적 드로잉은 깔끔했지만 사용자가 더 표현력 있는 PNG 디자인을 제공해서 Assets.xcassets 기반으로 전환. `PizzaIcon.swift` 는 카운트 → 이미지 이름 매핑만 |
| **자체서명 cert `projectJAM1s` 사용** (0.1.4 도입) | 0.1.3 까지의 ad-hoc 서명은 cdhash 가 매 빌드마다 바뀌어서 TCC Accessibility grant 가 매번 revoke됐음. Keychain Access 자체서명 cert (Code Signing, 10년 유효) 로 전환하면 identity 기반 grant 라서 cdhash 가 바뀌어도 유지됨. project.yml `CODE_SIGN_STYLE: Manual`, `CODE_SIGN_IDENTITY: "projectJAM1s"`. 처음 한 번 TCC 등록한 뒤로는 release 마다 다시 grant 안 해도 됨 |
| **이스터에그 burst = SwiftUI 진짜 View (Canvas X)** (0.1.3) | 처음엔 Canvas + `gc.draw(text:)` 로 구현했는데 macOS 13에서 emoji 가 그려지지 않는 케이스 발견. ForEach + Text + `.position` 으로 교체해 시각 보장. 48개 정도는 60fps 가능 |
| **show + trigger race fix** (0.1.3) | `showWithPizzaBurst` 가 `show()` 직후 동기로 `triggerPizzaBurst()` 호출하면 SwiftUI 첫 mount 와 동시라 `.onChange` 가 놓침. `DispatchQueue.main.async` 로 한 틱 미루고 `PizzaBurst` 는 `.task(id:)` 로 mount + change 둘 다 잡음 |
| **CGEventTap session-level + listenOnly** (0.1.5 한/영 토글) | HID-level 탭은 Input Monitoring 권한 추가로 필요하지만 session-level + listenOnly 는 Accessibility 만으로 충분. 키 이벤트도 흘려보내기만 하므로 다른 단축키 시스템과 충돌 없음. release 트리거 (press X) 로 chord 와 솔로 탭 구분 |
| **TIS 대상 = "ko" 언어 보유 여부로 분기** (0.1.5) | 입력 소스 ID 문자열 매칭 (e.g. `com.apple.inputmethod.Korean.2SetKorean`) 은 사용자가 다른 한국어 방식 (3벌식, 천지인 등) 을 쓰면 깨짐. `kTISPropertyInputSourceLanguages` 가 `["ko"]` 면 한국어 소스로 간주. 다중 한국어 소스 환경에서도 동작 |
| **/Applications 설치** (0.1.5) | `~/Applications` 는 Spotlight·Launchpad 노출이 일관적이지 않음. 일반 사용자의 macOS 앱이라면 `/Applications` 가 표준 위치. admin 계정이면 sudo 없이 cp 됨. 비-admin 사용자는 권한 부족으로 실패할 수 있지만 이 프로젝트는 단일 사용자 (admin) 기준 |

## 4. 파일 맵

```
pizzaClip/
├── App/                          # composition root
│   ├── pizzaClipApp.swift        # @main struct PizzaClipApp, Settings { SettingsView() } 씬 선언
│   ├── AppDelegate.swift         # 모든 wiring + 상태바 + 알림 옵저버 + 이스터에그 트리거
│   └── AppPaths.swift            # ~/Library/Application Support/pizzaClip 경로
├── Clipboard/
│   ├── Pasteboard.swift          # PasteboardReader 프로토콜
│   ├── CapturedItem.swift        # value type, text/imageData/sourceBundleID
│   └── ClipboardMonitor.swift    # Timer 폴링 + 분류기 + 드롭 룰
├── Storage/
│   ├── Item.swift                # GRDB record
│   ├── Schema.swift              # v1 (items) + v2-fts5 마이그레이션
│   ├── HistoryStore.swift        # insert/topN/pin/prune/clearAll/search + 알림 발송
│   └── BlobStore.swift           # 이미지 파일 저장 (원본 포맷 유지)
├── Paste/
│   └── PasteEngine.swift         # pasteboard 쓰기 + ⌘V 합성 (CGEvent)
├── Popup/
│   ├── PopupView.swift           # SwiftUI — 타이틀바(🍕)/9→1 full paste 행/리스트/푸터/이스터에그 overlay
│   ├── PopupRow.swift            # 행 (썸네일/제목/슬롯배지)
│   ├── PopupViewModel.swift      # 항목·선택 상태 + 키보드 vs 호버 구분 + pizzaBurstID 트리거
│   ├── PopupPanelController.swift # FocusablePanel 라이프사이클 + 키 모니터 + showWithPizzaBurst
│   └── PizzaBurst.swift          # 🍕 이스터에그 burst (TimelineView + ForEach particles)
├── Settings/
│   └── SettingsView.swift        # TabView (General/Shortcuts/Privacy/Storage) + 알림 이름들
├── Shortcuts/Shortcut.swift      # KeyboardShortcuts.Name 확장 (togglePopup, slot 1~9)
├── InputSource/
│   └── HangulToggler.swift       # 우⌘ tap → Carbon TIS 한국어↔Latin 입력 소스 토글 (0.1.5)
├── Permissions/Accessibility.swift # 1회 prompt, openSystemSettings
├── DesignSystem/
│   ├── Colors.swift              # 코랄 액센트 #D97757
│   └── Theme.swift               # panelRadius, rowRadius, panelWidth=440, panelHeight=480
├── MenuBar/
│   └── PizzaIcon.swift           # NSImage(named: "PizzaIcon\(n)") 로딩만 (Core Graphics 드로잉 제거)
├── Resources/
│   └── Assets.xcassets/
│       └── PizzaIcon{0..9}.imageset/  # 10단계 PNG @1x/@2x, template-rendering-intent: original (0.1.6 부터 슬라이스 7개 + 박스 2단계)
├── AppIcon.icns                  # release.sh 가 sips+iconutil 로 빌드 (커밋 대상)
└── Info.plist                    # LSUIElement=YES, CFBundleIconFile=AppIcon, CFBundle*=pizzaClip
```

```
assets/pizzaClip-icon.png         # README 등에서 쓰는 작은 아이콘
assets/pizzaClipAppIcon.png       # 1024px 앱 아이콘 소스 (xcodegen 번들 외부)
scripts/release.sh                # 빌드+패키징+배포 한방
dist/                             # gitignored, release.sh 결과물
pizzaClipTests/                   # 25개 XCTest (HistoryStore·BlobStore·ClipboardMonitor·Pasteboard)
docs/
├── HANDOFF.md                    # 이 파일
├── qa/checklist.md               # 수동 QA
└── superpowers/{specs,plans}     # 역사적 문서 (파일명 pizzaClip-*)
```

## 5. 알림 (Notification.Name) 인벤토리

`SettingsView.swift`와 `HistoryStore.swift`에 분산 정의 (0.1.3에서 `.myclip*` → `.pizzaClip*` rename):

| 이름 | 발송 | 옵저버 |
|---|---|---|
| `.pizzaClipClearAll` | Settings → Clear all 버튼 / 팝업 footer Clear all | AppDelegate → `store.clearAll()` |
| `.pizzaClipExportHistory` | Settings → Export to text 버튼 | AppDelegate → 텍스트 파일 작성 |
| `.pizzaClipOpenSettings` | 팝업 푸터 ⌘, Settings 클릭 | AppDelegate → 합성 ⌘, 발사 |
| `.pizzaClipHistoryChanged` | HistoryStore의 insert/delete/togglePin/clearAll | AppDelegate → status icon refresh + PopupPanelController (panel 보일 때만) → `viewModel.reload()` |
| `.pizzaClipHangulToggleChanged` (0.1.5) | Settings → "Input source" 체크박스 변경 | AppDelegate → `HangulToggler.shared.setEnabled(bool)`. `object` 에 `NSNumber(value: bool)` 동봉 |

## 6. 데이터 & 권한

- **저장**: `~/Library/Application Support/pizzaClip/` (Settings에서 변경 가능)
  - `db.sqlite` — 텍스트, 메타데이터, 썸네일
  - `blobs/<uuid>.{png,jpg,heic,gif,…}` — 원본 포맷 이미지 파일
  - **마이그레이션 노트**: 0.1.3 에서 디렉토리 이름이 `myclip` → `pizzaClip` 으로 변경. 기존 데이터 유지하려면 1회 수동 이동: `mv ~/Library/Application\ Support/myclip ~/Library/Application\ Support/pizzaClip`
- **권한**: Accessibility 하나만 필요 (⌘V 합성용). 거부해도 클립보드까지는 들어감
- **Bundle ID**: `com.jekeun.pizzaClip` (0.1.3 변경). 이전 `com.jekeun.myclip` 으로 받은 TCC grant / KeyboardShortcuts 설정 / UserDefaults 플래그는 새 ID 에서 재설정 필요
- **코드사인**: 자체서명 `projectJAM1s` (0.1.4). cdhash 가 바뀌어도 TCC grant 유지. cert 갱신 만료: 2036-05-24
- **마이그레이션 플래그**:
  - `didShowAccessibilityPrompt` — 권한 다이얼로그 1회 제한
  - `didMigrateCapTo9` — cap=10에서 9로 1회 마이그레이션

## 7. 다음 버전 범위 (확정)

**다음 앱 업데이트에 진행할 것은 §0.5 의 두 가지뿐이다.**

1. 업데이트 알림창에 릴리스 노트(바뀐 점) 표시 — §0.5 참고
2. ⌘P = "1번 슬롯 고정" 으로 변경 — §0.5 참고

> 이전에 "후속 거리 / 다음 세션 후보" 로 적어두었던 항목들(멀티모니터 마우스 추종, 5MB 텍스트 트런케이션, Launch-at-Login 토글, Privacy 탭 drag-drop UI, dedupe 인덱스 최적화, DB 메인스레드 쓰기, prune 게이팅, 이스터에그 파티클 이미지 교체, release.sh 아이콘 자동 빌드 등)은 **2026-06-02 사용자 결정으로 범위에서 제외**했다. 나중에 다시 필요해지면 그때 새로 올린다.

## 8. 빌드 / 테스트 / 배포

```bash
cd /Users/parkjaekeun/DEV/ProjectJAM/pizzaClip

# 프로젝트 생성 (.xcodeproj는 gitignored)
xcodegen generate

# 테스트
xcodebuild -project pizzaClip.xcodeproj -scheme pizzaClip -destination 'platform=macOS' test

# 개발용 실행 (Xcode가 가장 편함)
open pizzaClip.xcodeproj   # 그리고 ⌘R

# 배포 빌드 + 패키징 + ~/Applications 설치
./scripts/release.sh
```

배포 빌드는 항상 ad-hoc 서명 — 외부 배포 전엔 Developer ID로 재서명 + notarization 필요.

## 9. 작업 컨벤션

- **커밋 메시지**: conventional commits 스타일 (feat/fix/perf/refactor/chore/docs)
- **본문**: 무엇/왜를 두세 문단으로 (저자: Claude Opus 4.7 자동 co-author 안 함, 이 프로젝트는 단독 개발자)
- **테스트**: 모든 수정 후 `xcodebuild ... test`로 25개 통과 확인. 새 기능엔 TDD 권장 (Storage·Monitor는 그렇게 함)
- **버전 bump**: `project.yml`의 `MARKETING_VERSION` + `CURRENT_PROJECT_VERSION` 두 곳만 수정. `Info.plist`는 `$(MARKETING_VERSION)` placeholder를 쓰므로 손대지 않음 (0.1.1에서 정리됨)
- **xcodegen**: project.yml만 손대고 `xcodegen generate`로 .xcodeproj 재생성. .xcodeproj는 절대 직접 편집 금지
- **xcodegen이 새 파일 자동 인식**: `pizzaClip/` 트리에 파일 추가만 하면 자동으로 픽업 — **단 새 .swift 추가 후엔 `xcodegen generate` 한 번 더 돌려야 빌드에 포함됨** (0.1.3 PizzaBurst.swift 추가 시 첫 빌드가 "cannot find PizzaBurst in scope" 로 실패해서 확인)

## 세션 노트 — 2026-05-30 (🎉 v1.0.0 정식 출시 + 다운로드 직접화)

**범위**: v1.0.0 정식 배포(공증 포함) + 다운로드 링크 직접다운로드화 + Sparkle 자동업데이트 라이브.

### 한 일 (커밋·푸시 완료)
1. `chore: bump 1.0.0` — MARKETING 1.0.0 / CURRENT 10. (0.1.8 은 바이너리 미배포라 건너뜀.)
2. `feat(web): direct DMG download button + macOS/notary note` — 다운로드 버튼을 `…/releases/latest/download/pizzaClip.dmg`(고정 파일명) 로 변경 → 한 클릭에 최신 DMG 바로 받기, 버전 올라가도 링크 수정 불필요. 카드 문구 '준비 중' → macOS 호환/공증/무료. (`web/src/consts.ts`, `index.astro`)
3. `chore(release): upload fixed-name pizzaClip.dmg` — release.sh 가 버전 DMG 외에 고정이름 `pizzaClip.dmg` 사본도 GitHub 릴리스에 업로드(스테이플 티켓 유지).
4. `PUBLISH=1 ./scripts/release.sh` 실행 → v1.0.0 정식 릴리스.

### 릴리스 결과 (라이브 검증됨)
- 공증 2라운드(.app id `240a170c…`, DMG id `76b4eedc…`) 모두 **Accepted + staple**. Gatekeeper: `accepted, Notarized Developer ID`.
- `/Applications/pizzaClip.app` = **1.0.0** 설치·실행됨.
- GitHub 릴리스: <https://github.com/parkppuri01/pizzaClip/releases/tag/v1.0.0> — 자산 3개: `pizzaClip-1.0.0.dmg`(5.49MB), `pizzaClip-1.0.0.zip`(4.97MB, Sparkle 자동설치용), `pizzaClip.dmg`(고정 이름, 웹 버튼용).
- 다운로드 버튼 → 302 → `…/v1.0.0/pizzaClip.dmg` → HTTP 200 정상.
- `pizza-clip.com/appcast.xml` 라이브: v1.0.0 아이템(`sparkle:version=10`, `shortVersionString=1.0.0`, EdDSA 서명, enclosure=v1.0.0 zip). **자동업데이트 준비 완료** — 설치본이 build 10 이라 지금은 "최신", **다음 릴리스(build 11+)부터 자동 적용**.

### 다음 버전 내는 법 (Sparkle 자동업데이트 사이클)
1. `project.yml` MARKETING/CURRENT 올림 (예: `1.0.1` / `11`).
2. `PUBLISH=1 ./scripts/release.sh` 한 방 → 공증 2라운드 + GitHub 릴리스 생성 + 고정 DMG 업로드 + `web/public/appcast.xml` 재생성·커밋·푸시(→Vercel) 전부 자동.
3. 기존 1.0.0 사용자에게 자동 업데이트 내려감(하루 1회 체크 + 메뉴 "Check for Updates…").
- ⚠️ 비공개 EdDSA 서명키 분실 주의(분실 시 향후 업데이트 서명 영구 불가). 백업 위치는 사용자 본인만 보관.
- ⚠️ 공증 전 시스템 시계 동기화 필요(`--timestamp` 가 시계 어긋나면 거부). 해외/절전 후 주의.

---

## 세션 노트 — 2026-05-29 (0.1.8 새 아이콘 + 팝업 색상 + 자동업데이트 실제 배선)

**범위**: 앱쪽 대기열(§"앱 배포 미완 항목") 정리 + 사용자 요청 3건(아이콘 교체 / 팝업 색상 / 버전 표시 확인).

### 핵심 변경 (커밋 4개, master 푸시 완료)
1. `feat(app): new app icon (pizza-cutter on document) + auto-built icns` — 새 1024px PNG → `assets/pizzaClipAppIcon.png`, `AppIcon.icns` 재생성, `scripts/build-icon.sh` 신설.
2. `feat(popup): brand color refresh — brick-red + amber, day/night adaptive` — `Colors.swift` 에 `Color(light:dark:)` 적응형 헬퍼. 2색 역할 분리: **벽돌색 #A2371F** = 선택/푸터 액션/틴트, **앰버 #FFB703** = 슬롯 배지·"0" 칩(네이비 글자)·핀. 라이트=진한 골드/벽돌, 다크=밝은 앰버/테라코타.
3. `chore(release): wire live auto-update — SUFeedURL, appcast, publish + icon build` — Info.plist SUFeedURL=pizza-clip.com, `web/public/appcast.xml` 빈 스켈레톤, release.sh 에 아이콘 자동빌드 + DOWNLOAD_BASE_URL(GitHub) + PUBLISH=1 발행 블록.
4. `chore: bump 0.1.8` — MARKETING 0.1.8 / CURRENT 9.

### 버전 표시 (사용자 요청) — 이미 되어 있었음
Settings → General → About → "Version" = `CFBundleShortVersionString (CFBundleVersion)`. 0.1.7 에서 추가됨. 추가 작업 없음.

### 검증
- 유닛 테스트 25개 통과 + Swift(적응형 색) 컴파일 OK.
- **실제 앱 데이/나이트 팝업 캡처**로 색상 확인. 메뉴바 앱이라 자동 캡처가 까다로웠음 — 교훈 아래.

### 디버깅 교훈 (메뉴바 앱 스크린샷)
- `screencapture` CLI 는 호출 프로세스에 **화면 녹화 권한** 필요 → Bash 에선 "could not create image from display" 로 막힘.
- computer-use `request_access` 는 **LSUIElement(accessory) 앱을 이름/번들ID 로 못 잡음** → 빌드 산출물 Info.plist 의 `LSUIElement` 를 false 로 플립 + ad-hoc 재서명하면 일반 앱으로 인식돼 허용됨.
- computer-use 가 합성한 ⌘⇧V(전역 핫키)는 **Carbon 핫키를 트리거 못 함** + 노치로 메뉴바 아이콘 타겟 불안정 → 임시 `PIZZACLIP_AUTOSHOW=1` 런치 훅으로 팝업 자동표시 후 캡처(검증 끝나고 훅 제거함).
- 외관 토글: `osascript -e 'tell application "System Events" to tell appearance preferences to set dark mode to ...'` 동작(권한 프롬프트 없었음).

### ⚠️ 다음 (자동업데이트 라이브까지 남은 것)
- **첫 릴리스 미실행**: `PUBLISH=1 ./scripts/release.sh` 로 0.1.8 GitHub 릴리스 + appcast 발행 (notarize ~10분, keychain 잠금해제). 실행 전엔 GitHub Release 0개라 사이트 다운로드 링크 404.
- **Vercel 웹 배포 미확인**: appcast 가 `https://pizza-clip.com/appcast.xml` 로 실제 응답하려면 web/ 가 Vercel 에 배포돼 있어야 함(HANDOFF §"셋업 진행 중"). 미배포면 업데이트 체크가 조용히 실패.
- 0.1.6→0.1.8 은 수동 재다운로드(0.1.6 엔 Sparkle 없음). **0.1.8→다음 이 첫 자동 사이클**.

---

## 10. 세션 노트 — 2026-05-29 (0.1.7 Sparkle 2 자동업데이트 — 앱쪽 완료 + 호스팅 인프라 셋업: GitHub 공개 repo + web/ Astro + Vercel/도메인)

**범위 합의**: 앱쪽 Sparkle 통합 + 키 생성 + release.sh 서명 단계까지만. **사이트쪽(도메인/Vercel appcast 호스팅/gh release 업로드)은 이번 세션에서 제외** — repo·도메인 확정 후 진행.

### 핵심 변경

1. **Sparkle 2 SPM 의존성**: `project.yml` `packages:` 에 `Sparkle: github.com/sparkle-project/Sparkle from 2.6.0` + target dependency. 실제 resolve 된 버전 **2.9.2**. 버전 bump 0.1.7 / CURRENT 8.
2. **EdDSA 키쌍 생성** (`generate_keys`):
   - 비공개키 → **login 키체인** (account 기본값 `ed25519`). 이 맥에만 존재.
   - 공개키 → Info.plist `SUPublicEDKey` = `KR0QzoAjNr4/Crb4N+2AEGL2GKvfX8PO/yTA3sTQolg=`
   - **백업**: `~/pizzaClip-sparkle-PRIVATE-KEY-BACKUP.txt` (44 bytes, base64). ⚠️ **이 키를 잃으면 향후 모든 업데이트 서명 불가** → 1Password 등 안전한 곳에 옮기고 평문 파일은 삭제 권장. (repo 밖이라 git 추적 안 됨)
   - CLI 도구 위치: `./build/SourcePackages/artifacts/sparkle/Sparkle/bin/{generate_keys,sign_update}` (SPM resolve 후 생김). 기존 키 조회 `generate_keys -p`, 백업 export `generate_keys -x <file>`.
3. **Info.plist 키 추가**:
   - `SUPublicEDKey` (위 공개키)
   - `SUFeedURL` = `https://REPLACE-WITH-VERCEL-DOMAIN.invalid/appcast.xml` ⚠️ **플레이스홀더**. `.invalid` TLD라 백그라운드 체크는 조용히 실패. **도메인 확정되면 반드시 교체**. (메뉴 "Check for Updates…" 수동 클릭은 교체 전까진 에러 다이얼로그 뜸)
   - `SUEnableAutomaticChecks=true`, `SUAutomaticallyUpdate=true` (기본 자동 다운로드+설치), `SUScheduledCheckInterval=86400` (24h)
4. **AppDelegate** ([App/AppDelegate.swift](../pizzaClip/App/AppDelegate.swift)): `import Sparkle` + `SPUStandardUpdaterController(startingUpdater:true)` 프로퍼티 1개. context 메뉴 "Settings…" 다음에 "Check for Updates…" 항목 추가 — target = updaterController, action = `checkForUpdates(_:)`. 컨트롤러가 `canCheckForUpdates` 로 항목 자동 enable/disable.
5. **Settings → General** ([Settings/SettingsView.swift](../pizzaClip/Settings/SettingsView.swift)): Section 3개(History/Updates/About)로 정리.
   - **Updates**: "Download updates automatically" Toggle, `@AppStorage("SUAutomaticallyUpdate")` 기본 true. Sparkle 이 같은 defaults 키를 live 로 읽으므로 체크박스 토글이 곧바로 `automaticallyDownloadsUpdates` 를 구동.
   - **About**: "Version" = `CFBundleShortVersionString (CFBundleVersion)` 표시 → 사용자가 Settings 에서 현재 버전 확인 가능 (이번 세션 요청 사항).
6. **release.sh 확장** ([scripts/release.sh](../scripts/release.sh)):
   - **(중요) Sparkle 임베드 헬퍼 Developer ID 재서명** — 빌드 직후, notary 제출 전. `sparkle_resign()` 가 bottom-up 으로 `XPCServices/Downloader.xpc`, `Installer.xpc`, `Updater.app`, `Autoupdate`, `Sparkle.framework` 순서로 `--options runtime --timestamp` 재서명 후 outer `.app` 를 빈 entitlements 로 재봉인. 이어서 `codesign --verify --deep --strict` 하드 체크.
   - **ZIP EdDSA 서명**: notarize+staple 된 ZIP 을 `sign_update` 로 서명 → `sparkle:edSignature="…" length="…"` 출력.
   - **appcast `<item>` 생성**: `dist/appcast-item-<버전>.xml` (sparkle:version=빌드번호, shortVersionString=마케팅버전, minimumSystemVersion=13.0, enclosure url=`${DOWNLOAD_BASE_URL}/pizzaClip-<버전>.zip`). `DOWNLOAD_BASE_URL` env 로 다운로드 호스트 주입 (기본 `.invalid` 플레이스홀더).
   - gh release + Vercel 푸시는 스크립트 말미 **TODO 주석**으로만 (repo/도메인 미정).

### 디버깅 교훈

1. **`xcodebuild build` 는 임베드 프레임워크를 Developer ID 로 재서명하지 않는다** — Xcode Archive/Export 만 해줌. 그래서 빌드 직후 Sparkle 의 중첩 XPC/Updater.app/Autoupdate 가 **ad-hoc** (`flags=0x10002(adhoc,runtime)`, `TeamIdentifier=not set`) 상태 → notary 거부 대상. 해결: 위 #6 bottom-up 재서명. 재서명 후 전부 `flags=0x10000(runtime)` + Developer ID + secure Timestamp + TeamIdentifier 로 확인됨.
2. **Sparkle 공식 문서의 "별도 서명 불필요" 는 Archive/Export 워크플로 한정** — 우리처럼 `xcodebuild build` + 수동 notary 파이프라인엔 해당 안 됨.
3. **non-sandboxed + hardened runtime 엔 Sparkle 전용 entitlement 불필요** (sandbox 일 때만 XPC entitlement 필요). 기존 빈 entitlements 그대로 OK.

### ⚠️ 0.1.6 → 0.1.7 은 자동 업데이트 안 됨

Sparkle 은 **이미 Sparkle 이 박힌 앱만** 업데이트 가능. 0.1.6 엔 Sparkle 이 없으므로 **0.1.6 → 0.1.7 은 수동 재다운로드**(랜딩페이지 DMG). **0.1.7 → 0.1.8 이 첫 자동 업데이트 사이클**. (실사용자가 본인뿐이면 영향 미미.)

### 검증

- 유닛 테스트 25개 통과.
- Release 유니버설 빌드 성공 + 재서명 후 `codesign --verify --deep --strict` 통과 (notary-ready). **실제 notary 제출은 이번 세션에서 안 함** (호스팅 미정이라 릴리스 미실행).

### 커밋 완료 (master, origin 동기화됨)

이번 세션 변경분은 모두 커밋·푸시됨 (워킹트리 깨끗, `master...origin/master`):
- `feat(updates): Sparkle 2 자동업데이트 통합 + 버전 표시; 0.1.7` (280794e)
- `chore(release): Sparkle 임베드 헬퍼 재서명 + ZIP EdDSA 서명 + appcast item` (3124bef)
- `docs: 0.1.7 Sparkle 자동업데이트 핸드오프 노트` (950f7ef)
- `docs: GitHub repo 생성 반영` (053787d)
- `chore(web): Astro 프로젝트 스캐폴드 (Vercel 호스팅용)` (f68435e)

### 🌐 사이트 1차 완성 (2026-05-29) → 상세는 web/HANDOFF.md

랜딩 사이트 1차 구현(Astro 6.4.2 스캐폴드 · 디자인 토큰 · 공용 컴포넌트 · 3페이지 · 폰트 self-host · 블로그 Content Layer). 이후 Vercel 배포 + 도메인 연결 + 직접 다운로드 전환 완료. 2026-05-30 전면 개편까지 모두 라이브. **웹 관련 상세·구조·교훈·남은 task 는 [`web/HANDOFF.md`](../web/HANDOFF.md) 로 이전.**

### 인프라 메모 (이제 전부 라이브)

- **GitHub repo**: `parkppuri01/pizzaClip` (PUBLIC, `master`). `origin` = **HTTPS** (`gh auth setup-git` 토큰; SSH 키 미등록이라 `git@` 푸시는 실패 → https 만 사용).
- **도메인/배포**: `pizza-clip.com` (Cloudflare DNS, **회색 구름=DNS only**; 주황 구름=프록시면 SSL 충돌) + Vercel(프로젝트 `pizza-clip`, **Root Directory = `web`**). `SUFeedURL` = `https://pizza-clip.com/appcast.xml`.
- 웹 구조·작업 상세 → [`web/HANDOFF.md`](../web/HANDOFF.md).

### ✅ 앱 배포 미완 항목 — **전부 완료 (v1.0.0, 2026-05-30)**

> 아래는 당시 미완 목록의 역사적 기록. **2026-05-30 v1.0.0 출시로 전 항목 해소됨** (위 v1.0.0 세션 노트 참고): SUFeedURL 라이브, release.sh 발행 자동화 검증, GitHub 릴리스 v1.0.0 생성(자산 3개), appcast 라이브, Vercel 배포 확인, 아이콘 자동빌드. 첫 자동 사이클은 v1.0.0→다음 버전.

자동업데이트를 **실제로 가동**하려면 아직 남은 것들:

1. ~~**`SUFeedURL` 교체**~~ → **완료 (0.1.8)**: `Info.plist` SUFeedURL = `https://pizza-clip.com/appcast.xml`.
2. ~~**release.sh 배포 자동화 미배선**~~ → **완료 (0.1.8)**: `PUBLISH=1 ./scripts/release.sh` 가 (a) `gh release create`(없으면)/`upload`(있으면) 로 ZIP+DMG 업로드, (b) `web/public/appcast.xml` 을 서명된 `<item>` 으로 재생성(최신 1개), (c) appcast 커밋·푸시(→Vercel). `DOWNLOAD_BASE_URL` 기본값 = `https://github.com/parkppuri01/pizzaClip/releases/download/v<버전>`. 일반 `./scripts/release.sh` 는 발행 안 함(로컬 빌드/공증/설치만).
3. ~~**GitHub Release 0개**~~ → **완료 (v1.0.0)**: 릴리스 v1.0.0 생성, 자산 `pizzaClip-1.0.0.{dmg,zip}` + 고정이름 `pizzaClip.dmg`. 다운로드 버튼은 `…/releases/latest/download/pizzaClip.dmg` 직접다운로드.
4. ~~**appcast.xml 미존재**~~ → **부분 완료 (0.1.8)**: `web/public/appcast.xml` 에 유효한 빈 채널 스켈레톤 커밋됨(첫 발행 전 404 방지). 실제 `<item>` 은 위 PUBLISH 실행이 채움. **단 Vercel 배포가 돼야 라이브** (아래 ⓘ).
5. **enclosure 포맷** — ZIP=Sparkle 자동설치용(appcast 가 가리킴), DMG=수동 다운로드용. release.sh 가 둘 다 생성.
6. **0.1.6→0.1.7 은 수동** — 0.1.6 엔 Sparkle 없음 → 기존 사용자 수동 재다운로드. **0.1.7→0.1.8 이 첫 자동 사이클**.
7. ~~**(선택) release.sh 아이콘 자동빌드**~~ → **완료 (0.1.8)**: `scripts/build-icon.sh`(sips 10단계 + iconutil) 신설, release.sh 가 빌드 직전 자동 호출. 이제 `assets/pizzaClipAppIcon.png` 만 바꾸면 됨.
8. ~~**🔑 비공개 서명키 백업**~~ → **완료 (2026-05-29)**: 사용자가 키를 별도 안전한 곳에 적어두고 평문 파일 `~/pizzaClip-sparkle-PRIVATE-KEY-BACKUP.txt` 삭제함. (분실 시 향후 모든 업데이트 서명 영구 불가 — 백업본 잘 보관할 것.)

---

## 11. 이전 세션 노트 — 2026-05-29 (0.1.6 Developer ID + notarize + TCC 자동복구 + 한글 이스터에그 + 아이콘 10단계 정리)

**Phase A 의 모든 작업** — 랜딩페이지 배포 준비 완료. Sparkle 자동업데이트는 0.1.7 로 분리.

### 핵심 변경

1. **상태바 피자 아이콘 11단계 → 10단계로 정리**: 슬라이스 8 아이콘 삭제, PizzaIcon9 (피자박스 뚜껑열림) 이 8개 자리로, PizzaIcon10 (박스 쌓임) 이 9+ 자리로. `PizzaIcon.swift` `min(10, count)` → `min(9, count)`
2. **Apple Developer ID 인증서로 코드서명 전환**: `Developer ID Application: jaekeun park (R684FN2S7J)`. project.yml `CODE_SIGN_IDENTITY` 갱신, `ENABLE_HARDENED_RUNTIME: YES`, `OTHER_CODE_SIGN_FLAGS: "--timestamp"`, `CODE_SIGN_ENTITLEMENTS: pizzaClip/pizzaClip.entitlements` (빈 dict)
3. **Release 구성에서 `CODE_SIGN_INJECT_BASE_ENTITLEMENTS: NO`** — Xcode 가 자동 주입하는 `com.apple.security.get-task-allow` 가 Release 빌드까지 따라와서 notary 가 거부 (`The executable requests the com.apple.security.get-task-allow entitlement`). per-config 설정으로 Debug 디버깅은 유지하면서 Release 만 클린
4. **`release.sh` 가 2라운드 notary 수행**:
   - 라운드 1: `.app` ZIP 묶어서 제출 → staple
   - DMG 생성 (stapled .app 안에 들고)
   - `codesign --sign Developer\ ID... --timestamp` 로 DMG 자체 서명
   - 라운드 2: 서명된 DMG 제출 → staple
   - 결과: `.app` 도 stapled, DMG 도 signed + notarized + stapled → 사용자 DMG 마운트 시 Gatekeeper 경고 없음
5. **앱 전용 비번 + 키체인 프로파일 `pizzaClip notary`**: `xcrun notarytool store-credentials` 로 1회 등록. release.sh 는 `--keychain-profile "pizzaClip notary"` 로 참조 (비번 노출 X)
6. **한글 '피자' 이스터에그**: `text.lowercased() == "pizza" || trimmed == "피자"`. Exact match 만, substring 트리거는 여전히 거부
7. **TCC 권한 자동복구** (`HangulToggler`): `wantsEnabled` 추가로 사용자 의도 보존, `installPermissionObserversIfNeeded()` 가 DistributedNotificationCenter (`com.apple.accessibility.api`) + NSWorkspace activation 노티 listen + 2초 timer fallback. 권한 들어오는 순간 자동으로 `startTap()` 재시도
8. **0.1.5 → 0.1.6 마이그레이션 알림**: `showDeveloperIDMigrationAlertIfNeeded()` — UserDefaults `didMigrateToDeveloperID` 가드, `didShowAccessibilityPrompt=true` (= 기존 사용자) 인 경우만 표시. "기존 항목 제거 후 재추가" 단계 안내

### 디버깅 교훈

1. **시계 동기화**: Apple `--timestamp` 서명은 시스템 시계가 정확해야 함 (오차 ~수 분). 19분 30초 어긋났더니 `timestamps differ by 1173 seconds` 거부. `sudo sntp -sS time.apple.com` 또는 시스템 설정 자동 동기화 토글로 fix. 해외 출장·노트북 절전 후엔 종종 어긋남
2. **notary 거부 패턴 1 — get-task-allow**: 위 #3 참고. Xcode 의 base entitlements 자동 주입이 Release 까지 따라옴. per-config `CODE_SIGN_INJECT_BASE_ENTITLEMENTS: NO`
3. **notarytool `--wait` 의 stdout 파싱 함정**: 출력에 "Current status: In Progress" 가 N번 반복되고 마지막에 "  status: Accepted" 가 옴. `awk '/status:/ {print $2}'` 는 첫 매치 "Current status:" 의 $2 = "status:" 를 잡아서 가짜 fail. 해결: `awk '$1 == "status:" {print $2; exit}'` 로 정확 매치
4. **DMG staple 은 DMG 도 notarize 돼야 함**: ZIP-포장 .app 만 제출한 상태에서 `stapler staple <dmg>` 하면 `CloudKit Record not found` 로 실패. DMG cdhash 가 Apple 티켓 풀에 없기 때문. 두 옵션: (a) DMG staple 생략하고 .app 만 stapled 로 두기, (b) DMG 도 sign + notarize + staple. 옵션 B 가 macOS 사용자 UX 표준 → 채택
5. **TCC identity 전환은 1회 reset 불가피**: `projectJAM1s` → Developer ID 는 시스템이 다른 앱으로 인식. 기존 grant 살릴 방법 없음. 이번 1회만 사용자가 시스템 설정에서 기존 항목 제거 후 재추가. 이후 0.1.7, 0.1.8 ... 은 Developer ID identity 유지라 grant 안 풀림

### 새 파일

- `pizzaClip/pizzaClip.entitlements` — 빈 dict (hardened runtime 호환)

### 배포

- 0.1.6 (`project.yml` MARKETING 0.1.6, CURRENT 7)
- `dist/pizzaClip-0.1.6.{zip,dmg}` — DMG 사용자 받아서 마운트 → Gatekeeper 통과 → /Applications 드래그
- `/Applications/pizzaClip.app` 자체도 stapled

### 미커밋 (다음 세션에서 정리)

이번 세션의 변경분 다수 미커밋. 제안 split:
- `chore(menubar): drop 8-slice icon, shift box stages one earlier (10 stages)`
- `feat(easter-egg): trigger on Korean '피자' as well as 'pizza'`
- `feat(hangul-toggle): auto-recover when Accessibility grant arrives later`
- `feat(launch): show one-time Developer ID migration alert for 0.1.5 users`
- `chore(release): switch to Developer ID Application + hardened runtime + notarize`
- `chore(release): 2-round notary for DMG (sign + submit + staple)`
- `chore: bump 0.1.6`
- `docs: 0.1.6 handoff + QA checklist refresh`

---

## 12. 이전 세션 노트 — 2026-05-28 (0.1.5 한/영 토글 + /Applications + 새 앱 아이콘)

**Settings → Shortcuts → "Input source" (옵트인 우⌘ 한/영 토글)**

- 새 파일 `pizzaClip/InputSource/HangulToggler.swift` 약 135줄
- 핵심: `CGEvent.tapCreate(tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly, ...)` + `kCGEventFlagsChanged` / `kCGEventKeyDown` 마스크
- 우⌘ vs 좌⌘ 구분: 키코드 54 + `event.flags.rawValue & 0x10` (NX_DEVICERCMDKEYMASK)
- "clean tap" 판정: press 시 `dirtied = false`, 다른 키나 다른 모디파이어가 닿으면 `dirtied = true`. release 시 dirtied 가 false 면 트리거
- TIS 호출: `TISCreateInputSourceList(filter, false)` 로 활성+선택 가능 키보드 소스 → `kTISPropertyInputSourceLanguages` 에 `"ko"` 포함 여부로 한국어 분기 → 현재와 반대 카테고리의 첫 소스로 `TISSelectInputSource`
- AppDelegate 가 launch 시 `UserDefaults.standard.bool(forKey: "rightCommandHangulToggle")` 확인 + `.pizzaClipHangulToggleChanged` 옵저버 등록. 토글 ON 시 `AXIsProcessTrusted()` 체크해서 미부여면 alert + 시스템 설정 안내 후 자동 OFF
- `tapDisabledByTimeout` / `tapDisabledByUserInput` 발사 시 자동 재활성화 (`CGEvent.tapEnable(tap: port, enable: true)`)

**왜 session-level + listenOnly 인가**

- HID-level (`kCGHIDEventTap`) 은 Input Monitoring TCC 권한이 따로 필요. session-level + listenOnly 는 Accessibility 만으로 충분
- 사용자가 이미 paste 용 Accessibility 를 grant 한 상태라 추가 권한 다이얼로그 없음
- 이벤트 흘려보내기만 하므로 (return passUnretained) 우⌘ 가 다른 시스템 단축키와 충돌하지 않음

**체감 검증**

- 사용자 피드백: "체감 아주좋아" — Karabiner-Elements 수준의 즉각 반응. 60Hz 한 프레임 (16ms) 안에 끝남

**`/Applications` 설치 전환**

- release.sh: `mkdir -p ~/Applications` 제거, `cp` 대상 `/Applications` 로
- admin 그룹 멤버는 sudo 없이 쓰기 가능 (`ls -ld /Applications` → `drwxrwxr-x root admin`)
- 부수효과: 기존 `~/Applications/pizzaClip.app` 잔류는 사용자 환경에 없어서 cleanup 불필요했음 (사전 확인 완료)
- 실행 중 재설치 주의: `rm -rf /Applications/pizzaClip.app` 가 디스크 번들 지워도 메모리 프로세스는 살아있음. release 전 `pkill -x pizzaClip` 수동 권장 (release.sh 자체에 포함 안 함 — 사용자 모를 사이에 죽이지 않기 위해)

**새 앱 아이콘 자산 갱신**

- 사용자가 `pizzaClip/AppIcon.png` 위치에 새 1024px PNG (86KB) 떨어뜨림 — 빌드 시스템이 못 보는 위치라서 dead asset 상태였음
- `assets/pizzaClipAppIcon.png` 로 옮기고 sips (16/32/64/128/256/512 + @2x 변형 10개) + `iconutil -c icns` 로 `pizzaClip/AppIcon.icns` 재생성
- 240KB icns 갱신, `CFBundleIconFile=AppIcon` 매핑은 그대로

**커밋 시리즈 (4개)**

```
4cb7b5b chore: bump 0.1.5
2a76e43 feat(shortcuts): right ⌘ tap toggles Hangul/Latin input source
1652d7c chore(app): refresh AppIcon from new 1024px source
94f6f70 chore(release): install release builds to /Applications
```

**버전 / 배포**

- 0.1.5 (`project.yml` MARKETING 0.1.5, CURRENT 6)
- `./scripts/release.sh` 로 `dist/pizzaClip-0.1.5.{zip,dmg}` 생성, `/Applications/pizzaClip.app` 0.1.5 설치 + 실행
- TCC Accessibility 는 0.1.4 → 0.1.5 path 변경에도 `projectJAM1s` identity 가 동일해서 grant 유지됨 (자체서명 cert 도입 효과)

---

## 13. 이전 세션 노트 — 2026-05-27 (0.1.4 버그 픽스 + 자체서명)

**0.1.3 사용 중 발견된 3개 버그 픽스**

1. **이스터에그 너무 자주 발동**: `text.range(of: "pizza", options: .caseInsensitive) != nil` 로 substring 매치 → "Pizza party" 같은 문장도 트리거. **fix**: `text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "pizza"` 로 정확 단어 매치만 인정 (`AppDelegate.swift` onCapture)
2. **팝업 재오픈 시 burst 재생**: `pizzaBurstID` 가 viewModel 에 남아있어서 새 popup 마운트 시 `.task(id:)` 가 또 발사. **fix**: `PopupPanelController.show()` 진입 시 `viewModel.pizzaBurstID = nil` 로 클리어. 정상 발동인 `showWithPizzaBurst` 는 그 다음에 새 UUID 를 set 하므로 영향 없음
3. **자체서명 cert 도입**: 권한 문제로 paste 안 되던 증상이 cdhash 변경 + bundle ID 변경의 합쳐진 페인이었음. Keychain Access 자체서명 `projectJAM1s` 생성 (Code Signing, 10년) → 코드 서명 trust 설정 (Keychain Access → 인증서 정보 → 신뢰 → 코드 서명: 항상 신뢰) → project.yml `CODE_SIGN_STYLE: Manual`, `CODE_SIGN_IDENTITY: "projectJAM1s"`. 이후 빌드마다 cdhash 가 바뀌어도 identity 기반으로 TCC 유지됨

**아이콘 자산 추가**
- `PizzaIcon10.imageset` 추가 (사용자 제공 PNG, 1x 36×36 + 2x 72×72, `template-rendering-intent: original`)
- `PizzaIcon.swift` 의 `min(9, count)` → `min(10, count)` 로 11단계 매핑
- 의미: 0 = 빈 상태, 1~8 = 슬라이스 1~8개, 9 = 피자박스 1개 (capacity), 10+ = 피자박스 쌓임 (overflow)

**Self-signed cert 만들기 (재현 메모)**
- Keychain Access (`/Applications/Utilities/키체인 접근.app`) → 메뉴바 → 인증서 지원 → 인증서 생성…
- 이름: `projectJAM1s`, Identity Type: Self Signed Root, Certificate Type: Code Signing, "기본값을 무시" 체크
- Validity: 3650 일 (10년)
- 생성 후 **로그인 키체인 → 내 인증서 → projectJAM1s 더블클릭 → 신뢰 섹션 → 코드 서명: 항상 신뢰**
- `security find-identity -p codesigning -v` 로 인식 확인 (trust 설정 전엔 0개로 나옴)
- 빌드 시 codesign 이 키체인 잠금해제 비번 묻는 다이얼로그 뜸 → 맥북 로그인 비번 + "항상 허용"

**버전 / 배포**
- 0.1.4 bump (`project.yml` MARKETING 0.1.4, CURRENT 5)
- `./scripts/release.sh` 로 `dist/pizzaClip-0.1.4.{zip,dmg}` 생성, `~/Applications/pizzaClip.app` install
- 첫 0.1.4 실행 시 TCC Accessibility 1회 grant 필요 (`tccutil reset Accessibility com.jekeun.pizzaClip` 후 시스템 설정 토글). 이후 0.1.5, 0.1.6… 빌드해도 동일 cert 로 서명되므로 grant 유지

---

## 14. 이전 세션 노트 — 2026-05-26 (0.1.3 작업 완료, 미커밋이었음)

**변경된 동작 / 자산**
- 앱/번들 전면 rename: `myclip` → `pizzaClip`
  - 디렉토리: `myclip/` → `pizzaClip/`, `myclipTests/` → `pizzaClipTests/`
  - Xcode 프로젝트: `pizzaClip.xcodeproj`
  - Bundle ID: `com.jekeun.pizzaClip`, struct `PizzaClipApp`
  - Notification.Name 4종 `.myclip*` → `.pizzaClip*`
  - 사용자 표시 텍스트 (팝업 타이틀, Settings 타이틀, Quit 메뉴, Accessibility 알림 등), 데이터 경로 (`~/Library/Application Support/pizzaClip/`), 익스포트 파일명 (`pizzaClip-history.txt`), 로그 prefix 모두 갱신
  - project.yml, Info.plist, release.sh, README.md, docs/qa/checklist.md 일괄 정리 (docs/superpowers 의 spec/plan 역사적 문서는 내용만 보존)
- 상태바 피자 아이콘을 사용자 제공 PNG 10단계로 교체
  - `pizzaClip/Resources/Assets.xcassets/PizzaIcon{0..9}.imageset` (각 imageset 안에 PNG @1x + @2x, `template-rendering-intent: original`)
  - `MenuBar/PizzaIcon.swift` 는 Core Graphics 드로잉 코드 삭제, `NSImage(named: "PizzaIcon\(n)")` 로딩만
  - 0~8개 → PizzaIcon0~8 / 9개+ → PizzaIcon9. 기존 "박스" 상태 제거 (PizzaIcon9 가 가득찬 피자 디자인)
- 앱 아이콘 교체: 사용자가 `pizzaClip/pizzaClipAppIcon.png` (1024px) 제공 → `assets/pizzaClipAppIcon.png` 로 이동 → `sips`+`iconutil` 로 10단계 iconset 생성 → `pizzaClip/AppIcon.icns` 덮어쓰기
- **🍕 이스터에그**: 클립보드 텍스트에 "pizza" 포함되면 (case-insensitive 부분 매치) 팝업 자동 오픈 + 🍕 48개 burst
  - 신규: `pizzaClip/Popup/PizzaBurst.swift` (SwiftUI ForEach + Text + .position + .rotationEffect, TimelineView 매 프레임 갱신, .task(id:) 트리거)
  - 물리: 바닥에서 위로 발사 (vy 360~560 px/s, gravity 600 px/s²) → 정점 통과 후 다시 떨어짐. 좌우 drift, 회전, 페이드 인/아웃, 0~0.32s 스태거. 총 2.4초
  - `PopupViewModel.pizzaBurstID: UUID?` + `triggerPizzaBurst()` 신규
  - `PopupView.ZStack` 최상단에 overlay (clipShape + allowsHitTesting false)
  - `PopupPanelController.showWithPizzaBurst(anchorRect:)` — 팝업 안 보이면 show, 그리고 burst 트리거
  - `AppDelegate.setUpMonitor.onCapture` 가 `text.range(of: "pizza", options: .caseInsensitive)` 검사 → `showWithPizzaBurst` 호출

**디버깅 교훈 (다음에 같은 실수 안 하려고)**

1. **xcodegen 은 새 파일 추가 시 재생성 필요**: `PizzaBurst.swift` 만 추가하고 빌드 → "cannot find 'PizzaBurst' in scope". `xcodegen generate` 다시 돌려야 sources 에 포함됨. (HANDOFF §9 의 "자동 인식" 은 디렉토리 스캔 시점 기준이라 manifest 안 갱신하면 빌드 못 잡음.)
2. **Canvas + drawLayer + emoji 그리기는 macOS 13 에서 안 그려질 수 있음**: 처음에 `TimelineView { Canvas { gc, _ in gc.drawLayer { ctx in ctx.draw(Text("🍕"), at: ...) } } }` 로 짰는데 사용자 환경에서 아무것도 안 보임. 일반 SwiftUI Text + .position 으로 교체해서 해결. Canvas 가 빠르긴 한데 emoji rasterise 신뢰성은 진짜 view 쪽이 압도적.
3. **SwiftUI `.onChange` 는 view mount 와 같은 tick 에 발생한 변경을 놓침**: `showWithPizzaBurst` 가 `show()` 직후 동기로 `triggerPizzaBurst()` 호출 → SwiftUI 첫 body 평가와 동시 → `.onChange` 가 미설치 상태. `DispatchQueue.main.async` 로 한 틱 미루고, 부수적으로 `PizzaBurst` 는 `.onChange` → `.task(id:)` 로 교체해서 mount + change 둘 다 보장.
4. **새 빌드 안 됐는지부터 의심**: "이스터에그가 안 돼요" 진단할 때 `~/Applications/pizzaClip.app` 존재 자체부터 확인. release.sh 가 한 번도 안 돌았으면 사용자는 옛 myclip 앱 띄우고 있는 거. 가장 흔한 false 진단.

**Ad-hoc 사인 + bundle ID 변경의 합쳐진 페인**
0.1.3 은 cdhash + bundle ID 둘 다 바뀌어서 이전 grant 가 무의미함. 새 빌드 후 1회:
```bash
tccutil reset Accessibility com.jekeun.pizzaClip
# (옛 ID 도 정리하려면)
tccutil reset Accessibility com.jekeun.myclip
defaults delete com.jekeun.pizzaClip didShowAccessibilityPrompt 2>/dev/null || true
# 그 후 앱 실행 → 시스템 프롬프트 → 설정에서 토글 ON
```
영구 해결은 자체서명 인증서 (§7 다음 세션 후보).

**버전 / 배포**
- 0.1.3 bump 완료 (`project.yml` MARKETING 0.1.3, CURRENT 4)
- `./scripts/release.sh` 로 `dist/pizzaClip-0.1.3.{zip,dmg}` 생성, `~/Applications/pizzaClip.app` install 됨
- ad-hoc 사인 — install 후 TCC reset 필요 (위 운영 노트 참고)

**미커밋**
- 변경분 모두 미커밋 (0.1.2 7파일 + 0.1.3 의 대대적 rename + easter egg + 새 자산)
- 다음 세션에서 conventional commit 시리즈로 분할 정리. 제안 split:
  - `chore: rename myclip → pizzaClip across project`
  - `feat(menubar): switch pizza icon to PNG asset set`
  - `feat(popup): add pizza easter egg burst`
  - `chore(app): regenerate AppIcon.icns from new source PNG`
  - `feat(popup): 9 → 1 full paste` (0.1.2 분)
  - `feat(paste): alert when Accessibility missing` (0.1.2 분)
  - `chore: bump 0.1.3`

---

## 다음 세션 시작 시 Claude에게 할 말

아래 메시지를 새 세션 첫 줄에 붙여넣으세요:

```
macOS 메뉴바 클립보드 히스토리 앱 pizzaClip을 작업 중입니다.
프로젝트는 /Users/parkjaekeun/DEV/ProjectJAM/pizzaClip 에 있어요.
먼저 docs/HANDOFF.md 와 git log 를 읽어서 컨텍스트 잡고 시작해 주세요.
이 세션에서 하고 싶은 작업: <여기에 구체적 요청 적기>
```

또는 짧게:
```
/Users/parkjaekeun/DEV/ProjectJAM/pizzaClip 의 docs/HANDOFF.md 읽고 시작.
오늘 할 일: <요청>
```

Claude가 해야 할 첫 동작:
1. `docs/HANDOFF.md` 읽기
2. `git log --oneline | head -20` 으로 최근 변경 확인
3. 요청한 작업 시작
