# HotSauce 작업 현황

## ✅ 1.2.0 팝업 배너 + 푸터 여유 + 배포 (2026-08-14, 세션 10)
- [x] 팝업 네트워크 섹션 아래 **Team JAM 사이트 배너** — 클릭 시 pizza-clip.com. 배너 기하(894.9×148.6, 중심 451.9)는 원본 PNG 아이콘 픽셀(206×206 @ x=407.5/2635.5)에서 역산해 기존 아이콘 열(126 / 790.6)에 정확히 정렬
- [x] 푸터 띠 85.5 → **120 유닛** (아이콘 여백 12→29, 탭 영역 70→80). 배너 위 여백 45.5 = 섹션 사이 간격과 동일
- [x] 설정창 개인정보처리방침 링크 + **포커스 링 제거**(Link `focusable(false)` + `makeFirstResponder(nil)`)
- [x] 캔버스 1000 → 1176 (팝업 468×520 → 468×611.5pt)
- [x] **1.2.0(빌드7) 공증 배포** — 앱·DMG 2라운드 Accepted, EdDSA appcast, web 다운로드/버전/릴리스노트(한·영) → 라이브 검증 통과. 커밋 `bf02a7e`
- [ ] **앱스토어(HotSauce-MAS) 업로드 — 빌드7 거부됨, 빌드8 재업로드 필요**
  - 지뢰 ① **"No Team Found in Archive"** — XcodeGen 이 자동 삽입하는 `CODE_SIGN_IDENTITY[sdk=macosx*]` 가 `project.yml` 의 무조건부 설정을 이겨 ad-hoc 서명. `CODE_SIGN_IDENTITY` 줄 제거로 해결
  - 지뢰 ② **`ITMS-91109` Invalid package contents** — 디자인 PNG 3개에 `com.apple.quarantine` xattr. 소스 청소 + 두 타깃 `postBuildScripts` 에 `xattr -cr` 상시 적용으로 해결
  - `project.yml` 은 빌드8 상태. 상세는 `docs/HANDOFF.md` 주의사항
- [ ] **App Store Connect 마무리** — 빌드 8 연결 · 스크린샷 · 설명/키워드/연령등급 · App Privacy "Data Not Collected" · **심사노트에 메뉴바 아이콘 안내 필수** · English (U.S.) 현지화

## 🍎 앱스토어 출시 준비 — 듀얼 타깃 (2026-08-06, 세션 9)
- [x] 샌드박스 실측: 시스템 API 9종을 App Sandbox ON/OFF 로 비교 → **CoreWLAN(Wi-Fi 신호세기)만 차단**, `network.client` 엔타이틀먼트로 해결. 나머지(CPU·메모리·디스크·배터리 IOKit·네트워크·활성보기 실행)는 전부 통과 → **지표 엔진 코드 수정 불필요**
- [x] 타깃 2개 분리 — `HotSauce`(Developer ID + Sparkle, 기존 그대로) / `HotSauce-MAS`(App Sandbox, Sparkle 없음). 코드 분기는 `#if MAS` 하나
- [x] 신규: `HotSauce-MAS.entitlements` · `Info-MAS.plist` · `Signing-MAS.xcconfig(.example)` · `Fonts/NOTICE.txt`
- [x] 양쪽 plist 보강: 저작권 문구 + `LSApplicationCategoryType`, MAS 는 `ITSAppUsesNonExemptEncryption` 추가
- [x] 검증 4중: 두 타깃 빌드 성공 / MAS 번들에 Sparkle 0건 / 직접 배포 회귀 0 / **샌드박스 서명 실행 → 팝업 렌더 정상**
- [x] 웹 `/privacy`·`/en/privacy` 신설 (App Store Connect 필수) — 빌드 11→13페이지, 회귀 0
- [x] 방침 진입점 배치 — 웹 푸터 3개 전부(피자·피클·핫소스) + 앱 설정창 버전 줄 옆. 샌드박스 URL 열기 실측 완료
- [x] 설정창 MAS 높이 330 → **420 원복** (330 은 추정값이었고 렌더해보니 '언어' 섹션이 잘렸음. 420 = 3앱 통일 규격이자 검증된 값)
- [x] 🐞 **실배포 버그 수정** — `.omc` 툴링 상태 파일(jsonl/json)이 앱 번들 Resources 에 섞여 **1.1.3 공개 DMG 까지 배포되고 있었음**. 두 타깃 sources 에 `"**/.omc"` exclude 추가 + 옛 잔여물 삭제 → 번들 잡파일 0건. (피클도 동일 문제 있음 — 별도 스트림)
- 다음: Apple 포털 App ID·프로파일·인증서 → App Store Connect 메타데이터·스크린샷 → **심사노트에 "메뉴바 아이콘 클릭" 필수 기재**(LSUIElement 리젝 방지)
- 상세: `docs/HANDOFF.md` 세션 9

## ✅ 1.1.3 제목 옆 퍼센트 표시 + 배포 (2026-07-15, 세션 8)
- [x] 팝업 섹션 제목 옆에 현재 수치 병기 (`CPU  43%`) — CPU·메모리·저장 용량·배터리. 게이지와 같은 기준값, 네트워크 제외·배터리 미장착 시 생략
- [x] 1.1.3(빌드6) 공증 DMG → appcast → web(다운로드·softwareVersion·릴리스노트 한/영)
- 커밋 `ba91981`

## ✅ 1.1.2 설정창 3앱 통일 + 배포 (2026-07-09, 세션 7)
- [x] 설정창을 피자·피클과 동형으로 통일 — 아이콘·이름·버전 헤더 + `Form(.grouped)`(로그인시작/언어/업데이트), 창 500×420
- [x] 자동 다운로드 토글 신설(`SUAutomaticallyUpdate`) + AppDelegate 의 강제 `automaticallyDownloadsUpdates` 제거 → 토글이 실제로 동작
- [x] 세션 6의 SSID·위치권한 제거분을 함께 배포
- 커밋 `47580e0`

## 🔧 Wi-Fi 이름·위치권한 제거 (2026-07-06, 세션 6) — 세션 7에서 커밋·배포됨
- [x] SSID 표시 + CoreLocation 위치권한 요청 코드 전부 제거 (위치권한 프롬프트 거부감 때문 → SSID 도입 이전 상태로 원복)
  - `Snapshot.swift`(ssid 필드) · `NetworkSampler.swift`(signalBars()로 복원, 신호세기 유지·`ssid()`호출 제거) · `PopupView.swift`(네트워크 이름 줄 삭제 + 좌표 원복, 아이콘 size:62는 유지) · `AppDelegate.swift`(CoreLocation 전부) · `Info.plist`(위치 설명 키 2개)
- [x] 검증 3중: grep 잔여 0건 + Release 컴파일 성공 + 팝업 렌더 육안 확인(Wi-Fi 줄 사라짐, 신호세기 ●●●●● 유지)
- 상태: 당시 미커밋이었으나 **세션 7(1.1.2)에서 커밋·배포로 해소됨**

## ✅ 1.1.1 버그픽스 + 배포 (2026-07-05, 세션 5)
- [x] 자물쇠 클릭 버그 수정 — 탭 영역이 offset(placedCenter) 뒤 contentShape라 팝업 좌상단에 남던 문제 → footer 패턴(별도 Color.clear 탭영역)
- [x] 타이틀 폰트 피클과 통일 — SF 13pt semibold (세션4의 18.2pt Pretendard 오판 바로잡음)
- [x] 위치권한·Wi-Fi 이름 표시 — 근본원인=위치 서비스 전역 OFF(코드 아님). 코드도 델리게이트 상태분기 + startUpdatingLocation 보강
- [x] 네트워크 이름(SSID)을 로컬 IP 바로 위로 재배치
- [x] 1.1.1(빌드4) 공증 DMG → appcast(EdDSA) → web/public → consts.ts+HotSaucePage.astro(softwareVersion) → push → 라이브 검증 통과
- 커밋 `6544a62`

## ✅ 1.1.0 기능 추가 + 배포 (2026-07-05, 세션 3)
- [x] Wi-Fi 네트워크 이름(SSID) 한 줄 추가 — CoreLocation 위치권한 요청 포함(macOS 14+ 필수, 거부 시 "—")
- [x] 팝업 자물쇠 잠금(고정) — 헤더 우상단 토글, 잠그면 포커스 잃어도 안 닫힘 (FocusablePanel.isLocked)
- [x] 배터리 충전기 연결 시 아이콘을 bat_icon_charge 로 교체
- [x] 시스템 과부하(빨강 얼굴 4개+) 이스터에그 — 핫소스 병 폭발(HotSauceBurst), 팝업 열려 있을 때/열 때 발동
- [x] 상단 타이틀 폰트 확대 (피클 타이틀과 동일 ~18pt, headerFontSize 22→35)
- [x] 완전 자동 업데이트 코드로 확정 (automaticallyChecks/DownloadsUpdates=true)
- [x] 1.1.0(빌드3) 공증 DMG → appcast(EdDSA) → web/public/hotsauce/ → 다운로드 버튼(consts.ts) 갱신 → push
- 계획 문서: `docs/PLAN-1.1.0.md`

## ✅ 완료 (2026-07-02, 세션 1)
- [x] 피자클립/피클 인프라 분석, 런캣 소스 기능 분석
- [x] hotsauce.pxd 에서 디자인 스펙 추출 (좌표/색상/폰트 전부)
- [x] XcodeGen 프로젝트 셋업 (project.yml, 서명, Sparkle, 아이콘)
- [x] 지표 수집 엔진: CPU/메모리/디스크/배터리/네트워크
- [x] 메뉴바 병 아이콘 상태별 자동 변경 (쾌적/중부하/고부하)
- [x] 팝업 디자인 구현 (540×600, 디자인 좌표 그대로)
- [x] 설정 창 (로그인 시 자동 시작, 언어, 업데이트 확인)
- [x] 릴리스 스크립트 (release-test-dmg.sh, sparkle-appcast.sh, build-icon.sh)
- [x] Release 빌드 성공 + 실행 확인 + 팝업 렌더 디자인 대조
- [x] 멀티에이전트 코드 리뷰 → 확정 버그 2건 수정 (네트워크 카운터 랩, 배터리 온도 단위)

## ✅ 웹 신설 + 1.0.0 공식 배포 (2026-07-04, 세션 2)
- [x] 웹 페이지 신설 (한/영) → https://pizza-clip.com/hotsauce 라이브 (시안 재현, 인트로 3번째 카드, 네비 크로스링크 N개화, 정보 3열 릴리스노트, llms.txt)
- [x] 첫 공식 릴리스 1.0.0(빌드2): 버전 bump → 공증 DMG → appcast → web/public/hotsauce/ → push → 프로덕션 검증(200·언어분기·회귀0) 완료
- [ ] (선택) 사용자 실사용 피드백 반영 (병 매핑 순서, 팝업 크기, 웹 색·문구·스티커 위치 등)

## 미결 사항
- ~~앱스토어 버전은 샌드박스 대응 필요~~ → **세션 9에서 해소**(듀얼 타깃 + 샌드박스 실측 완료). 남은 건 Apple 포털·App Store Connect 쪽 작업.

## ✅ 팀원 배포 (2026-07-03)
- [x] 서명+공증+staple DMG 생성 → `~/Downloads/HotSauce-0.1.0.dmg` (3.1MB)
  - 앱 공증 Accepted → DMG 공증 Accepted → Gatekeeper "Notarized Developer ID" 통과
  - 팀원은 더블클릭으로 바로 설치 가능 (우클릭 열기 불필요, 인터넷 없이도 실행됨)
  - 재생성: `./scripts/release-test-dmg.sh` (Release 빌드가 build/ 에 있어야 함)

## 확정 사항 (2차 피드백 반영)
- 병 매핑 사용자 확정: 기본(쾌적)=빨강, 중부하=노랑, 고부하=레인보우 ✓
- 팝업 크기: 468×520pt (scale 0.52) — 피클 팝업(460×500)보다 조금 크게.
  상세 수치 텍스트는 8.7pt 절대값 고정(최소 가독 크기, DS.statFontPoints)
- 얼굴 판정 기준: CPU 35/70%, 메모리는 게이지(사용률) 60/80% 기준 + 커널 압력 단계로 격상

## 빌드 명령
```bash
xcodegen generate   # .swift 파일 추가/삭제 후 필수

# 직접 배포 타깃 (Developer ID + Sparkle)
xcodebuild -project HotSauce.xcodeproj -scheme HotSauce -configuration Release \
  -derivedDataPath build -clonedSourcePackagesDirPath build/SourcePackages build

# 앱스토어 타깃 (App Sandbox, Sparkle 없음)
# ⚠️ 산출물 이름이 둘 다 HotSauce.app 이라 derivedDataPath 를 반드시 분리할 것
xcodebuild -project HotSauce.xcodeproj -scheme HotSauce-MAS -configuration Release \
  -derivedDataPath build-mas -clonedSourcePackagesDirPath build/SourcePackages build

# 디자인 검증용 팝업 PNG:
HOTSAUCE_SNAPSHOT=/tmp/popup.png ./build/Build/Products/Release/HotSauce.app/Contents/MacOS/HotSauce
# MAS 빌드는 샌드박스라 컨테이너 안 경로로 줘야 한다:
HOTSAUCE_SNAPSHOT="$HOME/Library/Containers/com.Team-jAm.HotSauce/Data/popup.png" \
  ./build-mas/Build/Products/Release/HotSauce.app/Contents/MacOS/HotSauce
```
