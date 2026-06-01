/** 사이트 전역 상수 — 한 곳에서 관리 */

// 최신 릴리스 DMG 바로 다운로드. 고정 파일명(pizzaClip.dmg)이라 버전이 올라가도
// 항상 최신 릴리스를 가리킴 — release.sh 가 매 릴리스마다 이 이름으로도 업로드한다.
export const DOWNLOAD_URL =
  "https://github.com/parkppuri01/pizzaClip/releases/latest/download/pizzaClip.dmg";

export const GITHUB_URL = "https://github.com/parkppuri01/pizzaClip";

// Team JAM 소셜 계정
export const INSTAGRAM_URL = "https://www.instagram.com/team___jam/";
export const THREADS_URL = "https://www.threads.com/@team___jam";

// 사이트 기본 메타
export const SITE_TITLE = "PIZZA CLIP";
export const SITE_DESC =
  "맥 메뉴바에 사는 피자 한 판. 복사한 건 다 기억하는 macOS 클립보드 히스토리 앱.";

// 상단 네비 메뉴 (영문 라벨 + 한글 보조)
// BLOG 는 차후 재개 예정 — 페이지 파일은 보존하되 네비에서만 뺀다.
export const NAV_LINKS = [
  { href: "/", label: "HOME", ko: "홈" },
  { href: "/how-to", label: "HOW TO", ko: "사용법" },
  { href: "/info", label: "INFO", ko: "정보" },
];
