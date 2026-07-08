# HotSauce — HANDOFF

세션 단위 역순 기록. 형제 프로젝트(pizzaClip, PicKle) 관행과 동일.

---

## 세션 7 — 2026-07-09: 설정창 3앱 통일 + 1.1.2 정식 배포 (✅ 완료·배포됨)

### 마지막으로 한 일
- **1.1.2(빌드5) 공증 배포 완료.** 세션 6의 SSID·위치권한 제거분 + 이번 설정창 통일을 함께 배포. 커밋 `47580e0`(핫소스 소스) → master push → Vercel 라이브 검증 통과(appcast 1.1.2, DMG 200, 페이지 다운로드 버튼 1.1.2).
- **설정창 3앱 통일**(`Settings/SettingsView.swift`): 단일 폼 → 통일 '일반' 레이아웃 = 아이콘 헤더(`NSApp.applicationIconImage`) + "HotSauce" + tagline"메뉴바 시스템 모니터" + 버전 `v{short} (build {build})` → `Form(.grouped)`: 로그인시작 / 언어(세그먼트) / 업데이트. 창 `.frame(width:380)`→`500×420`(+`SettingsWindowController` NSWindow `setContentSize` 명시).
- **자동 다운로드 토글 신설**(`@AppStorage("SUAutomaticallyUpdate")=true`) — `AppDelegate`의 강제 `automaticallyDownloadsUpdates=true` **제거**(이제 사용자가 끄면 실제로 꺼짐, 기본 ON은 plist 폴백으로 보장). '업데이트 확인'을 `onCheckForUpdates` 클로저 → `.hotsauceCheckForUpdates` notification 배선으로 교체. 언어 `.system` 라벨 "시스템 설정 따름"→"시스템", enum 순서 시스템|한국어|English 통일.
- **배포 절차**: project.yml 1.1.2/5 → 서명 Release 빌드 → `release-test-dmg.sh`(공증 Accepted·staple·Gatekeeper) → `DOWNLOAD_BASE_URL=https://pizza-clip.com/hotsauce ./scripts/sparkle-appcast.sh` → `web/public/hotsauce/` 복사 → consts `HOTSAUCE_DOWNLOAD_URL` 1.1.2 + `HotSaucePage.astro` softwareVersion 1.1.2 + `info.ts` 릴리스노트(한/영: 1.1.2 + **웹에서 누락됐던 1.1.0·1.1.1 보강**) → 커밋 push → 라이브 검증. 로컬 `/Applications`에 1.1.2(build5) 서명본 설치·실행 중.

### 다음에 할 일
- (선택) 앱 아이콘 둥근 모서리 마스크 · 폭발 파티클 전용 아트 · 옛 `HotSauce-1.0.0.dmg` 정리 (세션 4 이월).

### 주의사항 / 컨텍스트
- **언어 방식**: 핫소스는 인라인 `L("en","ko")` + 재시작 방식 유지(사용자 결정 A). 피클만 실시간 전환이라 언어 아래 재시작 안내가 없음 — **의도된 차이**(원하면 피자·핫소스를 피클의 `.lproj` 실시간 방식으로 이관하는 게 후속 과제).
- 설정창 통일은 세 앱 **동형 복제**(공유 파일 아님, 독립 Xcode 프로젝트). 계획서 `.omc/plans/settings-unification.md`.
- dist/ 는 관례대로 미커밋(web/public에만 배포본 커밋). 세션 6의 "미커밋" 상태는 이번에 커밋·배포로 해소됨.

---

## 세션 6 — 2026-07-06: Wi-Fi 이름(SSID)·위치권한 제거 (✅ 코드 완료 · 미배포·미커밋)

### 마지막으로 한 일
- **사용자 요청**: "Wi-Fi 이름 나오는 부분 없애줘 — 위치권한 물어보는 게 거부감. 관련 코드 전부 빼줘. Wi-Fi 이름은 표시 안 해도 됨." → 세션 4/5에서 넣었던 SSID 표시 + CoreLocation 위치권한을 **전부 제거**(= SSID 기능 도입 이전 상태로 원복).
- **수정 파일 5개**:
  - `Metrics/Snapshot.swift`: `NetworkSnapshot.ssid` 필드 삭제.
  - `Metrics/NetworkSampler.swift`: `wifiInfo() -> (bars, ssid)` 튜플을 원래 `signalBars() -> Int` 로 복원. 신호 판정 조건의 `interface.ssid() != nil ||` 도 떼어내 `interface.rssiValue() != 0` 만으로 판정(SSID 흔적 완전 제거). **신호세기(칸수)는 그대로 유지**. `import CoreWLAN` 은 신호세기(RSSI)에 필요하므로 **유지**.
  - `Popup/PopupView.swift`: `networkSection` 에서 "네트워크 이름" 줄 삭제 + 나머지 2줄 `centerY` 원복(로컬IP·신호 831.2→802.8, 업·다운 860→831.2). **`sectionIcon` 의 `size:62` 는 세션3의 별개 변경이라 건드리지 않음**(원본 96으로 되돌리지 않음).
  - `App/AppDelegate.swift`: `import CoreLocation`, `locationManager` 프로퍼티, `NSApp.activate(...)`+`locationManager.delegate = self` 블록, `CLLocationManagerDelegate` extension **전부 삭제**.
  - `Resources/Info.plist`: `NSLocationWhenInUseUsageDescription`, `NSLocationUsageDescription` 키 삭제.
- **원본 대조**: `git show 1104f70~1`(=1.1.0 SSID 추가 직전)의 `networkSection`·`signalBars` 원본과 1:1 비교해 좌표·로직을 정확히 복원.
- **검증 3중**: (1) `grep -riE "ssid|CoreLocation|CLLocation|locationManager|NSLocation|requestWhenInUse"` → **0건**. (2) Release 컴파일 빌드(`CODE_SIGNING_ALLOWED=NO`) **성공**. (3) `HOTSAUCE_SNAPSHOT` 팝업 렌더 → Wi-Fi 줄 사라지고 네트워크 2줄 정상, 신호세기 ●●●●● 유지 육안 확인.
- **사용자 결정**: 배포·설치·커밋 **모두 안 함**("코드만 유지"). 변경은 작업트리에만 있음(미커밋).

### 다음에 할 일
- **설정창(Settings) 편집** — `HotSauce/Settings/SettingsView.swift`(자체 NSWindow: SMAppService 로그인 시작 · 언어 · 업데이트 확인). 구체 편집 내용은 세션 시작 시 사용자에게 확인.
- (이 세션 변경을 실제 반영하려면 — 사용자 지시 시)
  - 내 Mac만: 재빌드 → `/Applications` 설치.
  - 정식 배포: 1.1.2 bump → 공증 DMG → appcast → `web/public/hotsauce/` 복사 → **버전 3곳**(`project.yml` · `consts.ts` · `HotSaucePage.astro` softwareVersion) → push.

### 주의사항 / 컨텍스트
- **현재 실행 앱은 아직 1.1.1**(위치권한 쓰는 옛 버전). 이번 변경은 소스에만 있음. `build/` 에 검증용 미서명 빌드가 있으나 **설치 안 함**.
- **SSID 제거 범위**: 화면 표시 + Info.plist 설명 + AppDelegate 권한요청 + Sampler 저장·`ssid()` 호출까지 전부. `import CoreWLAN` 만 남김(신호세기용, 위치권한 무관).
- 위치권한을 뺐으므로 앱 첫 실행 시 **위치 허용 팝업이 더는 뜨지 않음**(사용자 요청의 핵심). 기존 1.1.1 설치자의 시스템 설정에 남은 위치 항목은 새 버전이 위치를 안 쓰므로 무의미.
- **미커밋 상태**: 다음 세션에서 설정창 작업을 커밋할 때 이 5개 파일도 함께 커밋할지(또는 별개 커밋으로 분리할지) 결정 필요.

---

## 세션 5 — 2026-07-05: 1.1.1 버그픽스 3종 + 네트워크 이름 재배치 (✅ 완료·배포됨)

### 마지막으로 한 일
- **1.1.1(빌드4) 공증 배포 완료.** 커밋 `6544a62` → master push → Vercel 라이브 검증 통과(appcast 1.1.1, DMG 200, 페이지 버튼 1.1.1).
- 버그 3종 + 레이아웃 1건:
  - **자물쇠 클릭 안 됨**(유일한 실제 코드 결함): `PopupView` 자물쇠의 `.contentShape(Rectangle())`가 `.placedCenter`(=offset) **뒤**에 있어 탭 영역이 팝업 좌상단 원위치에 남던 버그. footer(설정·활성보기)와 동일 패턴 — 그림(Image)과 별도 `Color.clear` 탭영역(placedCenter 845,41.4 w60 h60)으로 분리해 수정. → 사용자 실사용 확인됨.
  - **타이틀 폰트 불일치**: 세션4의 "u(35)≈18pt=피클과 동일"이 **오판**이었음. 피클 히스토리 타이틀은 실제 `.system(size:13, weight:.semibold)`(SF). `DesignTokens`에서 `headerFontSize` 제거 → `headerFont: Font = .system(size:13, weight:.semibold)` 추가, `PopupView.header`가 `DS.headerFont` 사용. 사용자 선택="피클과 완전 통일".
  - **위치권한·Wi-Fi 이름 안 뜸**: **근본 원인은 사용자 Mac의 위치 서비스 전역 OFF**였음(코드 아님). 켜니 즉시 해결. 코드도 표준으로 보강 — `AppDelegate`에서 무조건 `requestWhenInUseAuthorization` 제거, `NSApp.activate(ignoringOtherApps:)` + delegate만 설정. `locationManagerDidChangeAuthorization` 상태 분기(.notDetermined→request / .authorized→`startUpdatingLocation`+desiredAccuracy ThreeKilometers / .denied→폴백) + `didFailWithError` 추가. → **startUpdatingLocation 이 SSID 채움의 실질 트리거**임이 실사용으로 확인됨.
  - **네트워크 이름 위치**(사용자 요청): SSID를 로컬 IP 바로 위로. `networkSection` 세로좌표(802.8/831.2/860) 유지하고 내용만 재배치(이름 → 로컬IP·신호 → 업·다운).
- **배포 절차**: project.yml 1.1.1/빌드4 → `xcodegen generate` → Developer ID 서명 Release 빌드 → `release-test-dmg.sh`(앱+DMG 공증 Accepted·staple·Gatekeeper 통과) → `sparkle-appcast.sh`(EdDSA) → `web/public/hotsauce/` 복사 → `consts.ts` + `HotSaucePage.astro` softwareVersion 1.1.1 → 웹빌드 검증(11p) → 커밋 push → 라이브 검증.
- **로컬 설치**: 정식 공증 1.1.1 을 `/Applications` 에도 설치(그전까지 실행되던 테스트 adhoc 1.1.0 빌드 교체). Developer ID 서명이라 이후 재빌드에도 위치 권한이 안정 유지됨(project.yml 주석 참고). 단 adhoc→Developer ID 서명 전환이라 정식본 첫 실행 시 위치 권한을 1회 재요청할 수 있음 — 사용자 확인 대기 중.

### 다음에 할 일
- (선택) 위치 서비스 OFF/권한 거부 시 팝업이나 설정에 "Wi-Fi 이름을 보려면 위치 서비스를 켜세요" 힌트 UI 추가 고려(지금은 조용히 "—" 폴백이라 사용자가 이유를 모름).
- (이월) 세션4 선택 항목: 앱 아이콘 둥근 모서리, 폭발 파티클 전용 아트, 옛 `HotSauce-1.0.0.dmg` 정리.

### 주의사항 / 컨텍스트
- **릴리스 시 버전 갱신 3곳**: `project.yml`(MARKETING_VERSION+CURRENT_PROJECT_VERSION), `consts.ts`(HOTSAUCE_DOWNLOAD_URL), **`HotSaucePage.astro`의 `softwareVersion`**. 마지막 것은 세션2 1.0.0 이후 세션4에서 갱신 누락됐던 걸 이번에 발견·수정. 놓치기 쉬우니 체크.
- **위치권한 = 시스템 설정 의존**: SSID는 macOS 14+에서 위치권한 필수(Apple DTS 공식). 위치 서비스 전역 OFF면 프롬프트도 안 뜨고 즉시 denied. `tccutil reset Location <bundle>`은 **실패함**(Location은 특수 TCC, 표준 인프라 아님) — 리셋 필요 시 시스템 설정에서 수동.
- **커밋 범위**: 핫소스 소스 3개 + project.yml + web 배포물 8파일. HANDOFF.md·.claude·`dist/`는 제외(세션4 관행 유지, HANDOFF는 미커밋 로컬).

---

## 세션 4 — 2026-07-05: 1.1.0 기능 4종 + 공증 배포 (✅ 완료·배포됨)

### 마지막으로 한 일
- **1.1.0(빌드3) 4개 기능 + 공증 DMG 배포 완료.** 커밋 `1104f70` → master push → Vercel 라이브.
- 세션 3의 "미커밋 로컬 변경"(BatterySampler `externalConnected`, 앱 아이콘 등)도 이번 커밋에 함께 포함됨.
- 기능별:
  - **Wi-Fi 이름(SSID)**: `Snapshot.swift` `NetworkSnapshot.ssid` + `NetworkSampler.swift` `wifiInfo()`(bars+ssid 동시 반환) + `PopupView.swift` 네트워크 섹션 새 줄(left 242, centerY 860). **Option B 채택** — `AppDelegate`에 CoreLocation 위치권한 요청(`requestWhenInUseAuthorization`) + Info.plist `NSLocationWhenInUseUsageDescription`. macOS 14+는 권한 허용해야 이름 표시, 거부 시 "—".
  - **자물쇠 잠금**: `FocusablePanel.isLocked`(resignKey 가드) + `PopupView` 헤더 우상단 SF Symbol 토글(lock.open/lock.fill, placedCenter 845,41.4) + `StatusItemController.makePanel`에서 `panelRef`로 배선.
  - **배터리 충전 아이콘**: `bat2_icon` → **`bat_icon_charge`** (`내부아이콘/` → `Resources/DesignAssets/` 복사, PopupView batterySection).
  - **폭발 이스터에그**: 신규 `Popup/HotSauceBurst.swift`(PickleBurst 이식, 이미지=`menubar_1`, gravity 500, 파티클 40개) + `MetricsEngine.burstID`(빨강 `.bad` 4개+ rising edge, `isPopupVisible`일 때 즉발/닫혀 있으면 `replayBurstIfOverloaded()`로 팝업 열 때 발동) + PopupView ZStack 최상단 오버레이.
  - **타이틀 폰트 확대**: `DesignTokens.headerFontSize` 22→35 (u(35)≈18pt, 피클 타이틀과 동일).
  - **완전 자동 업데이트**: `AppDelegate`에서 `updater.automaticallyChecksForUpdates=true` + `automaticallyDownloadsUpdates=true` 코드 확정 (Info.plist엔 이미 `SUAutomaticallyUpdate=true`).
- **배포 절차 실행**: `project.yml` 1.1.0/빌드3 → Release 빌드(Developer ID 서명) → `release-test-dmg.sh`(앱+DMG 공증 2라운드 Accepted·staple, Gatekeeper 통과) → `sparkle-appcast.sh`(EdDSA appcast) → `web/public/hotsauce/`에 DMG+appcast 복사 → `consts.ts` 다운로드 버튼 1.1.0 → push → **라이브 검증**(appcast 1.1.0/build3, DMG 200, 페이지 버튼 1.1.0).
- **계획 문서**: `docs/PLAN-1.1.0.md` (조사·결정·코드 스케치 전부).

### 다음에 할 일
- **실사용 검증 2건**(자동 검증 불가 — 사용자 확인 필요):
  1. 1.1.0 첫 실행 시 뜨는 **위치 허용 팝업 → "허용"** 후 팝업 네트워크에 Wi-Fi 이름이 실제로 뜨는지.
  2. **폭발 이스터에그 실물** — 빨강 4개+ 상황. 테스트하려면 `MetricsEngine.overloadThreshold`를 잠깐 1~2로 낮춰 팝업 열고 확인 후 원복.
- (선택) 앱 아이콘 둥근 모서리 마스크 — 세션 3에서 넘어온 미결(`hotsauce_mainicon` 각짐). 사용자 확인 후 재생성.
- (선택) 폭발 파티클 전용 "폭탄 핫소스" 아트로 교체 — `HotSauceBurst.swift`의 `Assets.image("menubar_1")` 문자열 1줄만 바꾸면 됨.
- (선택) `web/public/hotsauce/HotSauce-1.0.0.dmg`는 기존 링크 보호용으로 유지 중 — 정리하려면 삭제.

### 주의사항 / 컨텍스트
- **위치권한 ↔ 배포 무관**: 이 앱은 Sparkle+DMG 직접배포(비샌드박스 Developer ID, 엔타이틀먼트 `<dict/>` 확인). 앱스토어 앱이 아니라 위치권한 추가가 배포에 아무 영향 없음. (설령 앱스토어라도 usage string 있으면 승인됨.)
- **미커밋 `dist/`**: `apps/hotsauce/dist/`(appcast.xml, appcast-item-*.xml, notes-1.1.0.md)는 로컬 산출물이라 커밋 안 함(1.0.0과 동일 관행). 배포본은 `web/public/hotsauce/`에만 커밋.
- **커밋 범위**: 핫소스 소스 + 웹 배포 20개 파일만. 피클·무관 web(InfoPage/i18n)·`.claude`·루트 handoff/task는 제외(다른 스트림 보존).
- **팝업 검증**: `HOTSAUCE_SNAPSHOT=<png>` PNG 렌더로 확인(타이틀·자물쇠·충전아이콘·SSID 줄·레이아웃 OK). 단 스냅샷 모드는 `isPopupVisible=false`라 **폭발은 안 뜸** → 실물은 실사용에서만.
- 이 HANDOFF.md 갱신은 로컬 작업트리에만 있음(미커밋) — 다음 세션 session-init이 읽음.

---

## 세션 3 — 2026-07-04: 1.0.1 다듬기 (→ 세션 4에서 1.1.0으로 완료·배포됨)

> 루트 `handoff.md`에 임시로 있던 내용을 이관. **아직 안 끝났고 배포 안 함.** 다음 hotsauce 세션은 여기서 이어받는다.

### 마지막으로 한 일
- **커밋됨**: 배터리 충전 시 왼쪽 아이콘을 플러그(`bat2_icon`)로 전환 (`1de0c42`, repo 버전은 **1.0.0 그대로**). pxd 숨김레이어(plug-svgrepo-com) 기반.
- **미커밋(로컬/테스트빌드 1.0.1빌드4에만 반영)**:
  - 배터리 조건 `IsCharging` → **`ExternalConnected`(꽂힘)** 로 변경 (최적화충전으로 IsCharging이 꽂혀도 자주 false).
  - 타이틀 폰트·아이콘 축소 (27→22, 64→48).
  - 사이드바 아이콘 5개 **62px·x=126** 정렬 (활성상태보기와 통일).
  - 앱 아이콘 `hotsauce_mainicon.png`로 교체 (`AppIcon.icns` 재생성).
- 테스트 빌드 **`1.0.1(빌드4)`** = `/Applications/HotSauce.app`에 설치·실행 중. **배포 안 함**(공증·appcast·push 없음). `project.yml`은 여전히 1.0.0(빌드타임 override로 테스트).

### 다음에 할 일 (바로 착수)
1. **남은 요청 3개 구현** (`apps/hotsauce/HotSauce/`):
   - **네트워크 이름(Wi-Fi SSID)** 한 줄 추가 → `Metrics/Snapshot.swift`의 `NetworkSnapshot`에 `ssid` 필드 + `Metrics/NetworkSampler.swift`에서 `CWWiFiClient.shared().interface()?.ssid()` 캡처 + `Popup/PopupView.swift`의 `networkSection`에 표시(로컬IP 근처, 레이아웃 빡빡하니 배치 주의).
   - **자물쇠 잠금** → 헤더 우상단 토글. 잠금 시 `MenuBar/FocusablePanel.swift`의 `resignKey`가 `orderOut` 안 하게(잠금 상태를 `MetricsEngine` 등 공유 상태로 두고 뷰·패널이 함께 참조).
   - **병 폭발 이스터에그** → 5개 섹션(cpu/memory/disk/battery/network) 중 `.bad` 4개+ 일 때 트리거. **피클/피자클립 이스터에그 구현부터 재조사**. 병 이미지는 `DesignAssets/title_icon.png`(TEAM JAM 병) 또는 `menubar_1.png` 재사용 가능.
2. **앱 아이콘 둥근 모서리** 여부 결정 — 지금 `hotsauce_mainicon.png`가 꽉 찬 정사각형이라 독/파인더에서 각져 보임. 사용자 확인 후 필요하면 마스크 적용해 재생성.
3. 완료·검증 후 **미커밋 앱 변경 전부 커밋**: `BatterySampler.swift`·`Snapshot.swift`·`DesignTokens.swift`·`PopupView.swift`·`Resources/AppIcon.icns`·`assets/HotSauceAppIcon.png` 등.

### 주의사항 / 컨텍스트
- **배터리 아이콘 로직**: `battery.externalConnected`(꽂힘) 기준. `IsCharging`은 최적화충전 때문에 꽂혀도 자주 false → 안 씀. `bat2_icon`(플러그)은 `bat_icon`과 픽셀 동일(1024×833). `Assets.exists()` 폴백 있어 에셋 없어도 안 깨짐. (사용자 "플러그가 작아 보인다" → 배터리 모양이 원래 납작(높이 81%)해서 그런 것, 크기는 동일 — "그대로 두기" 결정.)
- **🚫 computer-use로 팝업 스크린샷 불가** — LSUIElement(메뉴바 전용)라 허용목록에 못 올림. **팝업 UI 검증은 사용자가 직접** 메뉴바 병 아이콘 클릭. (좌표 기반 수정 후 사용자 확인 루프.)
- **테스트 빌드/설치**: `cd apps/hotsauce && xcodebuild -project HotSauce.xcodeproj -scheme HotSauce -configuration Release MARKETING_VERSION=1.0.1 CURRENT_PROJECT_VERSION=N CODE_SIGNING_ALLOWED=NO build`(컴파일 체크) 또는 서명 포함(`CODE_SIGNING_ALLOWED` 빼면 Developer ID). 설치: `pkill -x HotSauce; ditto <DerivedData>/…/Release/HotSauce.app /Applications/HotSauce.app; open`. 로컬 실행은 공증 없어도 OK(`spctl` reject는 정상 — quarantine 없어 실행됨).
- **배포는 아직**: 앱 릴리스(버전 bump→공증→DMG→appcast→push, 8단계)는 사용자가 따로 요청 시. 웹은 master push=Vercel 자동배포.
- **디자인 원본 `apps/hotsauce/hotsauce.pxd`**: 실은 zip(내부 `metadata.info`=SQLite + `data/UUID`=`PTBitmapBuffer` 비트맵). SQLite `document_layers`/`layer_info`로 레이어 이름·flags(하위비트=visible) 조회 가능. 벡터 도형(type 3)은 비트맵 캐시 없어 직접 추출 불가 → 필요 아이콘은 사용자가 Pixelmator로 내보내(`내부아이콘/`은 gitignore, 번들은 `HotSauce/Resources/DesignAssets/`).
- **⚠️ NBSP 주의**: `NavMinimal.astro` 등에 non-breaking space(U+00A0) 섞여 있어 Edit 매칭 실패 가능 → Python 라인 교체 우회.
- ~~(구 경고) pickle 미커밋 변경~~ → **해소됨**: pickle은 이 기간에 **1.3.2 배포 완료**([`../../pickle/docs/HANDOFF.md`](../../pickle/docs/HANDOFF.md)).

---

## 세션 2 — 2026-07-04: 웹 신설 + 1.0.0 공식 배포

- **웹 페이지 신설**: pizza-clip.com 모노레포 `web/`(Astro)에 핫소스를 세 번째 앱으로 추가. 시안(`web/hotsauce_page.png`) 그대로 재현 — 크림 히어로(틸 심전도-병 포스터) → 슬레이트 설명카드 → 빨강 스티커섹션 → 샌드 CTA. 한/영 공용(`components/pages/HotSaucePage.astro` + `i18n/hotsauce.ts`).
- **3앱 확장**: 인트로 3번째 카드, 네비 크로스링크를 "상대 1개 → 나머지 앱 전부"로 개조(피자/피클 페이지 회귀 0 검증 — dev+빌드+프로덕션), 정보 3열 릴리스노트(v1.0.0), llms.txt 3앱 갱신, 색토큰(`--hs-teal/slate/red/sand/poster/ink`)·미들웨어 언어분기 추가.
- **1.0.0 첫 공식 배포**: `project.yml` 0.1.0→1.0.0(빌드1→2) → `release-test-dmg.sh`로 공증 DMG(앱+DMG 2회 Accepted·staple) → `sparkle-appcast.sh`로 EdDSA appcast → `web/public/hotsauce/`에 DMG+appcast 복사 → `consts.ts` `HOTSAUCE_RELEASED=true` → 커밋 `516d1e4` push → Vercel 배포 → 프로덕션 검증(핫소스 URL 200·언어 자동분기·기존 페이지 회귀0).
- **자동업데이트**: 팀원 0.1.0(빌드1) 설치자는 1.0.0(빌드2)으로 자동 업데이트됨.
- 웹쪽 상세(앱 추가 패턴·릴리스 절차·NBSP 주의)는 모노레포 루트 `handoff.md` 참고.

---

## 세션 1 후반 — 2026-07-02 밤: 사용자 피드백 반영

- **병 매핑 사용자 확정**: 기본(쾌적)=빨강, 중부하=노랑, 고부하=레인보우 — 기존 구현 그대로, 종결.
- **팝업 축소**: 540×600 → **468×520pt** (`DS.scale` 0.6→0.52).
  사용자 요구 "75% + 피클보다 조금 크게"가 서로 충돌(피클 460×500 > 540의 75%인 405) →
  피클 비교 조건을 우선해 0.52 채택. 상세 수치 텍스트는 `DS.statFontPoints = 8.7pt` 절대값으로
  고정(최소 가독 크기 — 더 줄이지 말 것). 나머지(아이콘/게이지/제목/헤더)는 scale 따라 축소.
- **얼굴 표정 판정 완화**: 기준이 느슨해 사실상 항상 민트였음 →
  CPU 35/70%(순간값), 메모리는 게이지와 같은 사용률 60/80% 기준 + 커널 압력 단계(2/4)로 격상.
  검증: idle 렌더(메모리 66% → 노랑) / `yes`×8 부하 렌더(CPU 86% → 빨강) 둘 다 확인.
- **앱 아이콘 확정**: `사이트 디자인/메인아이콘.png`("I'm a Hot Sauce person" 하늘색 카드)를
  `assets/HotSauceAppIcon.png` 로 복사 → build-icon.sh 로 icns 재생성. 사용자 지정.
- 주의: 세션 스크래치(/private/tmp/...)는 수 시간 뒤 비워짐 — 렌더 출력 폴더는 mkdir -p 후 사용.

---

## 세션 1 — 2026-07-02: 앱 최초 구현

### 한 일
- **디자인 추출**: hotsauce.pxd(Pixelmator, ZIP+SQLite)에서 레이어 좌표·색·폰트 전부 추출.
  - 좌표계: 논리 900×1000 유닛(Y축 bottom-up, 중심점 기준). 캔버스는 그 2배(1800×2000px).
  - 색: 배경 #3A3A3C / 텍스트 #DEE0E2 / 구분선 #929292 / 게이지 #B6422E /
    얼굴 민트 #007C77·주황 #D97F04·빨강 #B6422E / 모서리 반경 40u
  - 폰트: 전부 Pretendard-Regular (헤더 27u, 섹션 제목 20u, 상세 14.5u — 유닛×0.6=pt)
- **사용자 확정사항**: 번들 ID `com.Team-jAm.HotSauce`(변경 금지), 팝업 540×600pt(scale 0.6),
  메뉴바 병 3종은 상태 자동 변경, 얼굴 3단계 = 민트(쾌적)/노랑(중부하)/빨강(고부하)
- **구현**: XcodeGen 프로젝트(피클 템플릿), Swift 5.9, macOS 13+, LSUIElement
  - `Metrics/`: CPU(host_statistics 틱 차분+5샘플 이동평균), 메모리(vm_statistics64+압력 sysctl+스왑),
    디스크(volumeAvailableCapacityForImportantUsage), 배터리(AppleSmartBattery IOKit),
    네트워크(getifaddrs 차분+CoreWLAN RSSI). 1초/5초 이중 폴링(런캣 방식)
  - `Popup/`: 디자인 좌표를 유닛 그대로 코드에 옮긴 절대배치 SwiftUI 뷰 (`DS.scale` 하나로 크기 조절)
  - `MenuBar/`: NSStatusItem 좌/우클릭 분기, FocusablePanel(포커스 잃으면 닫힘)
  - `Settings/`: 자체 NSWindow (SMAppService 로그인 시작, 언어, 업데이트 확인)
  - Sparkle 2 (형제와 같은 EdDSA 공개키, feed https://pizza-clip.com/hotsauce/appcast.xml)
  - Pretendard-Regular.otf 번들 (Info.plist ATSApplicationFontsPath=".", 리소스 평탄화 주의)
- **검증**: Release 빌드 성공, 실행 확인, `HOTSAUCE_SNAPSHOT=<png>` 훅으로 팝업 렌더 → 디자인과 대조 OK
- **멀티에이전트 리뷰(반박 검증 통과분만 수정)**:
  1. NetworkSampler — ifi_obytes/ifi_ibytes 는 32비트라 4GiB 랩어라운드/인터페이스 소멸 시
     UInt64 언더플로로 속도가 천문학적으로 표시되는 버그 → 인터페이스별 UInt32 랩 안전 차분으로 수정
  2. BatterySampler — IORegistry "Temperature" 는 0.1K 단위(centi-°C 아님).
     ÷100 은 실온에서만 우연히 맞음 → `raw/10 - 273.15` 로 수정 (애플 PowerManagement 소스로 교차 확인)
- **스크립트**: build-icon.sh / release-test-dmg.sh / sparkle-appcast.sh (피클에서 이식, 이름 치환)

### 다음 세션 (웹)
1. pizzaClip web 레포에 hotsauce 페이지 추가 (디자인: `web/hotsauce_page.png`, `a/hotsauce_page.pxd`)
2. 첫 릴리스: project.yml 버전 bump → Release 빌드 → `scripts/release-test-dmg.sh` →
   `DOWNLOAD_BASE_URL=https://pizza-clip.com/hotsauce scripts/sparkle-appcast.sh` →
   DMG+appcast.xml 을 web 레포 `web/public/hotsauce/` 에 복사 → push
3. git init + 첫 커밋은 사용자 확인 후 (아직 git 저장소 아님)

### 열린 질문 / 주의
- **병↔상태 매핑 확인 필요**: 현재 쾌적=빨강병(menubar_1), 중부하=노랑(2), 고부하=레인보우(3).
  반대(쾌적=레인보우, 고부하=빨강)를 원하면 `Snapshot.swift` `bottleAssetName` 세 줄만 스왑.
- 메모리 "압력 %"는 (wired+compressed)/전체 근사치. 얼굴 상태는 커널 공식 압력 단계 사용.
- 배터리 없는 데스크톱 맥은 배터리 섹션이 "—" 표시.
- Wi-Fi RSSI 는 CoreWLAN — 최신 macOS 에서 위치 권한 없이 0 이 나오면 유선 취급(5칸). 실기기별 확인 필요.
- 디버그 훅: `HOTSAUCE_SHOW_POPUP=1`(팝업 자동 표시), `HOTSAUCE_SNAPSHOT=<경로>`(팝업 PNG 저장 후 종료).
- 새 .swift 파일 추가 시 `xcodegen generate` 재실행 필수.
