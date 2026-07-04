# PICkle — HANDOFF (단일 진실 문서)

> **마지막 업데이트**: 2026-07-05 · **🎉 1.3.2 릴리스 완료(build 17, 배포됨 — 팝업 하단 저장폴더 경로 표시 + 자동업데이트 무인설치; 상세는 아래 [1.3.2] 섹션)** · 직전 1.3.1(build 16, 편집기 열림 idle CPU 6~9% 긴급패치) · 그 직전 1.3.0(build 15)에서 **캡처를 macOS 기본 `screencapture -i`로 전환 → 열린 메뉴/팝업도 그대로 캡처**. 자체 오버레이·직접그린 십자선·모드바를 전부 버리고 OS 캡처 호출로 단순화 + 관련 dead 코드(RegionSelectController·CaptureModeBar·CaptureFlyAnimation·SCK 경로) 삭제. pic.kle·pizzaClip 양쪽 커밋·공증 DMG·사이트/Sparkle 배포 완료.
> **새 세션은 이 문서를 먼저 읽으면 컨텍스트가 잡힙니다.**
> **▶ 1.3.0 핵심: 열린 메뉴/팝업(예: 사운드 컨트롤센터)을 펼친 채 캡처하려 하면 단축키 누른 순간 그 메뉴가 닫히던 문제. 근본 원인 = 일반 앱은 캡처용 오버레이 창을 띄우는 순간 macOS가 열린 메뉴를 닫음(오버레이가 key window를 가져가 히스토리 패널이 resignKey로 닫히고, shield 레벨 최상위 창으로 떠 다른 앱 메뉴 트래킹도 취소됨). ⌘⇧4가 멀쩡한 건 WindowServer(OS)가 직접 처리 = OS만의 특권. → 자체 오버레이(⇧⌘5식)를 전부 버리고 macOS 기본 `screencapture -i` 호출로 전환. `-i`는 사용자 동의형이라 권한 상속 문제 없음(과거 `-R` 실패와 대비). 픽셀 치수·스페이스 이동은 OS UI 기본 제공, 모드(S/D/A)는 단축키로 확정. 상세는 아래 [✅ 2026-07-03 — 1.3.0] 섹션.**
> **테스트 규칙: 빌드마다 `project.yml` MARKETING_VERSION+build 올리고 사용자에게 번호 알림(Settings 일반탭 `v1.x.x (build N)` 표시). 정식 배포=둘째자리(minor) ↑, 테스트 빌드=셋째자리(patch) ↑.**
> **알려진 후속(보류): ①편집 입력칸이 캔버스 `scaleEffect` 안에 있어 한글 IME 후보창 위치가 어긋남(입력칸만 scaleEffect 밖으로 분리 권고) ②캡처 십자 "+" 크기/색 미세조정 여지(`RegionSelectController.drawCrosshair`, 현재 팔 11px·중앙 gap 3px·초록) ③PizzaClip 연동 실기검증(설치/미설치 실동작)이 가벼웠음 — 다음에 한 번 확인 권장.**
> **❌ 종결(재시도 말 것): 키노트/슬라이드쇼처럼 시스템이 커서를 숨기는 곳에서 "화살표 보충"은 공개 API로 불가 확정 → 십자만 유지(2026-06-26 사용자 결정). 이유: `CGCursorIsVisible()`=unavailable, `NSCursor.currentSystem`=키노트 커서숨김 감지 못함, "항상 그리기"=일반화면 중복커서. 1.2.1/1.2.2 시도 폐기·git restore로 1.2.0 복귀. 상세는 메모리 `pickle-next-version-todo`.**
> 느낌/DNA 가이드는 형 앱에서 물려받은 [`../pickle-느낌브리프.md`](../pickle-느낌브리프.md) 참고.
>
> ⚠️ **개인정보 주의**: 서명에 쓰는 팀 ID·Developer ID 식별자는 **gitignore된 `Signing.xcconfig`** 에만 둡니다 (커밋 금지). 배포 자격증명은 `scripts/release.local.sh`(gitignore)에. 각각 `*.example` 템플릿을 복사해 채우세요.
>
> 📛 **이름 표기 규칙(중요)**: 사용자에게 보이는 **브랜드 = `PICkle`**(점·소문자 없이 통일). 단, **번들 ID는 `com.Team-jAm.PICkle`**(건드리면 TCC 권한 깨짐), **Xcode 프로젝트/스킴/소스폴더 이름은 `PicKle`(대문자 K)** 로 그대로 둡니다(내부 식별자라 화면에 안 보임).

---

## ✅ 2026-07-05 — 1.3.2 릴리스 (저장 폴더 경로 표시 + 자동업데이트 무인설치)

> **1.3.2 배포**(build 17). 보관함 팝업 하단 UI 개선 + 자동업데이트 근본 원인 수정. pic.kle·pizzaClip 양쪽 커밋·공증 DMG·Sparkle/사이트 배포 완료.

### 🎯 변경 1 — 팝업 하단 '모두 비우기' → 저장 폴더 경로 표시
- 요청: 팝업 하단 '모두 비우기' 제거, 대신 pizzaClip처럼 저장 폴더(`PICkle bottle`) 경로 표시 + 누르면 Finder에서 열기.
- 구현(`History/HistoryView.swift` footer): `internaldrive` 아이콘 + `~/…` 축약 경로(`AppPaths.bottleDirectory` → `abbreviatingWithTildeInPath`) + `Button(revealBottleFolder)` → `NSWorkspace.shared.open`. 툴팁은 기존 `menu.openBottleFolder` 재사용. (pizzaClip `Popup/PopupView.swift`의 `abbreviatedStoragePath`/`revealStorage` 패턴 이식.)
- dead 배선 정리: '모두 비우기'가 유일 사용처였던 `Notifications.swift` `.pickleClearAll` + `AppDelegate` `confirmAndClearAll()`·옵저버 제거. **단 `ScreenshotStore.deleteAll()`(재사용 가능 저수준 API)·`alert.clearAll.*` 문자열은 보존**(되살리기 쉽게).

### 🎯 변경 2 — 자동업데이트 "안 된다" 근본 원인 수정
- 증상: 유저 피드백 "자동업데이트가 안 된다 / '업데이트 확인'을 눌러야 하나?".
- 근본 원인: Sparkle은 기본적으로 **확인만 자동**(`SUEnableAutomaticChecks`)이고 다운로드·설치는 사용자 트리거 대기 → 새 버전을 찾아도 알림만 뜨고(메뉴바 앱이라 놓치기 쉬움) 끝.
- 해법(`AppDelegate.applicationDidFinishLaunching`): `updaterController.updater.automaticallyChecksForUpdates = true` + `automaticallyDownloadsUpdates = true` → 백그라운드 무인 다운로드·설치(재실행 시 적용). Info.plist `SUAutomaticallyUpdate`만으론 부족했던 것을 코드로 강제.
- ⚠️ **한계(중요)**: 이미 배포된 1.3.1 이하 앱의 updater 동작은 원격으로 못 고침 → 기존 사용자는 1.3.2로 **한 번은**(알림 클릭/수동 다운로드) 올라와야 이후부터 무인. 자동 확인 주기는 앱 실행 중 하루 1회(`SUScheduledCheckInterval=86400`).
- 진단(모두 정상 검증): SUFeedURL(`pizza-clip.com/pickle/appcast.xml`)·SUPublicEDKey·전 버전(1.0.0~1.3.1) EdDSA 서명·Keychain 공개키 일치·URL 200·sparkle:version 단조증가(6→7→14→15→16→17).

### 📤 배포
- pic.kle: 1.3.1/16 → **1.3.2/17**(`project.yml`), `dist/notes-1.3.2.md`, 공증 DMG(`~/Downloads/PICkle-1.3.2.dmg` — notary Accepted·staple·Gatekeeper=Notarized Developer ID, `release-test-dmg.sh`), `DOWNLOAD_BASE_URL=pizza-clip.com/pickle ./scripts/sparkle-appcast.sh` → `dist/appcast.xml`(EdDSA, `--verify` 통과·length 3668299 일치).
- pizzaClip(웹): DMG+appcast를 `web/public/pickle/`에 복사, `/info` 릴리스노트(`i18n/info.ts` `pickleReleases` 한/영) 1.3.2 추가 + 더보기 아래 '한 뼘' 문구(`relMoreBold` 타입·문자열·`InfoPage.astro` 사용처) 제거. → 커밋 **`3cb44e0`**.
- **다운로드 링크(체크리스트 a) 별도 수정**: `consts.ts` `PICKLE_DOWNLOAD_URL` + `PicklePage.astro` `softwareVersion` → 1.3.2. → 커밋 **`7399091`**. (처음에 놓쳤다가 랩업 중 + 유저 지적으로 발견.)
- push(master)=Vercel 배포. 라이브 검증: appcast=1.3.2 · `PICkle-1.3.2.dmg` HTTP 200 · /pickle 다운로드 버튼=1.3.2.
- 로컬: `/Applications/PICkle.app`=1.3.2 서명본 설치·실행 중(사용자 테스트용, **공증 생략본**). 웹 배포 DMG는 공증 완료본.

### ⚠️ 다음 릴리스 체크리스트 (여전히 유효 — 이번에도 (a) 놓칠 뻔)
- (a) 사이트 다운로드 = `web/src/consts.ts` `PICKLE_DOWNLOAD_URL` + `web/src/components/pages/PicklePage.astro` `softwareVersion`.
- (b) 사이트 릴리즈노트 = `web/src/i18n/info.ts` `pickleReleases`(한/영). appcast.xml(자동업데이트)과 별개 — 둘 다 갱신.

---

## ✅ 2026-07-03 — 1.3.1 릴리스 (편집기 열림 상태 CPU 상시 점유 — 긴급패치)

> **1.3.1 배포**(build 16). 편집 창을 열어둔 동안(아무 작업 안 해도) CPU가 6~9% 계속 점유되던 문제 수정. pic.kle·pizzaClip 양쪽 커밋·공증 DMG·Sparkle/사이트 배포 완료.

### 🎯 문제 — 편집기 열어두면 idle에도 CPU 6~9%
- 증상: 활성 상태 보기에서 PICkle이 편집 창 떠 있는 동안 CPU **6~9% + WindowServer 동반 상승**. 완전 idle(창 전부 닫힘)은 0%라 "창이 떠 있을 때만" 나던 문제.
- 근본 원인: **`Editor/PickleBurst.swift`의 `TimelineView(.animation)`이 버스트(🥒 이스터에그) 재생 여부와 무관하게 편집 캔버스에 항상 mount됨**(`EditorView.swift:257`, 조건 없이). `.animation` 스케줄은 화면에 올라와 있는 한 디스플레이 주사율(60~120fps)마다 재렌더 → 파티클 0개여도 매 프레임 `Color.clear`를 다시 그리며 CPU·WindowServer를 계속 태움. 창 닫으면 view가 해제되어 idle 0%였던 것.

### ✅ 해법 — 버스트 재생 중에만 TimelineView를 살림
- `PickleBurst`에 `@State isBursting` 게이트: 버스트 중에만 `TimelineView(.animation)` mount, 평상시엔 정적 `Color.clear`(프레임 갱신 예약 안 함).
- `.task(id: trigger)`가 버스트 시작 시 `isBursting=true` → `Task.sleep(duration+maxDelay ≈ 2.7초)` 후 `isBursting=false`+particles 비움 → 스스로 애니메이션 내려 idle CPU 0 복귀. 취소(창 닫힘/새 버스트로 교체) 시 `catch { return }`로 상태 안 건드림(레이스 방지).
- `maxDelay`를 static 상수로 빼서 `makeParticles()` delay 범위와 teardown 타이머가 어긋나지 않게 통일.
- 검증: 편집창 열어도 CPU **0%대**, 🥒 버스트는 그대로 재생 후 0 복귀(사용자 실기 확인 ✓). 이스터에그 동작·모양 변화 없음.

### 📤 배포
- pic.kle: 1.3.0/15 → **1.3.1/16**, `dist/notes-1.3.1.md`, 공증 DMG(`~/Downloads/PICkle-1.3.1.dmg` — Accepted·staple·Gatekeeper=Notarized Developer ID), `sparkle-appcast.sh`(DOWNLOAD_BASE_URL=pizza-clip.com/pickle) → `dist/appcast.xml`(EdDSA). 커밋 `64d84b9`.
- pizzaClip: DMG+appcast를 `web/public/pickle/`에 복사, 다운로드 링크(`consts.ts` `PICKLE_DOWNLOAD_URL`·`PicklePage.astro` `softwareVersion`) + /info 릴리스노트(`info.ts` `pickleReleases` 한/영) 1.3.1 갱신. 커밋 `0366c4d` → push(master)=Vercel 배포.
- ⚠️ 다음 릴리스도 사이트 2곳(consts+PicklePage 다운로드, info.ts 릴리스노트) 잊지 말 것.

---

## ✅ 2026-07-03 — 1.3.0 릴리스 (열린 메뉴/팝업 캡처 — macOS 기본 `screencapture -i`로 전환)

> **1.3.0 배포**(build 15). 열린 메뉴/팝업을 펼친 상태 그대로 캡처 가능하게 함 + 자체 캡처 스택 대거 삭제. pic.kle·pizzaClip 양쪽 커밋·공증 DMG·Sparkle/사이트 배포 완료.

### 🎯 문제 — 단축키 누르면 열린 메뉴가 닫힘
- 증상: 사운드 컨트롤센터 같은 상단 메뉴/팝업을 편 상태에서 캡처 단축키를 누르면 그 메뉴가 즉시 닫혀 못 찍음(다른 앱 메뉴도 닫힘).
- 근본 원인: **일반 앱은 캡처하려고 창(오버레이)을 띄우는 순간 macOS가 열린 메뉴를 닫는다.** ①자체 오버레이가 `makeKeyAndOrderFront`로 key window를 가져가면 히스토리 패널이 `didResignKey`로 자동 닫히고 ②오버레이가 shield 레벨 최상위 창으로 뜨면서 시스템이 다른 앱의 메뉴 트래킹을 취소. ⌘⇧4가 멀쩡한 건 WindowServer(OS)가 직접 처리 = active/key 개념 없음 = OS만의 특권. (미니 모드바 CaptureModeBar는 NonKeyPanel이라 무죄였음 — 범인은 전체화면 오버레이 창.)

### ✅ 해법 (사용자 선택 = 길 A: 진짜 OS 캡처 호출)
- `AppDelegate.presentCaptureMenu`가 자체 오버레이(`beginRegionSelect`) 대신 **macOS 기본 `screencapture -i`**를 호출. WindowServer 처리 → ⌘⇧4처럼 열린 메뉴 안 닫힘. (`CaptureService.interactiveCaptureToFile`/`interactiveCaptureToClipboard` → `Process("/usr/sbin/screencapture", ["-i", …])`, `terminationHandler`로 완료·취소 판정 = 파일 존재 여부.)
- **`-i`는 사용자 동의형**이라 spawn된 자식 프로세스가 화면기록 TCC 권한을 상속 못 해도 OS가 허용(과거 `-R` 고정영역이 실패했던 것과 대비 — 0.5.0 교훈). 실기 검증 ✓ (열린 메뉴 캡처됨, 권한 정상).
- 잃은 것: 커스텀 초록 십자선·모드 중간전환(모드바)·빨려들기 애니메이션. 유지/얻음: 드래그 픽셀 치수·스페이스 영역 이동은 OS 캡처 UI가 기본 제공. 모드(S/D/A)는 단축키로 이미 확정.

### 🧹 대거 정리 (자체 캡처 스택 dead → 삭제)
- 삭제 파일: `Capture/RegionSelectController.swift`(오버레이 창·뷰·컨트롤러·직접그린 십자선·60fps 폴링), `Capture/CaptureModeBar.swift`(모드바 — `CaptureMode` enum만 `CaptureService.swift`로 이전), `Capture/CaptureFlyAnimation.swift`(빨려들기).
- `CaptureService`: SCK/freeze 경로 전부 제거(`warmUp`·`freezeScreens`·`saveImageToFile`·`copyImageToClipboard`·`captureRegionTo*`·`captureSCK`·`captureLegacy`). 이제 `screencapture -i` 래퍼 + `uniqueURL`만. `import ScreenCaptureKit` 제거.
- `AppDelegate`: `regionSelect`·`beginRegionSelect`·`runRegionCapture`·`flourishAfterSave`·`warmUp()` 호출 제거. 재빌드 검증 ✓ (BUILD SUCCEEDED).
- ⚠️ `Resources/{en,ko}.lproj`의 `capture.mode.*` 키는 이제 고아(무해). 다음에 정리 여지.

### 📤 배포 (사이트 반영 보강 포함)
- pic.kle: 1.2.0/14 → **1.3.0/15**, `dist/notes-1.3.0.md`, 공증 DMG(`~/Downloads/PICkle-1.3.0.dmg`), `sparkle-appcast.sh`(DOWNLOAD_BASE_URL=pizza-clip.com/pickle) → `dist/appcast.xml`.
- pizzaClip: DMG+appcast를 `web/public/pickle/`에 복사. **그동안 놓쳤던 사이트 반영도 이번에 바로잡음** — ①다운로드 링크가 1.0.0에 멈춰 있던 것 → 1.3.0(`consts.ts` `PICKLE_DOWNLOAD_URL`·`PicklePage.astro` `softwareVersion`) ②`/info` 릴리즈노트(`i18n/info.ts` `pickleReleases`)에 빠져있던 1.2.0 + 새 1.3.0 추가(한/영), "더보기" 문구 1.1→1.3.
- ⚠️ **다음 릴리스 체크리스트 2가지(잊지 말 것)**: (a) 사이트 다운로드 버전 갱신 = `consts.ts` `PICKLE_DOWNLOAD_URL` + `PicklePage.astro` `softwareVersion` — 1.1/1.2 때 놓쳐서 1.0.0 DMG가 계속 받아지고 있었음. (b) 사이트 릴리즈노트 = pizzaClip `web/src/i18n/info.ts`의 `pickleReleases` 배열(사람이 보는 /info 페이지, 한/영). appcast.xml(자동 업데이트용)과는 별개 — 둘 다 갱신.

---

## ✅ 2026-06-25 — 1.2.0 릴리스 (캡처 십자선 직접 그리기 · PizzaClip 연동 · 캡처 누수 수정)

> **1.2.0 배포**(build 14). 1.1.0(커밋 `debaa1f`) 이후 미커밋이던 1.1.x 작업 전부 + 십자선 최종 해결을 1.2.0으로 한 번에 커밋·공증 DMG·Sparkle 호스팅 배포. 정식 배포라 버전 둘째자리 ↑(1.1.0→1.2.0).

### 🎯 캡처 십자선 커서 "랜덤" — 최종 해결
- **증상 재정의**: "랜덤"이 아니라 **첫 캡처는 화살표, 저장(⇧⌥S) 한 번 한 뒤부터 십자선**. ⇧⌥A(클립보드)로만 캡처하면 계속 화살표 — 이게 진단의 결정적 단서.
- **근본 원인 확정**: macOS에서 **마우스 커서 모양은 "활성(frontmost) 앱"만 바꿀 수 있다**. PICkle은 텔레그램 등의 풀스크린 뷰어가 닫히지 않게 일부러 활성화(`NSApp.activate`)를 안 함 → 앱이 inactive라 `NSCursor.crosshair.set()`이 무시됨. **저장하면 직후 히스토리 패널이 `NSApp.activate` 호출(`HistoryPanelController.swift:74`)로 앱을 깨워서** 그 다음 캡처부터 커서가 바뀜. ⇧⌥A는 창을 안 열어 앱을 못 깨우니 계속 화살표.
- **왜 ⌘⇧4는 멀쩡한가**: 그건 일반 앱이 아니라 **OS(WindowServer)가 직접** 처리 → active 개념 자체가 없고 다른 앱도 안 닫음. 일반 앱이 공개 API로 {라이브+십자선+텔레그램 유지}를 동시에 못 갖는 근본 이유.
- **해법(사용자 선택 = A안: 화살표와 겹친 십자)**: `NSCursor.crosshair` 의존을 전부 제거하고, 오버레이 뷰에 **작은 "+" 십자(초록, ⌘⇧4식)를 직접 draw**. 마우스 위치는 mouseMoved(inactive에서 불안정) 대신 **60fps 타이머로 `NSEvent.mouseLocation` 폴링** → 각 오버레이에 push(`updateCrosshair(global:)`, 화면 frame 안일 때만). active 여부·첫 캡처 무관하게 **항상 일관**. 시스템 화살표는 못 숨기므로 화살표+십자가 겹쳐 보이지만 "랜덤"은 0. 모드바 위에선 off-screen 좌표 push로 십자 숨김. (`Capture/RegionSelectController.swift`)
- **폐기한 것**: `resetCursorRects`/`cursorUpdate`/`mouseMoved`의 `NSCursor.set`, `startCursorAssert`/`assertCursor`(→`startCrosshairTracking`/`pushCrosshair`), teardown의 `NSCursor.arrow.set()`, 트래킹영역 커서 옵션.

### ✅ 함께 릴리스한 1.1.x 작업 (전부 1.2.0에 포함)
- **캡처 단축키 누수 수정**: 텔레그램 풀스크린 사진 중 캡처 단축키 → 뷰어 닫히던 버그. `begin()`에서 `NSApp.activate` 제거(위 십자선과 같은 "활성화 안 함" 정책). 사용자 검증 ✓.
- **🍕 PizzaClip 연동**: 보관함 🍕 = ①설치 시 바로 클립보드 복사 ②미설치 첫 클릭=`pizza-clip.com/pizzaclip/` 열기, 이후 복사. (`ClipboardService`·`HistoryViewModel.handlePizzaButton`·`pizzaClipPromptShown`)
- **버전 카운팅**: `SettingsView.appVersion`이 `v1.2.0 (build 14)` 표시. **CPU**: idle 0%.

---

## ★ 현재 스냅샷 (0.4.0 + 0.5.0 진행분)

**한 줄**: PICkle — 캡처·편집(펜/블러/워터마크)·보관·자동삭제·설정·아이콘 상태표시·공증DMG + **다국어(한/영)** 까지 동작하는 완성형 메뉴바 앱.

### 지금 동작하는 것 (검증 완료)
- 메뉴바 🥒 병 아이콘 + 그리드 히스토리 패널 (FocusablePanel, 바깥클릭 닫힘, 멀티모니터).
  - **자물쇠(고정) + ✕(닫기) 버튼**: 자물쇠 잠그면 포커스 잃어도 안 닫힘(✕로만 닫기). 마지막 잠금 상태 기억(UserDefaults).
  - **아이콘 상태표시**: 캡처 내역 있으면 피클병, 비면 빈병 (메뉴바 + 폴더 아이콘 둘 다).
- 단축키 3종 (Settings에서 변경 가능) → 누르면 **자체 영역선택 오버레이(⇧⌘5식)** + 모드바가 뜨고, 모드 프리셀렉트됨:
  - `⇧⌥S` 저장(바로 bottle) / `⇧⌥D` 편집(편집창) / `⇧⌥A` 클립보드(**bottle에 저장 안 함**, PizzaClip 켜져 있으면 그쪽으로)
  - 단축키 누르면 **화면 변화 없이**(⌘⇧4식·완전 투명 오버레이) 십자선 → 드래그로 영역 선택 → 그 영역만 캡처(ScreenCaptureKit, 멀티모니터 OK). **드래그 중 스페이스바 = 선택영역 이동**. 커서 옆 **픽셀 치수(W×H)** 표시. ←/→ 모드변경, Esc/✕ 취소.
- 저장 위치: `~/Documents/PICkle bottle` (Settings에서 변경 가능, 변경 시 경고).
- **편집기 3도구** (왼쪽 아이콘 레일 + **선택 시 옆에 떠있는 옵션 팝오버**, 마우스 떠나면 ~2초 후 자동 페이드 / 선택 툴 재클릭=토글):
  - 펜(색7/굵기3) · 블러(가우시안+모자이크 / 브러시+영역, 강도 슬라이더) · 워터마크(텍스트 **AND** 로고 동시, 각각 독립 드래그·크기·투명도)
  - **워터마크 텍스트는 캔버스에서 직접 입력**(NSTextView): Enter=줄바꿈 / 바깥클릭·Esc=확정 / 더블클릭=재편집. **문단정렬(좌/중/우)·자간·줄간격** 조절. 드래그 시 **변(edge) 기준 스냅 가이드**(좌=왼쪽변·우=오른쪽변·상/하=위/아래변·가운데=중심).
  - **크롭(자르기)**: 진입 시 전체 박스 → 4모서리·4변 핸들로 조절(안쪽=이동, 리사이즈 커서), 영역 바뀌면 캔버스 가운데 "자르기" 버튼/**Enter**로 적용. 우측 상단엔 px·용량·확장자 표시(줌% 없음).
  - **⌘Z** 통합 되돌리기(펜/블러/크롭을 한 순서대로). 저장=원본 해상도 합성 후 덮어쓰기.
- **자동삭제**: 기본 30일(끄기/7/14/30/60/90일). 지난 파일은 휴지통으로(복구 가능). 앱 실행 시 + 하루 1회.
- **다국어(한국어/영어 런타임 전환)**: Settings → 일반 탭에서 `시스템 / 한국어 / English` 선택. 앱 재시작 없이 전환(설정창은 즉시, 다른 창은 다음 열 때). 기본=시스템 언어.
- **Settings**(TabView 4탭): **일반**(앱정보+언어) / **단축키**(캡처 S/D/A + 보관함 열기 ⌥⇧F) / **워터마크**(폰트·로고 프리셋·마지막 텍스트 기억) / **저장공간**(자동삭제·저장위치+경고). 아이콘: 일반=gearshape·단축키=keyboard·워터마크=signature·저장공간=internaldrive.
- 히스토리 그리드: 1:1 썸네일, 더블클릭=편집, 단일클릭=선택, 🍕=클립보드 복사, 🗑=휴지통, 드래그아웃, Clear all(확인창).
- **배포**: 서명+공증+staple DMG (`bash scripts/release-test-dmg.sh` → `~/Downloads/PICkle-<버전>.dmg`).

### 핵심 환경/주의 (재현용)
- 번들 ID `com.Team-jAm.PICkle`. 서명/팀ID는 `Signing.xcconfig`(로컬), 공증 프로필은 `scripts/release.local.sh`(로컬).
- **항상 서명된 Release 빌드**로 테스트(ad-hoc 금지) → `/Applications`에 `ditto` 설치. 안 그러면 화면기록 권한 무한 재요청. (§5)
- 빌드: `xcodegen generate && xcodebuild -project PicKle.xcodeproj -scheme PicKle -configuration Release -derivedDataPath build -clonedSourcePackagesDirPath build/SourcePackages build` (결과물은 `PICkle.app`).
- 새 .swift 파일 추가 시 `xcodegen generate` 다시 돌려야 인식됨. 다국어 `.lproj`(en/ko)도 xcodegen이 변형 그룹으로 자동 인식.
- App Sandbox OFF / Hardened Runtime ON. 의존성: KeyboardShortcuts(정적). GRDB/Sparkle 미사용(folder-as-truth).

### 미완료 / 다음 (0.5.0~)
- [x] **Sparkle 배포(호스팅) — 1.0.0 완료**: GitHub Release 대신 **형 web 레포에 함께** 호스팅 — `pizzaClip/web/public/pickle/`에 DMG+`appcast.xml` 배치 → Vercel. enclosure=`pizza-clip.com/pickle/PICkle-<버전>.dmg`. 다음 버전은 위 [✅ 2026-06-09 — 1.0.0 정식 릴리스]의 재현 순서 그대로.
- [ ] **편집 입력칸 `scaleEffect` 분리 (후속, 보류)** — 워터마크 입력칸(NSTextView)이 캔버스 축소 변환 안에 있어 **한글 IME 후보창 위치가 구조적으로 어긋남**(architect 자문). *편집칸만 scaleEffect 밖으로 빼서 좌표변환 배치* 권고(`textWM.center*s`로 화면좌표, 폰트는 이미 스케일된 크기). (2026-06-08 세션 참고)
- [ ] **편집기 디자인 세부 조정** — 툴바 팝오버(시안 B)·캔버스 직접입력·정렬/자간/줄간격·**크롭(자르기) 완료**. 예시(`guide/편집팝업예시.png`)의 남은 추가 도구(화살표·도형·스티커 등)는 추후.
- 미해결 리스크: folder-as-truth라 bottle 폴더를 공용폴더로 바꾸면 남의 이미지도 그리드/ClearAll 대상 → Settings에 경고 표시는 해둠.
- 자체 오버레이 한계(추후 보강 여지): macOS 기본 ⇧⌘5의 *창(window) 모드·돋보기 루페*는 없음(선택영역 **픽셀 치수 표시는 추가됨**, 드래그 직사각형 선택만 지원). 멀티모니터는 **화면별 오버레이**로 처리(2026-06-07 세션) — 배치가 특이하면 캡처 좌표 검증 권장.

### ✅ 최근 완료 (0.5.0 작업분)
- **🥒 이스터에그 burst**: 편집기 워터마크 텍스트가 *정확히* `pickle`/`피클`일 때 캔버스에 🥒가 솟구침(형 PizzaBurst 이식 → `Editor/PickleBurst.swift`). `EditorModel.pickleBurstID`+`maybeTriggerBurst` / `EditorView`의 `onChange(textWM.text)`로 발동.
- **캡처 동작 선택 + 자체 영역선택 오버레이 (⇧⌘5식)**: 단축키(S/D/A)를 누르면 **즉시** 전체화면 선택 오버레이(십자선)가 뜨고, 메뉴바 아래에 *해당 기능이 선택된* 컴팩트 모드바가 같이 뜸. 바로 드래그하면 그 기능으로 캡처 / 다른 기능은 모드바 클릭으로 변경 / **드래그 시작 순간 모드바 숨김**(캡처영역 안 가리게). ←/→ 모드변경, Esc/✕ 취소. 오버레이는 `sharingType=.none`라 캡처에 안 찍힘. 캡처는 `screencapture -R`(고정영역). (`Capture/RegionSelectController.swift`=오버레이창+뷰+컨트롤러, `Capture/CaptureModeBar.swift`=모드바, `CaptureService.captureRegionToFile/Clipboard`, `AppDelegate.presentCaptureMenu/runRegionCapture`)
- **캡처→메뉴바 빨려들기 애니메이션**: *저장(S)* 캡처 후 캡처 이미지가 **찍힌 그 자리에서** 줄어들며 메뉴바 아이콘으로 빨려들어가고 히스토리 팝업이 열림(`Capture/CaptureFlyAnimation.swift` → `AppDelegate.flourishAfterSave`). 자체 오버레이라 실제 캡처 좌표를 알아서 시작 위치가 정확함.
- **편집기 레이아웃 리디자인(1차)**: 상단 세그먼트 → **왼쪽 세로 아이콘 툴바**(펜·블러·워터마크+⌘Z) + **어두운 캔버스**(이미지 중앙·그림자)로 재구성. 창도 다크 외형+투명 타이틀바(`EditorWindowController`). 도구 옵션/저장·취소는 상단바로. (형태 우선, 세부는 추후)
- **이름 통일 → `PICkle`**: 섞여 있던 `PicKle`(대문자 K)·`PIC.kle`(점)을 화면·코드·파일명·DMG까지 전부 `PICkle`로. (번들 ID·Xcode 프로젝트/스킴/소스폴더 이름은 의도적으로 유지)
- **bottle 폴더명 → `PICkle bottle`**: `AppPaths.bottleFolderName`. 대소문자 차이라 기존 데이터 보존(대소문자 무시 파일시스템).
- **다국어(한/영 런타임 전환)**: `App/LocalizationManager.swift` + `Resources/{en,ko}.lproj/Localizable.strings`(키 93개). 선택 언어의 `.lproj` 번들을 직접 펴서 읽는 방식 → 재시작 없이 전환.
- **폴더아이콘 교체**: `guide/폴더아이콘.png`(피클병)·`guide/폴더아이콘_빈병.png`(빈병)을 1024 정사각으로 패딩해 `FolderIconFull/Empty.imageset` 교체.
- **빈 보관함 일러스트 교체**: `guide/빈폴더 안내.png`(8000²)를 512²로 최적화(1MB→70KB)해 `HistoryEmptyArt.imageset`. `HistoryView` emptyState에서 `Text("🥒")` → `Image("HistoryEmptyArt")`. (그림 속 문구 "THE FOLDER IS EMPTY"는 영어 고정, 아래 안내문은 다국어)
- **Sparkle 자동 업데이트(앱 측)**: 형 pizzaClip 패턴 이식. Sparkle 2.6.0 패키지 + Info.plist SU* 키(`SUFeedURL=https://pizza-clip.com/pickle/appcast.xml`, `SUPublicEDKey`=pizzaClip 키 재사용) + AppDelegate `SPUStandardUpdaterController` + "업데이트 확인…" 메뉴. 릴리스 스크립트에 Sparkle 헬퍼(XPC/Updater.app/Autoupdate) Developer ID 재서명 단계 추가(공증 통과 필수). appcast 생성: `scripts/sparkle-appcast.sh`. **호스팅 배포는 미완**(위 "다음" 참고).

---

## ✅ 2026-06-14 — 1.1.0 (펜 색상 팔레트 · 스포이드 · hex 복사)

> **1.1.0 릴리스**. 버전 `1.1.0`(build 7). 펜 도구 색상 선택을 대폭 강화. 빌드 성공 + `/Applications` 설치 검증 + 공증·staple DMG + Sparkle 호스팅 배포까지 완료. 작업 중 3라운드 멀티에이전트 리뷰로 발견 결함(팝오버 auto-hide·명암·잘림 등) 수정.

### 펜 — 인라인 색상 피커 (시스템 색상창 제거)
- **처음엔** SwiftUI `ColorPicker`(시스템 `NSColorPanel`)를 썼으나 ⓐ 첫 유저가 팔레트인 줄 모름 ⓑ **앱 전역의 별도 떠다니는 창**이라 편집 팝오버를 닫아도 안 닫힘. → **시스템 ColorPicker 제거**하고 팝오버 내부에 사는 자작 피커로 교체.
- **무지개 색상환 버튼(`paletteToggle`)**: 누르면 인라인 피커 토글. 색상환 모양이라 "여기서 색 고른다"가 직관적. 커스텀색 활성 시 가운데에 현재색 점.
- **인라인 피커(`inlineColorPicker`)** = `sbSquare`(채도 x·명도 y 드래그) + `hueBar`(색조 드래그). HSB↔hex는 sRGB 성분공간 자체 계산(`hsbToHex`/`hexToHSB`/`hsbToRGB`/`rgbToHSB` static). `.onChange(of: model.colorHex)`로 외부 변경(프리셋/스포이드) 시 썸네일 재시드(자기 write는 hsbToHex 비교로 스킵).
- **스포이드(`eyedropperButton`)**: `NSColorSampler` 화면 색 추출 돋보기. 루페 떠 있는 동안 팝오버 안 사라지게 `pickingColor` 가드.
- **hex 표시(`hexCopyButton`/`copyHex`)**: `#RRGGBB` 클릭 시 클립보드 복사 + "복사됨!" 피드백.
- 색 변환 헬퍼: `NSColor.hexRGB`(Colors.swift). 로컬라이즈 키 `editor.pen.custom/eyedropper/copyHex.help`·`editor.pen.copied`(ko/en).

### 옵션 팝오버 — 작은 창에서 잘림 방지
- 펜 색 피커를 펼치면 팝오버가 길어져 **작은 캡처(최소 창 크기)** 에선 아래가 창 밖으로 잘렸음. → `optionsPopover`를 `ScrollView`로 감싸고 **창 높이에 맞춰 최대 높이 캡**(`PopoverContentHeightKey`로 내용 높이 측정 → `min(내용, 가용높이)`; 넘치면 스크롤). 펜뿐 아니라 블러·워터마크 팝오버도 함께 보호.

### 배포 (1.0.0 때와 동일 절차)
- `project.yml` 1.0.0/6 → **1.1.0/7** → `xcodegen generate` → Release 빌드 → `scripts/release-test-dmg.sh`(공증·staple `~/Downloads/PICkle-1.1.0.dmg`) → `dist/notes-1.1.0.md` → `DOWNLOAD_BASE_URL=https://pizza-clip.com/pickle bash scripts/sparkle-appcast.sh` → `dist/appcast.xml`+DMG를 `pizzaClip/web/public/pickle/`에 복사 → 양쪽 레포 push(pizzaClip push=Vercel 자동 배포=자동업데이트 공개).

---

## ✅ 2026-06-09 (저녁) — 캡처를 ⌘⇧4식 "화면 무변화" 라이브로 전환 (freeze 제거)

> **사용자 피드백**: freeze(단축키 누른 순간 전 화면 SCK 캡처)가 **화면이 미세하게 줌되는(작아졌다 커지는) 시각 효과**를 유발. 이는 **ScreenCaptureKit 캡처 시 macOS가 주는 시스템 효과**라 앱이 끌 수 없음(검색·실기 확인). macOS 기본 ⇧⌘4처럼 **화면 변화 0**을 원함.
>
> **해결: freeze 제거 → 라이브 캡처.** 단축키 → 라이브 화면 위 **완전 투명 오버레이** + 십자선 → 드래그 선택 → commit 시 그 영역만 SCK 캡처(오버레이 사라진 뒤).
- `AppDelegate.presentCaptureMenu` = `beginRegionSelect(frozen: [:])`만 (freeze 호출 제거).
- `SelectionOverlayView.draw` = dim·freeze 제거, **1% 검정 fill**로 마우스만 수신(★완전 투명 창은 클릭이 아래 앱으로 통과 → 드래그가 "풀림". 1% 알파 fill이 픽셀을 만들어 이벤트 수신, 화면은 사실상 그대로). 선택 테두리(검정 받침+초록)+커서 옆 픽셀 치수만.
- commit 시 image=nil → `runRegionCapture`가 라이브 경로(`captureRegionToFile/Clipboard` = `captureSCK` 영역 캡처)로.
- ⚠️ **트레이드오프(사용자 합의)**: 영상·애니메이션은 "누른 순간"이 아니라 "드래그 끝낸 순간"이 찍힘 — freeze의 원래 목적은 포기.
- ⚠️ **미사용(정리 대상) 코드**: freeze 경로가 전부 dead지만 동작은 무해(항상 라이브). 다음에 정리 권장 — `CaptureService.freezeScreens/saveImageToFile/copyImageToClipboard`, `RegionSelectController`의 freeze 일체(`freezeImage/freezeScale/screenID/croppedImage/applyFreeze`, `begin(frozen:)` 파라미터), `runRegionCapture`의 image 분기.

---

## ✅ 2026-06-09 — 1.0.0 정식 릴리스 + 자동 업데이트 호스팅 완료

> **1.0.0 배포**. 버전 `1.0.0`(build 6), 화면권한 설명(`NSScreenCaptureUsageDescription`) 추가, 고아 문구 2개(`editor.crop.hint/reset`) 정리. **Sparkle 자동 업데이트 호스팅까지 완료** — appcast가 이제 1.0 항목을 서빙(이전까지 빈 템플릿이었음).

### 자동 업데이트 — 호스팅 방식 확정 (별도 레포 없이 pizzaClip 안에서)
- DMG·appcast를 **GitHub Release가 아니라 형 web 레포에 함께** 둠: `pizzaClip/web/public/pickle/`에 `PICkle-1.0.0.dmg` + `appcast.xml` 배치 → Vercel 배포 시 `https://pizza-clip.com/pickle/PICkle-1.0.0.dmg` · `…/appcast.xml`로 서빙.
- enclosure URL = `https://pizza-clip.com/pickle/PICkle-<버전>.dmg` (`DOWNLOAD_BASE_URL=https://pizza-clip.com/pickle`로 `sparkle-appcast.sh` 실행).
- EdDSA 서명 = login keychain의 **pizzaClip 키 재사용**(앱 `SUPublicEDKey`=`KR0Qz…`와 매칭). 릴리스 노트는 `dist/notes-<버전>.md`. ⚠️ `sparkle-appcast.sh`의 `md_to_html`은 **`**볼드**` 인라인 마크다운 미지원** → 노트에 `**` 쓰지 말 것(별표가 그대로 남음).

### 다음 릴리스(1.1+) 재현 순서
1. `project.yml` `MARKETING_VERSION`·`CURRENT_PROJECT_VERSION` ↑ → `xcodegen generate` → Release 빌드
2. `bash scripts/release-test-dmg.sh` → 공증·staple DMG (`~/Downloads/PICkle-<버전>.dmg`)
3. `dist/notes-<버전>.md` 릴리스 노트 작성(별표 금지)
4. `DOWNLOAD_BASE_URL=https://pizza-clip.com/pickle bash scripts/sparkle-appcast.sh ~/Downloads/PICkle-<버전>.dmg`
5. `dist/appcast.xml` + DMG → `pizzaClip/web/public/pickle/`에 복사
6. 양쪽 레포 커밋·푸시 (**pizzaClip push = Vercel 자동 배포 = 자동업데이트 공개**)

---

## ✅ 2026-06-09 세션 — 캡처 freeze · 크롭 핸들 UX · 줌% 제거 · 아이콘/이스터에그 · 보관함 단축키

> 0.5.0 릴리스(커밋 8abb3e0) 이후 사용자 피드백 반영. 전부 빌드 성공 + `/Applications` 설치 검증. 이번 커밋에서 서명·공증 DMG 재생성.

### 캡처 — 단축키 누른 순간 화면 freeze (★캡처 파이프라인 변경)
- **문제**: 기존엔 투명 오버레이로 *라이브* 화면 위에서 선택 → commit 시 SCK **재캡처**(드래그 끝난 순간이 찍힘). 영상·애니메이션이면 "단축키 누른 순간 화면"을 못 잡음.
- **변경**: 단축키 누르면 **즉시 전 화면 스냅샷** → 정지본 위에서 선택 → 그 정지본에서 crop(재캡처 없음).
  - `CaptureService.freezeScreens()` = 화면별 SCK 전체 캡처 → `[CGDirectDisplayID: CGImage]` (+ `saveImageToFile`/`copyImageToClipboard` CGImage 헬퍼).
  - `SelectionOverlayView.freezeImage`/`freezeScale`: 정지본을 배경으로 그리고(dim 위 선택영역만 선명 재그리기), `croppedImage(for:)`로 view 좌표→픽셀 crop.
  - `AppDelegate.presentCaptureMenu`가 `Task{ await freezeScreens() }` 후 `beginRegionSelect(frozen:)`. `RegionSelectController.begin(frozen:)`이 화면별로 분배. `onComplete`가 `(CaptureMode, CGImage?, CGRect)`로 변경. `runRegionCapture`는 image 있으면 freeze 저장/복사, 없으면(macOS13) 기존 라이브 재캡처로 fallback.
  - **macOS 14+ 전용**(SCScreenshotManager). 13은 freeze 없이 기존 동작.

### 편집기 — 크롭을 핸들 조절 방식으로 (드래그 그리기 → 핸들)
- 크롭 도구 진입 시 **전체 이미지 박스**가 뜨고 4모서리(L자)·4변(막대) 핸들로 조절, 안쪽 끌면 이동(`CropHandle` enum, `cropHandle(at:in:)` 히트테스트, `applyCropDrag`). 핸들/선 크기는 `1/canvasScale`로 화면상 일정.
- **마우스 커서**: 모서리=대각선(`NSCursor` 내부 `_windowResize…Cursor` 셀렉터를 `AnyObject`로 안전 호출, 없으면 crosshair fallback), 변=↔/↕, 안쪽=손(`updateCropCursor`).
- **엔터 적용 + 팝오버 제거 + 캔버스 가운데 버튼**: 크롭은 팝오버 안 띄움(`optionsPopover`를 `tool != .crop`일 때만). 영역이 전체에서 바뀌면(`cropIsModified`) 캔버스 정중앙에 "자르기" 버튼(`cropApplyOverlay`, `.keyboardShortcut(.return)`). ⌘Z·즉시적용(flatten→crop)·스냅샷 복원은 그대로.

### 편집기 — 줌(%) 표시 **제거**
- 직전 세션의 "배율% Retina 보정"을 사용자 요청으로 **삭제**(원하는 값이 아니었음). `imageInfoBadge`는 `px · 용량 · 확장자`만. `@Environment(\.displayScale)` 제거. **`canvasScale`(CanvasScaleKey)는 크롭 핸들 크기 보정용으로 유지**.

### 편집창 — 초기 포커스 해제
- 편집창 열 때 버튼이 키보드 포커스를 잡아 **Enter로 창이 닫히던** 문제 → `EditorWindowController`에서 `makeFirstResponder(nil)`(async) + 저장 버튼의 `.keyboardShortcut(.defaultAction)` 제거. 이제 Enter는 크롭 적용 전용.

### 캡처 — 선택영역 픽셀 치수 표시
- 드래그 중 커서 옆에 `W × H`(Retina 배율 반영 실제 픽셀) 배지(`SelectionOverlayView.drawDimensionBadge`). macOS 캡처 HUD식.

### 보관함 단축키 ⌥⇧F
- 캡처 없이 보관함 패널만 여는 단축키(`Shortcuts.openHistory` 기본 `⌥⇧F` → `AppDelegate.openPanel()` 토글). 설정 단축키 탭에 Recorder 추가(`settings.shortcuts.openHistory`).

### 아이콘 · 이스터에그
- **앱 아이콘 → `guide/pk.png`**(AppIcon 전 사이즈 sips 재생성). **설정 일반탭 가운데 이미지 → 새 `AppMainIcon.imageset`**(`guide/피클 메인아이콘.png`, 72pt). 메뉴바 아이콘은 유지.
- **이스터에그 🥒 이모지 → `폭탄피클` 이미지**(`PickleBomb.imageset`, `guide/폭탄 피클@0.5x.png` 64/128px). 크기 이모지의 2배(32~60pt), 일부(약 8마리)는 더 높이 솟구침(`vySpeed` 640~780).
- ⚠️ 앱 아이콘 교체는 macOS 아이콘 캐시 때문에 Dock/Finder에 바로 안 보일 수 있음 → `lsregister -f` + `touch` + `killall Dock`, 그래도 안 되면 로그아웃/로그인.

---

## ✅ 2026-06-08 세션 (후속) — 크롭 도구 · 줌% 보정 · 설정탭 재구성 · 0.5.0 릴리스

> 빌드 성공(`BUILD SUCCEEDED`) + 서명·공증·staple DMG 생성 완료. 편집기 신규 동작(크롭/줌%)은 **사용자 측 DMG 설치 후 실기검증 권장**.

### 편집기 — 크롭(자르기) 도구 추가 (즉시 적용형)
- 좌측 레일에 ✂️ `crop` 도구(`railTool(.crop, system:"crop")`). `EditorModel.Tool`에 `case crop` 추가(allCases 순서=레일 순서=pen/blur/watermark/crop, popover 위치 인덱스 일치).
- 드래그로 남길 영역 선택(`cropRect` @State, display-space) → 캔버스에 **바깥 dim(even-odd fill)·3분할 그리드·밝은 점선 테두리**(`drawCropOverlay`), 드래그 전엔 hover 십자선.
- 팝오버 `cropControls`의 **"자르기"** 버튼 → `model.applyCrop(rectInDisplay)`: **현재 편집(펜/블러/워터마크)을 픽셀 해상도로 flatten(`renderBitmap`→`rep.cgImage`) → `cropping(to: pxRect)` → 새 `baseImage`/`imagePixelSize`/`displaySize`로 교체 → 라이브 레이어 초기화.** 즉 크롭하면 기존 편집은 이미지에 구워짐.
- **⌘Z 되돌리기 통합**: `EditAction`에 `case crop` 추가. 크롭 직전 전체 상태(`CropSnapshot`: image+pxSize+dispSize+strokes+blur+textWM+logoWM+undoStack)를 `cropSnapshots` 스택에 저장, `undoLast`의 `.crop`에서 `restoreCrop()`으로 복원.
- ⚠️ 이를 위해 `baseImage`/`imagePixelSize`/`displaySize`를 `let`→`@Published private(set) var`로 바꿈(크롭 시 캔버스가 새 크기로 자동 리드로우). `fittedDisplaySize(for:)` static 헬퍼로 init/crop 공통화.

### 편집기 — 배율(%) 표시 Retina 보정 (버그 수정)
- `imageInfoBadge`의 줌% 계산에 **`@Environment(\.displayScale)`(레티나 ×2)를 곱하는 것이 빠져 있어 항상 실제의 ~절반**(예 풀스크린 28%)으로 나오던 것 수정. 이제 `displaySize·canvasScale·displayScale / px ×100` = **"100% = 원본 1픽셀 : 화면 1픽셀"**(Preview.app 의미).

### 설정 — 탭 재구성 (첨부 참고 이미지 기준)
- 순서/이름/아이콘: `정보(info.circle)`→**`일반(gearshape)` 맨 앞**, `단축키`는 `command`→**`keyboard`**, `워터마크(signature)` 유지, `보관(tray.full)`→**`저장공간(internaldrive)`**. 로컬라이즈 키 `settings.tab.about`→`settings.tab.general`("일반"/"General"), `settings.tab.storage` 값 "보관"→"저장공간"(en "Storage" 유지).
- About(=일반)탭 버전 표기 `Text("v0.4.0")` 하드코딩 → **`Bundle.main` CFBundleShortVersionString 동적 읽기**(앞으로 릴리스마다 손댈 필요 없음).

### 0.5.0 버전 확정
- `project.yml`: `MARKETING_VERSION 0.4.0→0.5.0`, `CURRENT_PROJECT_VERSION 4→5`. `xcodegen generate` 재실행. DMG=`~/Downloads/PICkle-0.5.0.dmg`(공증 Accepted·staple·Gatekeeper accepted).

---

## ✅ 2026-06-08 세션 완료 (편집기 UX 대수술 + 캡처 스페이스 이동)

> 아래 전부 **완료·실기검증·커밋**. 편집기 워터마크 입력칸은 여러 번 갈아엎은 끝에 **NSScrollView로 감싼 NSTextView**(세로 자동크기)로 안착 — 시행착오 교훈은 본문에.

### 캡처 — 스페이스바 영역 이동
- 드래그 중 **스페이스바 누른 채 이동 = 선택영역 통째 이동**(macOS ⇧⌘5식). `SelectionOverlayView`에 `isMoving`/`lastDragPoint`, `mouseDragged`에서 space 중엔 델타로 사각형+앵커 함께 이동(화면 밖 클램프, 엣지 드리프트 방지=앵커를 *적용된* 델타로 갱신). space 키는 `RegionSelectController.installKeyMonitor`의 로컬 모니터(`[.keyDown,.keyUp]`, keyCode 49)에서 잡아 **모든 오버레이에 `setMoving` 브로드캐스트**(드래그 오버레이가 key window가 아닐 수 있어서). 새 드래그마다 `isMoving=false` 초기화.

### 편집기 — 툴바 재설계 (시안 B: 떠있는 팝오버)
- 도구 옵션을 상단 바에서 빼서 **레일 아이콘 옆 떠있는 팝오버**(`optionsPopover`, 위치=`topBarHeight+1+railTopInset+toolIndex*toolSlot`). **마우스 떠나면 ~2초 후 페이드아웃**(`scheduleHidePopover`/`DispatchWorkItem`), 호버 유지(`keepPopover`), **선택 툴 재클릭=즉시 숨김 토글**(`selectTool`). 상단 바는 정보+취소/저장만(`topBarHeight=54`).
- 옵션 3종 세로 배치(`penControls`/`blurControls`/`watermarkControls` + `sliderRow` 헬퍼). 펜 색상은 `colorSwatch`/`widthDot`로 추출(LazyVGrid 타입체커 부담 완화).
- **워터마크 레일 아이콘 = 작은 "water mark" 텍스트**(`railWatermarkTool`). SF심볼 `textformat`이 한국어 macOS에서 "가가"로 보여서. **설정창 워터마크 탭 아이콘**도 `textformat`→`signature`.

### 편집기 — 캔버스에서 워터마크 직접 입력 (가장 고생한 부분)
- `CanvasTextEditor`(`NSViewRepresentable`) = **`NSScrollView`로 감싼 `NSTextView`**. `isVerticallyResizable=true`(세로 성장은 AppKit), `isHorizontallyResizable=false`+`widthTracksTextView=true`(폭은 SwiftUI가 hug 폭으로 고정 → 긴 줄 wrap 안 함, trailing newline 빈 줄 폭폭발 없음). 폭=`measure`(줄별 최대폭), `sizeThatFits`가 폭 책임+`hasMarkedText` IME 가드. Enter=줄바꿈, 캔버스 빈 곳 탭(투명 캐처)/Esc/포커스상실/도구전환=확정. `model.isEditingText`로 정적 `Text`↔편집기 스왑.
- ⚠️ **시행착오 교훈(반복 말 것)**: ①SwiftUI `TextField(axis:.vertical)`는 macOS에서 Return을 submit 처리·soft-wrap만 → 멀티라인 불가. ②bare NSTextView(resizable=false)는 SwiftUI가 매 키 입력마다 프레임 강제→`setFrameSize`가 **컨테이너/커서 리셋** 연쇄(커서 맨앞·둘째줄 안보임). ③매 키 `setAttributes(전체범위)`도 커서 리셋 → 스타일은 변경 시에만(`lastStyle` 비교). ④무한폭 컨테이너+trailing `\n`=폭폭발. **정석=ScrollView+verticallyResizable**(architect 자문 `ac8e86…`). 조합 중(`hasMarkedText`)엔 손 안 댐.
- **남은 후속(보류)**: 입력칸이 `canvasArea`의 `.scaleEffect(s)` 안에 있어 **한글 IME 후보창 좌표가 구조적으로 어긋남**. 안정화 확인됐으면 *편집칸만 scaleEffect 밖으로 빼서 좌표변환 배치*(`textWM.center*s`=화면좌표, 폰트는 이미 스케일된 크기).

### 편집기 — 정렬/자간/줄간격 (모델·미리보기·저장 일관)
- `TextWatermark`에 `tracking`/`lineSpacing`/`alignment(NSTextAlignment)` 추가. 미리보기 `Text`(`.kerning`/`.lineSpacing`/`.multilineTextAlignment`), 편집칸 NSTextView, 저장 렌더 `drawTextWatermark`(NSParagraphStyle `alignment`+`lineSpacing`, `.kern`, 멀티라인 `boundingRect`+`draw(with:)`) **모두 반영**. 슬라이더: 자간 `-12...20`, 줄간격 `0...24`. 로컬라이즈 키 추가 `editor.text.add/edit/tracking.help/linespacing.help`(en/ko), 고아 키 `label/placeholder` 제거.

### 편집기 — 배율(%) 표시
- 캔버스 fit-scale `s`를 `CanvasScaleKey`(PreferenceKey)로 위로 올려 `imageInfoBadge`에서 `displaySize.width*canvasScale/px.width*100`로 줌% 표시(창 리사이즈 실시간). 포인트 기준(레티나 풀스크린 캡처 ~30–50%); "실물 크기 기준" 원하면 backingScale 반영 가능.

### 산출물
- 툴바 시안 3종(A 2단레일/B 팝오버/C 아코디언): `docs/mockups/editor-toolbar-mockups.html`(+.png). 형이 B 선택.

---

## ✅ 2026-06-07 세션 완료 (캡처 파이프라인 재작성 + 편집기 개선)

> 직전 인계의 "캡처 안 됨" 최우선 버그를 포함해 아래 전부 **완료·실기검증**(사용자 멀티모니터 환경에서 직접 확인). 9갈래 어드버서리얼 코드리뷰로 추가 버그 8건도 수정. 다음 세션은 사용자가 새로 요청할 수정부터.

### 캡처 "안 됨" 버그 — 근본 원인이 3겹이었음 (★중요 교훈)
직전 인계의 가설(오버레이 key window)은 **부분적으로만** 맞았고, 실제로는 세 문제가 겹쳐 있었음:
1. **오버레이가 마우스 드래그를 못 받음** — accessory(LSUIElement) 앱은 `NSApp.activate`만으로 key window를 못 가짐. → 오버레이 창을 **`.nonactivatingPanel`** 로 만들어 앱 활성화 없이 마우스/키를 받게.
2. **`screencapture` 셸아웃이 화면기록 권한을 상속 못 받음** — `/usr/sbin/screencapture`를 `Process`로 띄우면 자식 프로세스라 PICkle의 TCC 권한을 못 써서 `could not create image from rect` 실패. (0.4.0의 `-i` 인터랙티브는 시스템이 사용자동의로 처리해 됐던 것 / 0.5.0의 `-R`은 안 됨.) → **ScreenCaptureKit(`SCScreenshotManager`)** 로 in-process 캡처. macOS 26에선 `CGWindowListCreateImage`도 **빈(검정) 이미지**만 반환하므로 SCK가 유일한 길.
3. **단일 union 오버레이 창이 한 모니터에만 렌더** → 메인 모니터에서 캡처 자체가 안 됨. → **화면별(per-screen) 오버레이**로 재작성(`NSScreen.screens` 각각에 창). commit 시 화면 로컬좌표 + `screen.frame.origin` → 글로벌 Cocoa 좌표.

### ⚠️ 디버깅 함정 (다음에 또 헤매지 말 것)
- **터미널/Claude에서 `open`으로 앱을 띄우면 화면기록 권한이 막힘** (responsible process가 터미널이 됨). 캡처는 **반드시 사용자가 Finder/Spotlight로 직접 실행**해야 권한이 PICkle 기준으로 평가됨. (이것 때문에 한참 "권한 있는데 빈 캡처" 헤맴.)
- `NSLog` 보간 문자열은 unified logging에서 `<private>`로 마스킹돼 `log show` grep에 안 잡힘 → 디버깅 땐 파일로 직접 기록. (지금은 다 제거됨.)
- LSUIElement는 computer-use/`open` allowlist에 안 잡히고, 오버레이는 `sharingType=.none`이라 스크린샷에도 안 찍힘 → 자동 검증 어려움.

### 함께 완료한 편집기/캡처 개선
- **편집기 왼쪽 툴바 클릭영역 확대**(`.contentShape(Rectangle())`) · **파란 포커스 링 제거**(`noFocusRing`/`focusEffectDisabled`).
- **워터마크 위치 스냅/가이드선**(9앵커, 임계 12pt) · **워터마크 크기 슬라이더 범위 `0.4...3`→`0.2...6`**.
- **편집기 캔버스 배경 = 체크무늬**(`CheckerboardBackground`, 검정 캡처 구분용) · **우측 상단 px/용량/확장자 배지**(`imageInfoBadge`, 크기는 `EditorModel.originalByteCount`로 1회 캐시).
- **맥 표준 십자선 커서**(커스텀 push/pop 폐기, `addCursorRect`/`cursorUpdate`).
- **리뷰가 잡은 버그 8건**: Esc/방향키 취소(`NSApp.activate` 추가) · **클립보드 캡처 Retina 2배 크기**(`rep.size`를 논리 포인트로) · 모니터 경계 넘는 드래그 클램프 · PNG 인코딩 백그라운드화(메인스레드 멈춤) · 배지 매프레임 디스크 stat 제거 · `NSScreen.main!` 강제언랩 가드 · 분수좌표 반올림 · 체크무늬 타일 크기.

### 핵심 파일 (캡처)
- `Capture/RegionSelectController.swift` — per-screen `.nonactivatingPanel` 오버레이 + `SelectionOverlayView`(드래그를 화면 bounds로 클램프) + 모드바 + Esc/←/→ 키모니터.
- `Capture/CaptureService.swift` — ScreenCaptureKit 캡처(`captureSCK`, 선택영역 중심이 속한 디스플레이 정확 매칭) + macOS13 Quartz fallback(`captureLegacy`). 옛 셸아웃 코드는 전부 제거됨.

---

## 0. 한 줄 정체성

**PICkle** = macOS 메뉴바 **스크린샷 캡처·편집·보관** 유틸리티.
형 앱 **pizzaClip(클립보드 히스토리)** 의 형제 — 구조·느낌은 같게, 테마는 🥒 **초록 피클**.

- 형: 텍스트(클립보드)를 모은다 → 동생: **스크린샷(이미지)를 모은다**.

---

## 1. 기능 전체

1. **자동 폴더** — `~/Documents/PICkle bottle` 자동 생성. 스크린샷은 데스크탑이 아니라 이 폴더에 저장.
2. **자동삭제** — 지정 기간 지난 파일 자동 휴지통(기본 30일, Settings 조절·끄기).
3. **단축키 3종** — `⇧⌥S` 일반 / `⇧⌥D` 기능(편집) / `⇧⌥A` 클립보드 복사(저장 안 함).
4. **편집창** — 펜 · 블러/모자이크(브러시+영역) · 워터마크(텍스트+로고 동시, 각각 드래그). ⌘Z 되돌리기.
5. **히스토리 창** — 🥒 병 아이콘 클릭 → 그리드 썸네일. 자물쇠/닫기, Clear all, Settings, 드래그앤드롭.
6. **다국어** — 한국어/영어 런타임 전환(Settings → 정보). 기본=시스템 언어.
7. **이스터에그** — (예정) 트리거 시 🥒 burst.

---

## 2. 확정된 설계 결정

| 결정 | 선택 | 이유 |
|---|---|---|
| 캡처 | **화면별 `.nonactivatingPanel` 오버레이**(⇧⌘5식) + **ScreenCaptureKit** in-process 캡처 | accessory 앱은 셸아웃 `screencapture`에 화면기록 권한이 안 넘어가고 macOS26은 `CGWindowListCreateImage`도 빈 이미지 → SCK가 유일. 단일 union 창은 메인 모니터에 안 떠서 화면별 오버레이로. (상세: ✅ 2026-06-07 세션 완료) |
| 저장 | **folder-as-truth** (DB 없음) | 스크린샷이 곧 실제 파일 → 드래그아웃/Finder 통합 거저. 메타데이터 필요해지면 그때 DB |
| 워터마크 | 텍스트 + 로고 **동시**, 각각 독립 | 이름/날짜 글자 + 브랜드 로고 둘 다, 위치·크기 따로 |
| 블러 | 가우시안+모자이크 / 브러시+영역 | 부분(브러시)·큰영역(드래그) 둘 다 |
| 자동삭제 | 기본 30일, 휴지통行 | 보관함 무한증가 방지 + 복구 가능 |
| 클립보드 캡처(A) | bottle 저장 안 함 | 빠른 1회성 복사·PizzaClip 연동 |
| 다국어 | `.lproj` 번들 직접 스위칭(`LocalizationManager`) | 재시작 없이 언어 전환. 일반 NSLocalizedString은 실행 중 못 바꿈 |
| 이름 표기 | 브랜드=`PICkle`, 번들ID/프로젝트명은 유지 | 화면 통일 + TCC 권한·프로젝트 구조 안정 |
| 서명 | Manual + Developer ID, 값은 `Signing.xcconfig`(로컬) | 안정 서명으로 TCC 권한 유지(§5) + 개인정보 비커밋 |
| App Sandbox | OFF (Hardened Runtime ON) | ScreenCaptureKit 화면기록 + 임의 경로 쓰기 때문 |

---

## 3. 아키텍처 골격 (형에서 물려받음)

**SwiftUI + AppKit 혼합, 메뉴바 전용(`LSUIElement=YES`)**.

- **Composition root**: `App/AppDelegate` 가 모든 wiring 허브 (상태바·옵저버·단축키·자동삭제·아이콘).
- **느슨한 연결**: `Notification.Name` 확장(`.pickle*`)으로 컴포넌트 통신.
- **저장**: folder-as-truth. `ScreenshotStore` 가 폴더를 직접 읽음.
- **다국어**: `App/LocalizationManager`(ObservableObject) + 전역 `L("key")`. 뷰는 `LocalizationManager.shared`를 관찰, 언어 바뀌면 `.id(loc.language)`로 리프레시.

```
PicKle/                # ← Xcode 소스폴더 이름은 그대로 PicKle (내부 식별자)
├── App/            # @main, AppDelegate(허브), AppPaths, Notifications, LocalizationManager
├── Capture/        # screencapture 호출(파일/클립보드), 권한 헬퍼
├── DesignSystem/   # Colors(피클그린), Theme(토큰)
├── Editor/         # EditorModel/View/WindowController (펜·블러·워터마크)
├── History/        # 패널·그리드·뷰모델·썸네일 로더
├── MenuBar/        # PickleIcon (빈병/피클병)
├── Settings/       # SettingsView (4탭, +언어 선택)
├── Shortcuts/      # KeyboardShortcuts 등록 (S/D/A)
├── Storage/        # ScreenshotStore, RetentionService, WatermarkPresets,
│                   #   FolderIcon, ClipboardService
└── Resources/      # Info.plist, entitlements, Assets.xcassets, {en,ko}.lproj/Localizable.strings
```

---

## 4. 디자인 시스템

피클 그린 `accent`: `#3B6B2F`(light) / `#6FAE4E`(dark). 패턴: `Color(light:dark:)` 적응형 쌍.
모양 토큰: `panelRadius=14`, `rowRadius=8`. 편집 캔버스는 최대 1000×640로 표시 스케일.

### 아이콘 자산 (`guide/`)
- 앱 아이콘: `피클 앱아이콘.png`(1024) → `AppIcon.appiconset`.
- 메뉴바: `상단메뉴바 아이콘.png`(피클병) / `메뉴바 아이콘 빈병.png`(빈병) → 18·36px 에셋. `isTemplate=false`.
- 폴더 아이콘: `폴더아이콘.png`(피클병) / `폴더아이콘_빈병.png`(빈병) → 1024 정사각으로 패딩 후 `FolderIconFull/Empty.imageset`, `NSWorkspace.setIcon`으로 bottle 폴더에 적용.

---

## 5. ⚠️ 코드 서명 & 권한(TCC)

**문제**: ad-hoc(무서명) 빌드는 빌드마다 코드 "지문"이 바뀜 → TCC가 매번 다른 앱으로 보고 Screen Recording 권한을 안 기억함(허용해도 무한 재요청).

**해결**: Manual + Developer ID 서명으로 지문 고정. 서명 값(팀ID·식별자)은 **`Signing.xcconfig`(gitignore)** 에 두고 `project.yml`의 `configFiles`로 참조 → 개인정보 비커밋 + 안정 서명.

**개발 워크플로우**:
- 항상 서명된 Release 빌드(`-configuration Release`, `CODE_SIGNING_ALLOWED=NO` 쓰지 말 것).
- `/Applications`에 `ditto` 설치해 실행. (산출물 이름이 `PICkle.app`이므로 옛 `PicKle.app`이 있으면 지우고 설치)
- 권한 꼬이면: `tccutil reset ScreenCapture com.Team-jAm.PICkle`.
- Screen Recording 권한 허용 후 앱 재시작 필요.
- 번들 ID 바꾸면 macOS가 새 앱으로 봐서 권한 1회 재부여 필요.

### 테스트 배포 DMG
- `scripts/release-test-dmg.sh` — Release 빌드를 ① 타임스탬프+하드닝 재서명 → ② 앱 공증(`notarytool`) → staple → ③ DMG 생성 → 서명 → ④ DMG 공증 → staple. 결과 `~/Downloads/PICkle-<버전>.dmg`.
- 서명 식별자·공증 키체인 프로필은 **`scripts/release.local.sh`(gitignore)** 에서 주입(`PICKLE_SIGN_IDENTITY` / `PICKLE_NOTARY_PROFILE`).
- 핵심 주의: xcodebuild 기본 서명은 `--timestamp=none`이라 공증 거부 → 스크립트가 `--timestamp`로 재서명함.

---

## 6. 버전 로드맵

- **0.1.0** ✅ 뼈대 + 빈 앱(메뉴바·폴더·패널 골격).
- **0.2.0** ✅ 캡처 + 저장(folder-as-truth) + 그리드.
- **0.3.0** ✅ 편집기(펜·워터마크·블러) + 공증 DMG.
- **0.4.0** ✅ 자동삭제 · Settings 4탭 · ⇧⌥A 클립보드 캡처 · 편집기 개선(탭 순서·⌘Z·텍스트+로고 동시) · 히스토리 자물쇠/닫기 · 빈병↔피클병 아이콘(메뉴바+폴더).
- **0.5.0** ✅ **이름 통일(PICkle)** · **다국어(한/영 런타임 전환)** · **폴더아이콘 교체** · bottle 폴더명 `PICkle bottle` · **빈 보관함 일러스트 교체** · **Sparkle 자동 업데이트(앱 측)** (호스팅은 1.0에서) · **🥒 이스터에그 burst** · **캡처 동작 선택 메뉴(메뉴 먼저)** · **메뉴바 빨려들기 애니메이션(S)** · **편집기 다크 레이아웃** · **편집기 팝오버 툴바(시안 B)** · **캔버스 직접 워터마크 입력** · **문단정렬·자간·줄간격** · **변 기준 스냅 가이드** · **배율% 표시(Retina 보정)** · **캡처 스페이스 이동** · **편집기 크롭(자르기)** · **설정 탭 재구성(일반/단축키/워터마크/저장공간)**.
  - ✅ `project.yml` `MARKETING_VERSION=0.5.0`, `CURRENT_PROJECT_VERSION=5`. (이후 0.5.x 추가 작업: 크롭 핸들·줌% 제거·freeze 캡처·아이콘/이스터에그·보관함 단축키)
- **1.0.0** ✅ **정식 출시(2026-06-09)** — 위 작업 전체 + **화면권한 설명**(`NSScreenCaptureUsageDescription`) + **Sparkle 자동 업데이트 호스팅 완료**(`pizza-clip.com/pickle`). build 6. DMG=`~/Downloads/PICkle-1.0.0.dmg`(공증·staple).
- **1.1.0** ✅ **출시(2026-06-14)** — **펜 색상 강화**: 무지개 색상환 버튼으로 여는 **인라인 색상 피커**(채도/명도 사각형+색조 바, 시스템 색상창 제거) · **스포이드**(`NSColorSampler`) · **hex(#RRGGBB) 클릭 복사** · 옵션 팝오버 `ScrollView`+높이 캡(작은 창 잘림 방지). build 7. DMG=`~/Downloads/PICkle-1.1.0.dmg`(공증·staple). appcast 배포 완료.
- **1.2.0** ✅ **출시(2026-06-25)** — **캡처 십자선 "랜덤" 최종 해결**: 앱이 inactive면 `NSCursor`가 안 먹는 근본원인 규명(첫 캡처는 화살표, 저장 후 히스토리 패널이 `NSApp.activate`로 앱을 깨워야 십자선) → `NSCursor.crosshair` 의존 제거하고 오버레이에 작은 "+" 십자 **직접 draw** + 60fps `NSEvent.mouseLocation` 폴링(active 무관, 화살표와 겹치되 랜덤 0, 사용자 선택 A안) · **🍕 PizzaClip 연동** · **캡처 단축키 누수 수정**(텔레그램 풀스크린 뷰어 안 닫힘) · 설정에 build 번호 표시. build 14. DMG=`~/Downloads/PICkle-1.2.0.dmg`(공증·staple). appcast 배포.
- **1.3.0** ✅ **출시(2026-07-03)** — **열린 메뉴/팝업 캡처**: 캡처를 macOS 기본 `screencapture -i`로 전환(자체 오버레이 폐기) → 펼친 메뉴가 안 닫히고 그대로 캡처. 자체 캡처 스택(RegionSelectController·CaptureModeBar·CaptureFlyAnimation·SCK 경로) 삭제. 사이트 다운로드 1.0.0→1.3.0·`/info` 릴리즈노트(1.2·1.3) 보강. build 15. DMG=`~/Downloads/PICkle-1.3.0.dmg`(공증·staple). appcast·사이트 배포.

---

## 7. 협업 스타일
사용자는 바이브코더 → **쉬운 한국어**, 전문용어는 한 줄 풀이, 코드 바꿀 때 **"무엇을/왜"** 요약.
