/** 인트로(/) 페이지 콘텐츠 — 한국어/영문. 마크업·스타일은 components/pages/IntroPage.astro. */
import type { Lang } from "./ui.ts";

export type IntroContent = {
  titleLine1: string; // 1줄 (크림)
  titleLine2a: string; // 2줄 앞부분 (크림)
  titleLine2b: string; // 2줄 강조 (어두운 슬레이트)
  subtitle: string;
  pizzaCaption: string;
  pizzaAria: string;
  pizzaIconAlt: string;
  pickleCaption: string;
  pickleAria: string;
  pickleIconAlt: string;
};

export const intro: Record<Lang, IntroContent> = {
  ko: {
    titleLine1: "메뉴바 한 칸에 자리잡은",
    titleLine2a: "편리한",
    titleLine2b: "작은 도구.",
    subtitle: "완전 무료 / 내 기기에서만 안전하게 / 광고 제로",
    pizzaCaption: "복사한건 다 기억하는 피자클립",
    pizzaAria: "피자클립 — 복사한 건 다 기억하는 맥 클립보드 앱 보러가기",
    pizzaIconAlt: "피자클립 앱 아이콘",
    pickleCaption: "캡쳐한건 다 보관해주는 피클",
    pickleAria: "피클 — 캡처한 건 다 보관해주는 맥 스크린샷 앱 보러가기",
    pickleIconAlt: "피클 앱 아이콘",
  },
  en: {
    titleLine1: "Lives in your menu bar —",
    titleLine2a: "a handy",
    titleLine2b: "little tool.",
    subtitle: "100% free / Private to your Mac / Zero ads",
    pizzaCaption: "PizzaClip remembers everything you copy.",
    pizzaAria: "PizzaClip — meet the Mac clipboard app that remembers everything you copy",
    pizzaIconAlt: "PizzaClip app icon",
    pickleCaption: "PICkle keeps every capture fresh.",
    pickleAria: "PICkle — meet the Mac screenshot app that keeps every capture you take",
    pickleIconAlt: "PICkle app icon",
  },
};
