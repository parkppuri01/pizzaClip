/**
 * i18n 공용 헬퍼 — 언어 타입, 경로 해석, 로케일 맵, 공유 UI 문자열, 메타 기본값.
 * 한국어(기본)는 루트(/pizzaclip …), 영문은 /en/ 접두어(/en/pizzaclip …).
 *
 * 페이지 콘텐츠(히어로·기능 본문 등)는 각 src/i18n/{intro,pizza,pickle,info}.ts 에 분리.
 */

export type Lang = "ko" | "en";
export const LANGS: Lang[] = ["ko", "en"];

/** <html lang> 값 */
export const HTML_LANG: Record<Lang, string> = { ko: "ko", en: "en" };
/** og:locale 값 */
export const OG_LOCALE: Record<Lang, string> = { ko: "ko_KR", en: "en_US" };
/** sitemap/hreflang 용 BCP-47 태그 */
export const BCP47: Record<Lang, string> = { ko: "ko-KR", en: "en-US" };

/** 페이지 논리 경로(한국어=기본 경로). 영문은 enHref() 로 /en 접두어를 붙인다. */
export const ROUTES = {
  intro: "/",
  pizza: "/pizzaclip",
  pickle: "/pickle",
  hotsauce: "/hotsauce",
  info: "/info",
  privacy: "/privacy",
} as const;
export type RouteKey = keyof typeof ROUTES;

/** 한국어(기본) 경로 → 영문 경로. ("/" → "/en/", "/pizzaclip" → "/en/pizzaclip") */
export function enHref(koPath: string): string {
  return koPath === "/" ? "/en/" : "/en" + koPath;
}

/** 언어 + 논리 경로키 → 실제 href (내부 링크는 항상 같은 언어 버전으로) */
export function href(lang: Lang, key: RouteKey): string {
  const p = ROUTES[key];
  return lang === "en" ? enHref(p) : p;
}

/** 반대 언어 */
export const otherLang = (lang: Lang): Lang => (lang === "ko" ? "en" : "ko");

// ── 공유 UI 문자열(네비/푸터/소셜/버튼/모달) ──
type UiStrings = {
  navCrossToPickle: string; // 크로스링크 aria — PICkle 로
  navCrossToPizza: string; // 크로스링크 aria — PIZZA CLIP 으로
  navCrossToHotsauce: string; // 크로스링크 aria — Hot Sauce 로
  socialInfo: string;
  socialInstagram: string;
  socialThreads: string;
  socialGithub: string;
  jamHome: string;
  langToEn: string; // ko→en 전환 버튼 aria
  langToKo: string; // en→ko 전환 버튼 aria
  langGroup: string; // 토글 그룹 aria
  footerIntro: string;
  footerPizza: string;
  footerPickle: string;
  footerHotsauce: string;
  footerGithub: string;
  footerNav: string;
  footerSocial: string;
  videoClose: string;
};

export const ui: Record<Lang, UiStrings> = {
  ko: {
    navCrossToPickle: "피클 페이지로 이동",
    navCrossToPizza: "피자클립 페이지로 이동",
    navCrossToHotsauce: "핫소스 페이지로 이동",
    socialInfo: "정보 — 릴리스노트와 팀 소개",
    socialInstagram: "Team JAM 인스타그램 (새 창에서 열림)",
    socialThreads: "Team JAM 스레드 (새 창에서 열림)",
    socialGithub: "GitHub 저장소 (새 창에서 열림)",
    jamHome: "Team JAM 홈",
    langToEn: "View in English",
    langToKo: "한국어로 보기",
    langGroup: "언어 선택 / Language",
    footerIntro: "인트로",
    footerPizza: "피자클립",
    footerPickle: "피클",
    footerHotsauce: "핫소스",
    footerGithub: "깃허브",
    footerNav: "하단 메뉴",
    footerSocial: "소셜 미디어",
    videoClose: "닫기",
  },
  en: {
    navCrossToPickle: "Go to the PICkle page",
    navCrossToPizza: "Go to the PizzaClip page",
    navCrossToHotsauce: "Go to the Hot Sauce page",
    socialInfo: "Info — release notes and the team",
    socialInstagram: "Team JAM on Instagram (opens in a new tab)",
    socialThreads: "Team JAM on Threads (opens in a new tab)",
    socialGithub: "GitHub repository (opens in a new tab)",
    jamHome: "Team JAM home",
    langToEn: "View in English",
    langToKo: "한국어로 보기",
    langGroup: "언어 선택 / Language",
    footerIntro: "Intro",
    footerPizza: "PizzaClip",
    footerPickle: "PICkle",
    footerHotsauce: "Hot Sauce",
    footerGithub: "GitHub",
    footerNav: "Footer menu",
    footerSocial: "Social media",
    videoClose: "Close",
  },
};

// ── 페이지 메타 기본값(<title> · description) — site × lang ──
// description 은 AEO 핵심이므로 각 언어에서 고유·키워드 풍부하게.
type Meta = { title: string; desc: string };
export const APP_NAME: Record<"pizza" | "pickle" | "hotsauce" | "intro", string> = {
  pizza: "PIZZA CLIP",
  pickle: "PICkle",
  hotsauce: "Hot Sauce",
  intro: "PIZZA CLIP & PICkle",
};

export const siteMeta: Record<"pizza" | "pickle" | "hotsauce" | "intro", Record<Lang, Meta>> = {
  pizza: {
    ko: {
      title: "PIZZA CLIP — 맥 클립보드 히스토리 앱",
      desc: "맥 메뉴바에 사는 피자 한 판. 복사한 건 다 기억하는 macOS 클립보드 히스토리 앱. 무료·100% 로컬 저장.",
    },
    en: {
      title: "PIZZA CLIP — Mac menu-bar clipboard history manager",
      desc: "A free macOS clipboard history manager that lives in your menu bar. Copy anything with ⌘C and paste it back instantly — 100% on-device.",
    },
  },
  pickle: {
    ko: {
      title: "PICkle — 맥 스크린샷 정리 앱",
      desc: "캡처한 건 다 보관해주는 macOS 스크린샷 정리 앱. 찍는 즉시 ‘피클병’ 폴더에 차곡차곡. 무료·100% 로컬 저장.",
    },
    en: {
      title: "PICkle — Mac menu-bar screenshot organizer",
      desc: "A free macOS screenshot organizer. Every capture is auto-saved into a tidy pickle-jar folder, with quick edits and a menu-bar tray — 100% on-device.",
    },
  },
  hotsauce: {
    ko: {
      title: "Hot Sauce — 맥 시스템 모니터 메뉴바 앱",
      desc: "맥이 얼마나 열심히 일하는지 메뉴바에서 보여주는 macOS 시스템 모니터. CPU·메모리·배터리·디스크·네트워크를 핫소스 병으로 한눈에. 무료·100% 로컬.",
    },
    en: {
      title: "Hot Sauce — Mac menu-bar system monitor",
      desc: "A free macOS menu-bar system monitor. See how hard your Mac works — CPU, memory, battery, disk, and network at a glance through a hot-sauce bottle. 100% on-device.",
    },
  },
  intro: {
    ko: {
      title: "PIZZA CLIP · PICkle · Hot Sauce — Team JAM",
      desc: "맥 메뉴바에 사는 세 개의 작은 도구. 복사는 PIZZA CLIP, 캡처는 PICkle, 맥 상태는 Hot Sauce 로 똑똑하게. 무료·100% 로컬.",
    },
    en: {
      title: "PIZZA CLIP · PICkle · Hot Sauce — Team JAM",
      desc: "Three tiny tools that live in your Mac menu bar. PIZZA CLIP remembers what you copy, PICkle keeps every screenshot, Hot Sauce shows how hard your Mac works — free, private, no ads.",
    },
  },
};
