/** 사이트 전역 상수 — 한 곳에서 관리 */

// 최신 릴리스 다운로드 (첫 릴리스 전에는 releases 목록으로 랜딩)
export const DOWNLOAD_URL =
  "https://github.com/parkppuri01/pizzaClip/releases/latest";

export const GITHUB_URL = "https://github.com/parkppuri01/pizzaClip";

// 사이트 기본 메타
export const SITE_TITLE = "PIZZA CLIP";
export const SITE_DESC =
  "맥 메뉴바에 사는 피자 한 판. 복사한 건 다 기억하는 macOS 클립보드 히스토리 앱.";

// 상단 네비 메뉴 (영문 라벨 + 한글 보조)
export const NAV_LINKS = [
  { href: "/", label: "HOME", ko: "홈" },
  { href: "/how-to", label: "HOW TO", ko: "사용법" },
  { href: "/blog", label: "BLOG", ko: "블로그" },
];
