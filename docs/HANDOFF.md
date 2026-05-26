# Session Handoff — pizzaClip

마지막 업데이트: 2026-05-27

이 문서는 새 Claude 세션에서 작업을 이어갈 때 한 번 읽으면 컨텍스트가 잡히도록 만들어졌습니다.

## 1. 프로젝트 한 줄 요약

macOS 메뉴바 클립보드 히스토리 앱. SwiftUI + AppKit, GRDB SQLite, KeyboardShortcuts. 개인 사용 목적, **자체서명 cert(`projectJAM1s`) 서명**, Universal binary, macOS 13+.

- **위치**: `/Users/parkjaekeun/DEV/myclip` (저장소 디렉토리는 그대로, 앱/번들 이름만 pizzaClip)
- **현재 버전**: 0.1.4
- **브랜치**: `master` (단일 브랜치 운영)
- **빌드 스크립트**: `./scripts/release.sh` (테스트 → Release 빌드 → DMG/ZIP → ~/Applications 설치)

## 2. 첫 진입 시 읽어야 할 것

| 우선순위 | 파일 |
|---|---|
| 1 | 이 파일 (`docs/HANDOFF.md`) — 최신 상태 |
| 2 | `git log --oneline` — 시간순 진행 기록 |
| 3 | `docs/qa/checklist.md` — 현재 동작 명세 (실행 가능한 형태) |
| 4 | `docs/superpowers/specs/2026-05-21-myclip-design.md` — 초기 설계 의도 (역사적, 파일명은 옛 이름 유지) |
| 5 | `docs/superpowers/plans/2026-05-21-myclip.md` — 초기 16-task 구현 플랜 (역사적, 이미 모두 완료) |

## 3. 현재 기능 상태

### 작동 검증된 동작

- 자동 캡처: 텍스트 / 이미지 (스크린샷) / Finder 파일 / **Finder 이미지 파일** (원본 포맷 보존)
- 글로벌 단축키: ⌘⇧V (팝업), ⌘⌥⌃1~9 (직접 붙여넣기)
- 팝업 내부: ↑↓ 키보드 네비게이션, ↵ 또는 숫자 1~9 붙여넣기, **0 = 9→1 full paste (slot 9부터 1까지 순차 붙여넣기)**, ⌫ 삭제, ⌘P 핀, ⎋ 닫기
- 마우스: hover로 highlight (스크롤 안 함), 휠 스크롤, 클릭으로 picking
- 팝업 라이브 갱신: 열려있는 동안 다른 앱에서 ⌘C해도 즉시 반영
- **팝업 포커스 잃으면 자동 close** (다른 창 클릭 시 — 0.1.1)
- 상태바 아이콘: 좌클릭=팝업(슬라이드 다운 애니메이션), 우클릭=메뉴
- **상태바 피자 아이콘 PNG 단계 표시** (0.1.4: 11단계로 확장): 사용자 제공 PNG 11단계를 `pizzaClip/Resources/Assets.xcassets/PizzaIcon0~10.imageset` 으로 번들. 히스토리 0개 → PizzaIcon0, 1~8개 → PizzaIcon1~8, 9개 → PizzaIcon9 (피자박스 한 개), 10개+ → PizzaIcon10 (피자박스 쌓인 이미지). 이전 Core Graphics 직접 드로잉은 제거됨. `template-rendering-intent: original` 로 painted 컬러 유지
- **앱 아이콘 PNG → .icns 자동 빌드** (0.1.3): 사용자 제공 1024px `assets/pizzaClipAppIcon.png` 를 `sips`+`iconutil` 로 10개 사이즈 iconset → `pizzaClip/AppIcon.icns` 생성. Info.plist `CFBundleIconFile=AppIcon` 그대로
- **팝업 타이틀바 아이콘 = 🍕 이모지 + "pizzaClip — Clipboard History"** (0.1.3에서 텍스트 rename)
- **9 → 1 full paste 버튼** (0.1.2): 검색 박스 자리. 클릭 또는 바 0 키 → top-9 비핀 항목을 slot 9(오래된 것)부터 slot 1(최신)까지 순차로 이전 앱에 붙여넣기 (각 paste 사이 0.18s stagger)
- **🍕 이스터에그** (0.1.4: exact match): 클립보드 텍스트가 **정확히 `pizza` 한 단어** (대소문자/주변 공백 무시) 일 때만 팝업 자동 오픈 + 🍕 이모지 48개가 팝콘 터지듯 바닥에서 튀어 올랐다가 중력으로 떨어지는 burst 애니메이션 (총 2.4초). 0.1.3 의 substring 매치는 너무 자주 발동해서 제거. 또한 팝업 재오픈 시 stale `pizzaBurstID` 재생되던 버그 fix — `show()` 진입 시 viewModel.pizzaBurstID = nil. SwiftUI `ForEach` + `.position` + `.rotationEffect`, `TimelineView(.animation)` 매 프레임 갱신, `.task(id:)` 로 트리거
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
├── Permissions/Accessibility.swift # 1회 prompt, openSystemSettings
├── DesignSystem/
│   ├── Colors.swift              # 코랄 액센트 #D97757
│   └── Theme.swift               # panelRadius, rowRadius, panelWidth=440, panelHeight=480
├── MenuBar/
│   └── PizzaIcon.swift           # NSImage(named: "PizzaIcon\(n)") 로딩만 (Core Graphics 드로잉 제거)
├── Resources/
│   └── Assets.xcassets/
│       └── PizzaIcon{0..9}.imageset/  # 사용자 제공 PNG @1x/@2x, template-rendering-intent: original
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
└── superpowers/{specs,plans}     # 역사적 문서 (파일명 myclip-* 그대로)
```

## 5. 알림 (Notification.Name) 인벤토리

`SettingsView.swift`와 `HistoryStore.swift`에 분산 정의 (0.1.3에서 `.myclip*` → `.pizzaClip*` rename):

| 이름 | 발송 | 옵저버 |
|---|---|---|
| `.pizzaClipClearAll` | Settings → Clear all 버튼 / 팝업 footer Clear all | AppDelegate → `store.clearAll()` |
| `.pizzaClipExportHistory` | Settings → Export to text 버튼 | AppDelegate → 텍스트 파일 작성 |
| `.pizzaClipOpenSettings` | 팝업 푸터 ⌘, Settings 클릭 | AppDelegate → 합성 ⌘, 발사 |
| `.pizzaClipHistoryChanged` | HistoryStore의 insert/delete/togglePin/clearAll | AppDelegate → status icon refresh + PopupPanelController (panel 보일 때만) → `viewModel.reload()` |

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

## 7. 알려진 미구현 / 후속 거리

스펙에 있었지만 미구현 또는 단순화된 부분:

- Multi-monitor 마우스 추종 (현재 `NSScreen.main` 사용)
- 5MB 텍스트 트런케이션 + truncated 플래그
- Launch-at-Login 토글
- Privacy 탭의 drag-drop `.app` 추가 UI (현재 콤마 구분 텍스트)
- HistoryStore의 dedupe filter 인덱스 최적화

코드 리뷰가 짚었지만 미해결:
- DB 쓰기가 메인 스레드에서 도는 점 (`ValueObservation` 또는 background queue로 옮길 여지)
- `prune` 매 insert 후 호출 (가벼우니 acceptable, 추후 N회마다로 게이트 가능)

다음 세션 후보로 논의됐던 거:

- **Settings → "추가기능" 탭**: 오른쪽 ⌘ 키를 무지연 한/영 토글로 매핑. 기술 검토 완료 (CGEventTap + Carbon TIS API 직접 호출, ~5ms 지연). 필요 권한: 기존 Accessibility + 새로 Input Monitoring. 예상 작업량 1.5~3시간. opt-in 토글로 설계 추천
- **GitHub remote 셋업**: 현재 git remote 비어 있음. `gh repo create jekeun/pizzaClip --private --source=. --push` 한 줄. 셋업 후 feature branch + PR + squash merge 가능
- **이스터에그 파티클 이미지 교체**: 사용자가 PNG 파일 줄 예정. `Text("🍕")` → `Image("...")` 로 1줄 교체. Particle struct 의 emoji 필드를 image name 으로 바꾸면 됨

## 8. 빌드 / 테스트 / 배포

```bash
cd /Users/parkjaekeun/DEV/myclip

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

## 10. 세션 노트 — 2026-05-27 (0.1.4 버그 픽스 + 자체서명)

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

## 11. 이전 세션 노트 — 2026-05-26 (0.1.3 작업 완료, 미커밋이었음)

**변경된 동작 / 자산**
- 앱/번들 전면 rename: `myclip` → `pizzaClip`
  - 디렉토리: `myclip/` → `pizzaClip/`, `myclipTests/` → `pizzaClipTests/`
  - Xcode 프로젝트: `pizzaClip.xcodeproj`
  - Bundle ID: `com.jekeun.pizzaClip`, struct `PizzaClipApp`
  - Notification.Name 4종 `.myclip*` → `.pizzaClip*`
  - 사용자 표시 텍스트 (팝업 타이틀, Settings 타이틀, Quit 메뉴, Accessibility 알림 등), 데이터 경로 (`~/Library/Application Support/pizzaClip/`), 익스포트 파일명 (`pizzaClip-history.txt`), 로그 prefix 모두 갱신
  - project.yml, Info.plist, release.sh, README.md, docs/qa/checklist.md 일괄 정리. `docs/superpowers/specs/2026-05-21-myclip-*.md` 는 역사적 파일이라 파일명 유지
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
프로젝트는 /Users/parkjaekeun/DEV/myclip 에 있어요 (디렉토리 이름은 myclip 그대로).
먼저 docs/HANDOFF.md 와 git log 를 읽어서 컨텍스트 잡고 시작해 주세요.
이 세션에서 하고 싶은 작업: <여기에 구체적 요청 적기>
```

또는 짧게:
```
/Users/parkjaekeun/DEV/myclip 의 docs/HANDOFF.md 읽고 시작.
오늘 할 일: <요청>
```

Claude가 해야 할 첫 동작:
1. `docs/HANDOFF.md` 읽기
2. `git log --oneline | head -20` 으로 최근 변경 확인
3. 요청한 작업 시작
