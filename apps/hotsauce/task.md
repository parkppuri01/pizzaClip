# HotSauce 작업 현황

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
- 앱스토어 버전은 샌드박스 대응 필요 (추후)

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
xcodebuild -project HotSauce.xcodeproj -scheme HotSauce -configuration Release \
  -derivedDataPath build -clonedSourcePackagesDirPath build/SourcePackages build
# 디자인 검증용 팝업 PNG:
HOTSAUCE_SNAPSHOT=/tmp/popup.png ./build/Build/Products/Release/HotSauce.app/Contents/MacOS/HotSauce
```
