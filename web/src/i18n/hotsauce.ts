/** 핫소스(/hotsauce) 페이지 콘텐츠 — 한국어/영문. 마크업·스타일은 components/pages/HotSaucePage.astro. */
import type { Lang } from "./ui.ts";

export type HotSauceContent = {
  heroH1a: string;
  heroH1b: string;
  heroLead: string;
  ctaDownload: string;
  ctaSoon: string; // 릴리스 전 '곧 출시'
  // 설명 섹션(슬레이트블루 위 카드)
  explainLead: string;
  explainBody1: string;
  explainBody2: string;
  // CTA(샌드)
  ctaH2: string;
  ctaLead: string;
  ctaNote: string;
  // 직접배포(DMG) 채널 마감 안내 — 예전에 이 사이트에서 받아 쓰던 사용자용.
  // 번들 ID 는 같아도 App Store 판은 샌드박스라 설정이 넘어가지 않는다.
  ctaMigration: string;
  // 이미지 alt / 메타
  heroImgAlt: string;
  laptopAlt: string;
  metaDescription: string;
  featureList: string[];
};

export const hotsauce: Record<Lang, HotSauceContent> = {
  ko: {
    heroH1a: "Mac 조용한데..",
    heroH1b: "왜 이렇게 뜨겁지? 🔥",
    heroLead:
      "겉으로는 아무 일 없는 척해도, 뒤에서는 CPU가 뛰고 메모리가 바쁘고 배터리가 조용히 줄어들고 있을지 몰라요. Hot Sauce로 내 맥이 얼마나 열심히 일하는지 확인해보세요.",
    ctaDownload: "Mac App Store에서 받기",
    ctaSoon: "곧 출시",
    explainLead:
      "숫자는 정확하게, 경험은 조금 더 즐겁게. Mac이 얼마나 뜨겁게 일하고 있는지 확인해보세요. 🔥",
    explainBody1:
      "CPU 사용량, 메모리 점유율, 배터리 잔량, 디스크 사용 현황, 네트워크 정보까지 — 지금 내 맥이 어떤 상태인지 한눈에 확인할 수 있어요. 복잡한 창을 열 필요 없이, 필요한 정보만 메뉴바 아이콘으로 가볍게 확인하세요.",
    explainBody2:
      "조용히 일하고 있는 맥이 사실은 열심히 달리고 있는 건 아닌지, 배터리가 예상보다 빠르게 줄고 있지는 않은지 — Hot Sauce가 메뉴바에서 작은 신호를 보내줍니다.",
    ctaH2: "피자클립, 피클 그리고 빠질 수 없는 핫소스",
    ctaLead:
      "Mac이 지금 열심히 달리는 중인지, 쉬어가는 중인지. 메뉴바의 Hot Sauce 아이콘으로 쉽고 재밌게 확인해 보세요.",
    ctaNote: "macOS 13 이상 · 모든 Mac 지원 · 무료 · Mac App Store",
    ctaMigration:
      "예전에 이 사이트에서 직접 받아 쓰고 계셨나요? App Store 버전이 쓰던 앱을 그대로 대신하니 따로 지우실 건 없어요. 설치한 뒤에 메뉴바의 핫소스 병을 한 번 종료했다 켜주시면 새 버전으로 바뀝니다. 설정(언어·로그인 시 자동 시작)만 한 번 다시 맞춰주세요.",
    heroImgAlt: "Hot Sauce 포스터 — 틸 배경 위 심전도 선이 핫소스 병으로 이어지는 그림",
    laptopAlt: "Team JAM 스티커(핫소스·피자클립·피클)를 붙인 맥북",
    metaDescription:
      "맥이 얼마나 열심히 일하는지 메뉴바에서 보여주는 macOS 시스템 모니터. CPU·메모리·배터리·디스크·네트워크를 핫소스 병으로 한눈에. 무료·100% 로컬.",
    featureList: [
      "CPU·메모리·배터리·디스크·네트워크 실시간 모니터링",
      "메뉴바 핫소스 병 아이콘 — 부하에 따라 색이 바뀜",
      "복잡한 창 없이 메뉴바에서 한눈에",
      "100% 로컬 — 외부 서버로 전송하지 않음",
      "무료 · macOS 13+ 모든 Mac 지원",
    ],
  },
  en: {
    heroH1a: "Your Mac looks calm —",
    heroH1b: "so why’s it running hot? 🔥",
    heroLead:
      "It seems idle on the surface, but behind the scenes your CPU is racing, memory is busy, and the battery is quietly draining. Hot Sauce shows you just how hard your Mac is working.",
    ctaDownload: "Get it on the Mac App Store",
    ctaSoon: "Coming soon",
    explainLead:
      "Precise numbers, a little more fun. See exactly how hard your Mac is working. 🔥",
    explainBody1:
      "CPU load, memory usage, battery level, disk space, network activity — see what your Mac is doing at a glance. No heavy windows to open; just the essentials, right from a menu-bar icon.",
    explainBody2:
      "Is your seemingly-idle Mac actually sprinting? Is the battery draining faster than expected? Hot Sauce sends you a small signal, right from the menu bar.",
    ctaH2: "PizzaClip, PICkle, and the Hot Sauce you can’t skip",
    ctaLead:
      "Is your Mac sprinting or taking a breather? Check the fun, easy way — right from the Hot Sauce icon in your menu bar.",
    ctaNote: "macOS 13+ · works on every Mac · free · on the Mac App Store",
    ctaMigration:
      "Downloaded Hot Sauce straight from this site before? The App Store version replaces your existing copy in place — there's nothing to delete. After installing, quit Hot Sauce from the menu bar and open it again to pick up the new version. Your settings — language and launch at login — don't carry over, so set them once more.",
    heroImgAlt: "Hot Sauce poster — a heartbeat line flowing into a hot-sauce bottle on a teal background",
    laptopAlt: "A MacBook covered in Team JAM stickers — Hot Sauce, PizzaClip, and PICkle",
    metaDescription:
      "A free macOS menu-bar system monitor. See how hard your Mac works — CPU, memory, battery, disk, and network at a glance through a hot-sauce bottle. 100% on-device.",
    featureList: [
      "Real-time CPU, memory, battery, disk, and network monitoring",
      "A menu-bar hot-sauce bottle that changes color with load",
      "Everything at a glance — no heavy windows",
      "100% local — nothing is sent to any server",
      "Free · works on every Mac on macOS 13+",
    ],
  },
};
