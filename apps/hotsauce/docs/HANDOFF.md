# HotSauce — HANDOFF

세션 단위 역순 기록. 형제 프로젝트(pizzaClip, PicKle) 관행과 동일.

---

## 세션 3 — 2026-07-04: 1.0.1 다듬기 (⚠️ 진행 중 · 미배포)

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
