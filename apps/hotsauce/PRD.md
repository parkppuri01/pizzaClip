# HotSauce (핫소스) — 제품 요구사항

macOS 메뉴바에서 시스템 리소스를 보여주는 앱. 런캣(RunCat)과 기능적으로 유사하되 디자인은 완전히 독자적.
피자클립(pizzaClip)·피클(PICkle)과 한 가족(Team JAM)으로, pizza-clip.com 에서 웹 배포. 향후 앱스토어 출시 예정.

## 핵심 동작

### 메뉴바 아이콘 (핫소스 병)
- 시스템 상태(CPU 5샘플 이동평균)에 따라 병이 자동으로 바뀐다:
  - 쾌적 (CPU < 50%) → `menubar_1` 빨간 병 (기본 브랜드 병)
  - 중부하 (50–80%) → `menubar_2` 노란 병
  - 고부하 (> 80%) → `menubar_3` 레인보우 병
  - ※ 매핑은 `Snapshot.swift` 의 `bottleAssetName` 한 곳에서 변경 가능
- 좌클릭 → 팝업 열기/닫기, 우클릭 → 컨텍스트 메뉴(설정/업데이트 확인/종료)

### 팝업 (hotsauce.pxd 디자인 100% 재현)
- 디자인 원본 900×1000 유닛 → 화면 540×600pt (scale 0.6, `DesignTokens.swift` 에서 조절)
- 배경 #3A3A3C, 텍스트 #DEE0E2, 게이지 빨강 #B6422E, 폰트 Pretendard-Regular(번들 포함)
- 5개 섹션 + 상태 얼굴(민트 #007C77 쾌적 / 주황 #D97F04 중부하 / 빨강 #B6422E 고부하):
  1. **CPU**: 게이지=사용률, 시스템/사용자/대기 %
  2. **메모리**: 게이지=사용률, 압력 %/사용 메모리/캐쉬/스왑 (압력 단계는 커널 값)
  3. **저장 용량**: 게이지=사용률, 사용/전체 GB (Finder 기준 1000단위)
  4. **배터리**: 게이지=잔량, 잔량 %/온도 ℃/사이클 (데스크톱 맥은 — 표시)
  5. **네트워크**: 로컬 IP, 신호상태 ●○ 5칸(Wi-Fi RSSI, 유선=5칸), 업로드/다운로드
- 푸터: "활성 상태 보기"(Activity Monitor 열기) + 설정 톱니

### 폴링 (런캣 방식)
- 1초: CPU(5샘플 이동평균) + 네트워크 속도
- 5초(팝업 열려 있으면 1초): 메모리/디스크/배터리

## 기술 스택
- Swift 5.9 / SwiftUI + AppKit / macOS 13.0+ / LSUIElement (Dock 없음)
- XcodeGen (`project.yml` 이 소스 오브 트루스, `.xcodeproj` 는 gitignore)
- 번들 ID: `com.Team-jAm.HotSauce` (절대 변경 금지)
- 서명: Manual + Developer ID (Signing.xcconfig, gitignore)
- Sparkle 2 자동 업데이트 (형제 앱과 같은 EdDSA 키쌍, feed: pizza-clip.com/hotsauce/appcast.xml)
- 로그인 시 자동 시작: SMAppService

## 배포 (다음 세션: 웹)
- 피클 방식: DMG + appcast.xml 을 pizzaClip web 레포 `web/public/hotsauce/` 에 복사 → Vercel
- 릴리스: `scripts/release-test-dmg.sh` (서명→공증→DMG→2차 공증) + `scripts/sparkle-appcast.sh`
