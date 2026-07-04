/** 사이트 전역 상수 — 한 곳에서 관리 */

// 최신 릴리스 DMG 바로 다운로드. 고정 파일명(pizzaClip.dmg)이라 버전이 올라가도
// 항상 최신 릴리스를 가리킴 — release.sh 가 매 릴리스마다 이 이름으로도 업로드한다.
export const DOWNLOAD_URL =
  "https://github.com/parkppuri01/pizzaClip/releases/latest/download/pizzaClip.dmg";

export const GITHUB_URL = "https://github.com/parkppuri01/pizzaClip";

// Team JAM 소셜 계정 (두 제품 공통)
export const INSTAGRAM_URL = "https://www.instagram.com/team___jam/";
export const THREADS_URL = "https://www.threads.com/@team___jam";

// ── 리뉴얼(2026-06): 루트(/)는 인트로 선택화면. 피자클립 홈은 /pizzaclip 로 이동 ──
export const PIZZA_HOME = "/pizzaclip";

// 사이트 기본 메타 (피자클립)
export const SITE_TITLE = "PIZZA CLIP";
export const SITE_DESC =
  "맥 메뉴바에 사는 피자 한 판. 복사한 건 다 기억하는 macOS 클립보드 히스토리 앱.";

// ── 피클(PICKle) ──
export const PICKLE_GITHUB_URL = "https://github.com/parkppuri01/pickle";
// 1.0.0 정식 출시 — DMG 는 pizza-clip.com 에 직접 호스팅(web/public/pickle/).
// 새 버전 낼 때 이 파일명만 갱신하면 됨.
export const PICKLE_RELEASED = true;
export const PICKLE_DOWNLOAD_URL = "/pickle/PICkle-1.3.2.dmg";
export const PICKLE_TITLE = "PICkle";
export const PICKLE_DESC =
  "캡처한 건 다 보관해주는 macOS 스크린샷 정리 앱. 찍는 즉시 ‘피클병’ 폴더에 차곡차곡.";

// ── 핫소스(Hot Sauce) ──
// 모노레포(pizzaClip) 안에만 존재 — 전용 저장소가 없어 GitHub 은 모노레포로 링크.
export const HOTSAUCE_GITHUB_URL = "https://github.com/parkppuri01/pizzaClip";
// 1.0.0 정식 출시 — DMG 는 pizza-clip.com 에 직접 호스팅(web/public/hotsauce/).
// 새 버전 낼 때 아래 파일명만 갱신하면 됨.
export const HOTSAUCE_RELEASED = true;
export const HOTSAUCE_DOWNLOAD_URL = "/hotsauce/HotSauce-1.0.0.dmg";
export const HOTSAUCE_TITLE = "Hot Sauce";
export const HOTSAUCE_DESC =
  "맥이 얼마나 열심히 일하는지 메뉴바에서 보여주는 macOS 시스템 모니터 앱. CPU·메모리·배터리·네트워크를 한눈에.";

// ⚠️ DEPRECATED (2026-06-09): 옛 Navbar.astro 전용이었음. 이제 모든 페이지가
// NavMinimal(로고+크로스링크+소셜) 을 써서 이 메뉴 목록은 렌더되지 않음.
// 피자 상단바 메뉴를 되살릴 때만 Navbar.astro 와 함께 사용. 안 쓸 거면 둘 다 삭제 가능.
export const NAV_LINKS = [
  { href: PIZZA_HOME, label: "HOME", ko: "홈" },
  { href: "/how-to", label: "HOW TO", ko: "사용법" },
  { href: "/info", label: "INFO", ko: "정보" },
];
