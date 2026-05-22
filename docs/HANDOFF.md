# Session Handoff — myclip

마지막 업데이트: 2026-05-23

이 문서는 새 Claude 세션에서 작업을 이어갈 때 한 번 읽으면 컨텍스트가 잡히도록 만들어졌습니다.

## 1. 프로젝트 한 줄 요약

macOS 메뉴바 클립보드 히스토리 앱. SwiftUI + AppKit, GRDB SQLite, KeyboardShortcuts. 개인 사용 목적, ad-hoc 서명, Universal binary, macOS 13+.

- **위치**: `/Users/parkjaekeun/DEV/myclip`
- **현재 버전**: 0.1.0
- **브랜치**: `master` (단일 브랜치 운영)
- **빌드 스크립트**: `./scripts/release.sh` (테스트 → Release 빌드 → DMG/ZIP → ~/Applications 설치)

## 2. 첫 진입 시 읽어야 할 것

| 우선순위 | 파일 |
|---|---|
| 1 | 이 파일 (`docs/HANDOFF.md`) — 최신 상태 |
| 2 | `git log --oneline` — 시간순 진행 기록 |
| 3 | `docs/qa/checklist.md` — 현재 동작 명세 (실행 가능한 형태) |
| 4 | `docs/superpowers/specs/2026-05-21-myclip-design.md` — 초기 설계 의도 (역사적) |
| 5 | `docs/superpowers/plans/2026-05-21-myclip.md` — 초기 16-task 구현 플랜 (역사적, 이미 모두 완료) |

## 3. 현재 기능 상태

### 작동 검증된 동작

- 자동 캡처: 텍스트 / 이미지 (스크린샷) / Finder 파일 / **Finder 이미지 파일** (원본 포맷 보존)
- 글로벌 단축키: ⌘⇧V (팝업), ⌘⌥⌃1~9 (직접 붙여넣기)
- 팝업 내부: ↑↓ 키보드 네비게이션, ↵ 또는 숫자 1~9 붙여넣기, ⌫ 삭제, ⌘P 핀, ⎋ 닫기
- 마우스: hover로 highlight (스크롤 안 함), 휠 스크롤, 클릭으로 picking
- 팝업 라이브 갱신: 열려있는 동안 다른 앱에서 ⌘C해도 즉시 반영
- 상태바 아이콘: 좌클릭=팝업(슬라이드 다운 애니메이션), 우클릭=메뉴
- Settings: ⌘, / 상태바 우클릭 / 팝업 푸터 클릭 모두 동일한 SwiftUI Settings 창
- 검색: SQLite FTS5 prefix 매치
- 자동 정리: cap 초과 시 오래된 비핀부터 삭제 (블롭 파일까지 정리)

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
| **앱 아이콘 위치** | 소스 PNG는 `assets/myclip-icon.png` (앱 번들 외부), .icns는 `myclip/AppIcon.icns` (번들 내부) |

## 4. 파일 맵

```
myclip/
├── App/                       # composition root
│   ├── myclipApp.swift        # @main, Settings { SettingsView() } 씬 선언
│   ├── AppDelegate.swift      # 모든 wiring + 상태바 + 알림 옵저버
│   └── AppPaths.swift         # ~/Library/Application Support/myclip 경로
├── Clipboard/
│   ├── Pasteboard.swift       # PasteboardReader 프로토콜
│   ├── CapturedItem.swift     # value type, text/imageData/sourceBundleID
│   └── ClipboardMonitor.swift # Timer 폴링 + 분류기 + 드롭 룰
├── Storage/
│   ├── Item.swift             # GRDB record
│   ├── Schema.swift           # v1 (items) + v2-fts5 마이그레이션
│   ├── HistoryStore.swift     # insert/topN/pin/prune/clearAll/search + 알림 발송
│   └── BlobStore.swift        # 이미지 파일 저장 (원본 포맷 유지)
├── Paste/
│   └── PasteEngine.swift      # pasteboard 쓰기 + ⌘V 합성 (CGEvent)
├── Popup/
│   ├── PopupView.swift        # SwiftUI — 타이틀바/검색/리스트/푸터
│   ├── PopupRow.swift         # 행 (썸네일/제목/슬롯배지)
│   ├── PopupViewModel.swift   # 검색·선택 상태 + 키보드 vs 호버 구분
│   └── PopupPanelController.swift  # FocusablePanel 라이프사이클 + 키 모니터
├── Settings/
│   └── SettingsView.swift     # TabView (General/Shortcuts/Privacy/Storage) + 알림 이름들
├── Shortcuts/Shortcut.swift   # KeyboardShortcuts.Name 확장 (togglePopup, slot 1~9)
├── Permissions/Accessibility.swift  # 1회 prompt, openSystemSettings
├── DesignSystem/
│   ├── Colors.swift           # 코랄 액센트 #D97757
│   └── Theme.swift            # panelRadius, rowRadius 등
├── AppIcon.icns               # 빌드 결과물에 들어가는 아이콘
└── Info.plist                 # LSUIElement=YES, CFBundleIconFile=AppIcon
```

```
assets/myclip-icon.png         # 아이콘 소스 (xcodegen 번들 외부)
scripts/release.sh             # 빌드+패키징+배포 한방
dist/                          # gitignored, release.sh 결과물
docs/
├── HANDOFF.md                 # 이 파일
├── qa/checklist.md            # 수동 QA
└── superpowers/{specs,plans}  # 역사적 문서
```

## 5. 알림 (Notification.Name) 인벤토리

`SettingsView.swift`와 `HistoryStore.swift`에 분산 정의:

| 이름 | 발송 | 옵저버 |
|---|---|---|
| `.myclipClearAll` | Settings → Clear all 버튼 | AppDelegate → `store.clearAll()` |
| `.myclipExportHistory` | Settings → Export to text 버튼 | AppDelegate → 텍스트 파일 작성 |
| `.myclipOpenSettings` | 팝업 푸터 ⌘, Settings 클릭 | AppDelegate → 합성 ⌘, 발사 |
| `.myclipHistoryChanged` | HistoryStore의 insert/delete/togglePin/clearAll | PopupPanelController (panel 보일 때만) → `viewModel.reload()` |

## 6. 데이터 & 권한

- **저장**: `~/Library/Application Support/myclip/` (Settings에서 변경 가능)
  - `db.sqlite` — 텍스트, 메타데이터, 썸네일
  - `blobs/<uuid>.{png,jpg,heic,gif,…}` — 원본 포맷 이미지 파일
- **권한**: Accessibility 하나만 필요 (⌘V 합성용). 거부해도 클립보드까지는 들어감
- **마이그레이션 플래그**:
  - `didShowAccessibilityPrompt` — 권한 다이얼로그 1회 제한
  - `didMigrateCapTo9` — cap=10에서 9로 1회 마이그레이션

## 7. 알려진 미구현 / 후속 거리

스펙에 있었지만 미구현 또는 단순화된 부분:

- Multi-monitor 마우스 추종 (현재 `NSScreen.main` 사용)
- 5MB 텍스트 트런케이션 + truncated 플래그
- Launch-at-Login 토글
- Privacy 탭의 drag-drop `.app` 추가 UI (현재 콤마 구분 텍스트)
- 다크/라이트 별도 아이콘 변형
- HistoryStore의 dedupe filter 인덱스 최적화

코드 리뷰가 짚었지만 미해결:
- DB 쓰기가 메인 스레드에서 도는 점 (`ValueObservation` 또는 background queue로 옮길 여지)
- `prune` 매 insert 후 호출 (가벼우니 acceptable, 추후 N회마다로 게이트 가능)

## 8. 빌드 / 테스트 / 배포

```bash
cd /Users/parkjaekeun/DEV/myclip

# 프로젝트 생성 (.xcodeproj는 gitignored)
xcodegen generate

# 테스트
xcodebuild -project myclip.xcodeproj -scheme myclip -destination 'platform=macOS' test

# 개발용 실행 (Xcode가 가장 편함)
open myclip.xcodeproj   # 그리고 ⌘R

# 배포 빌드 + 패키징 + ~/Applications 설치
./scripts/release.sh
```

배포 빌드는 항상 ad-hoc 서명 — 외부 배포 전엔 Developer ID로 재서명 + notarization 필요.

## 9. 작업 컨벤션

- **커밋 메시지**: conventional commits 스타일 (feat/fix/perf/refactor/chore/docs)
- **본문**: 무엇/왜를 두세 문단으로 (저자: Claude Opus 4.7 자동 co-author 안 함, 이 프로젝트는 단독 개발자)
- **테스트**: 모든 수정 후 `xcodebuild ... test`로 17개 통과 확인. 새 기능엔 TDD 권장 (Storage·Monitor는 그렇게 함)
- **xcodegen**: project.yml만 손대고 `xcodegen generate`로 .xcodeproj 재생성. .xcodeproj는 절대 직접 편집 금지
- **xcodegen이 새 파일 자동 인식**: `myclip/` 트리에 파일 추가만 하면 자동으로 픽업

---

## 다음 세션 시작 시 Claude에게 할 말

아래 메시지를 새 세션 첫 줄에 붙여넣으세요:

```
macOS 메뉴바 클립보드 히스토리 앱 myclip을 작업 중입니다.
프로젝트는 /Users/parkjaekeun/DEV/myclip 에 있어요.
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
