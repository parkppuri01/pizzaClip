# HotSauce — HANDOFF

세션 단위 역순 기록. 형제 프로젝트(pizzaClip, PicKle) 관행과 동일.

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
