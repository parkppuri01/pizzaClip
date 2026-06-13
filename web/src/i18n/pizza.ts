/** 피자클립(/pizzaclip) 페이지 콘텐츠 — 한국어/영문. 마크업·스타일은 components/pages/PizzaPage.astro. */
import type { Lang } from "./ui.ts";

export type Shortcut = { keys: string; desc: string };
export type Classic = { icon: string; title: string; desc: string };

export type PizzaContent = {
  heroH1a: string; // 히어로 제목 1줄
  heroH1b: string; // 히어로 제목 2줄(이모지 포함)
  heroLeadStrong: string; // 리드 첫 문장(볼드)
  heroLeadRest: string;
  ctaDownload: string;
  ctaTutorial: string;
  features: { title: string; desc: string }[]; // 3개 (peach/yellow/green)
  classicTitle: string;
  classic: Classic[]; // 4개 (박스 D)
  downloadChecks: string[]; // 4개
  shortcutsTitle: string;
  shortcutsSub: string;
  shortcuts: Shortcut[]; // 7개
  downloadTitleA: string;
  downloadTitleB: string;
  downloadNote: string;
  heroImgAlt: string;
  billboardAlt: string;
  videoTitle: string;
  metaDescription: string;
  featureList: string[]; // JSON-LD
};

export const pizza: Record<Lang, PizzaContent> = {
  ko: {
    heroH1a: "Mac 메뉴바에",
    heroH1b: "배달된 피자 한판 🍕",
    heroLeadStrong: "⌘C로 주문하고, 단축키 한 번으로 바로 배달받으세요.",
    heroLeadRest: "방금 복사한 뜨끈한 텍스트부터 아까 아껴둔 이미지까지, 식기 전에 메뉴바에서 쏙쏙 꺼내 씁니다.",
    ctaDownload: "다운로드",
    ctaTutorial: "튜토리얼",
    features: [
      {
        title: "오늘 당신은 몇 조각의 피자를 구우셨나요? 🍕",
        desc: "다음 복사에 밀려 허무하게 날아가던 나의 소중한 데이터들. 이제 복사할 때마다 메뉴바에 맛있는 피자가 한 조각씩 차곡차곡 쌓입니다. 텍스트도, 링크도, 이미지도 복사만 하면 자동 저장! 여덟 조각이 모두 모여 ‘피자 한 판’이 완성되는 즐거움을 느끼다 보면, 어느새 산더미 같던 업무도 맛있게 끝나 있을 거예요.",
      },
      {
        title: "마우스로 손 뻗는 시간도 아까운 당신을 위해. ⚡️",
        desc: "방금 복사한 것도, 아까 낮에 복사했던 것도 단축키 하나로 소환 완료! 번거롭게 파일 탐색기나 메모장을 뒤적일 필요가 전혀 없습니다. 작업하던 화면 그대로 단축키만 톡- 누르면 내가 모아둔 ‘피자 조각(클립보드 기록)’들이 한눈에 펼쳐집니다. 마우스에 손대지 말고 키보드 위에서 초고속으로 붙여넣으세요. 작업 속도가 2배는 빨라집니다.",
      },
      {
        title: "외부 유출 제로! 오직 당신의 기기에서만 구워지는 나만의 피자",
        desc: "혹시 비밀번호나 계좌번호, 민감한 개인정보를 복사하면서 찝찝하셨나요? ‘피자클립’은 클라우드 서버로 데이터를 절대 보내지 않습니다. 당신이 복사한 모든 데이터는 오직 내 컴퓨터(로컬) 안에서만 안전하게 피자 조각으로 구워집니다. 외부 유출 걱정 없이 안심하고 마음껏 복사하세요!",
      },
    ],
    classicTitle: "피자클립이 하는 일",
    classic: [
      { icon: "🍕", title: "⌘C의 무한 보관소", desc: "글자부터 이미지, 파일까지 복사하는 즉시 알아서 담아둡니다. 새로 복사했다고 이전 기록이 사라지던 답답함은 끝!" },
      { icon: "⚡", title: "키보드 워리어용 1초 컷", desc: "⌘ + ⇧ + V 로 클립보드를 열고, 숫자키(0~9)로 원하는 조각을 바로 골라 쓰세요. 트랙패드까지 손 옮길 필요 없이 진짜 1초." },
      { icon: "🇰🇷", title: "한/영 전환도 가볍게", desc: "잠자던 오른쪽 ⌘ 키 하나로 한/영을 전환하세요. 맥북 쓰며 은근히 킹받던 입력 소스 스트레스를 날려줍니다. (켜고 끄는 옵션)" },
      { icon: "🔒", title: "철저한 로컬 보안", desc: "복사한 비밀번호·개인정보가 밖으로 샐까 걱정이셨나요? 모든 히스토리는 외부 서버를 타지 않고 오직 내 맥 안에서만 보관됩니다." },
    ],
    downloadChecks: [
      "가격은 0원 — 조건 없이 받아서 쓰세요",
      "내 맥북에 찰떡 — 기종 상관없이 모든 Mac에서 부드럽게",
      "안전해요 — 애플 인증 완료, 바이러스·보안 경고 없음",
      "알아서 업데이트 — 수동으로 안 챙겨도 늘 최신",
    ],
    shortcutsTitle: "단축키 한눈에 🍕",
    shortcutsSub: "키보드만으로 1초 컷. 복사한 조각을 바로 꺼내 쓰세요.",
    shortcuts: [
      { keys: "⌘⇧V", desc: "클립보드 히스토리 팝업 열기" },
      { keys: "⌘⌥⌃1 ~ 9", desc: "해당 번호 항목을 바로 붙여넣기" },
      { keys: "↑ ↓ / 1~9", desc: "팝업 안에서 항목 이동·선택" },
      { keys: "↵", desc: "선택한 항목 붙여넣기" },
      { keys: "0", desc: "9 → 1 전체 순차 붙여넣기" },
      { keys: "⌫", desc: "항목 삭제 · ⌘P 고정(핀)" },
      { keys: "오른쪽 ⌘", desc: "한국어 ↔ 영문 입력 전환 (옵션 켰을 때)" },
    ],
    downloadTitleA: "Mac에 빼놓을 수 없는 토핑,",
    downloadTitleB: "피자클립",
    downloadNote: "macOS 13 이상 · 모든 Mac 지원 · 무료",
    heroImgAlt: "피자클립 메인 일러스트 — 메뉴바에서 꺼내 쓰는 피자 한 판",
    billboardAlt: "피자클립 지하철 광고 — STILL HAVEN'T TRIED THE PIZZA CLIP?",
    videoTitle: "피자클립🍕튜토리얼",
    metaDescription:
      "맥 메뉴바에 사는 피자 한 판. 복사한 건 다 기억하는 macOS 클립보드 히스토리 앱. ⌘C 한 번이면 텍스트·이미지·파일까지 자동 저장, 단축키로 바로 소환. 무료·100% 로컬.",
    featureList: [
      "복사한 텍스트·이미지·파일을 자동으로 기록하는 클립보드 히스토리",
      "단축키(⌘⇧V) 한 번으로 기록 즉시 소환",
      "숫자키(⌘⌥⌃1~9)로 원하는 항목 바로 붙여넣기",
      "자주 쓰는 항목 핀 고정 · 순차 붙여넣기",
      "오른쪽 ⌘ 한/영 입력 전환(옵션)",
      "100% 로컬 저장 — 외부 서버 전송 없음",
    ],
  },
  en: {
    heroH1a: "A whole pizza,",
    heroH1b: "delivered to your Mac menu bar 🍕",
    heroLeadStrong: "Order with ⌘C, deliver with one shortcut.",
    heroLeadRest: "From the text you copied two seconds ago to that image you stashed earlier, pull every slice straight from your menu bar while it’s still hot.",
    ctaDownload: "Download",
    ctaTutorial: "Tutorial",
    features: [
      {
        title: "How many slices did you bake today? 🍕",
        desc: "All that precious data, gone the instant your next copy bumped it off the clipboard. Not anymore. Every time you copy, a fresh slice stacks up in your menu bar — text, links, images, saved automatically. Watch all eight come together into a whole pie, and somehow that mountain of work is done before you know it.",
      },
      {
        title: "For people who can’t spare the second it takes to reach for the mouse. ⚡️",
        desc: "What you copied a moment ago, what you copied at noon — one shortcut summons it all. No more digging through Finder or a scratch note. Stay right where you are, tap the shortcut, and every slice you’ve collected (your clipboard history) fans out at a glance. Hands off the mouse — paste at full speed from the keyboard. You’ll work about twice as fast.",
      },
      {
        title: "Zero leaks. Your pizza is baked on your machine, and yours alone. 🔒",
        desc: "Ever felt a little uneasy copying a password, an account number, or other sensitive info? PizzaClip never sends your data to a cloud server. Everything you copy is baked into a slice safely inside your own computer (locally) — and nowhere else. Copy whatever you want, as much as you want, with zero worry about leaks.",
      },
    ],
    classicTitle: "What PizzaClip does",
    classic: [
      { icon: "🍕", title: "An endless vault for ⌘C", desc: "Text, images, files — the moment you copy, it’s stashed for you. No more groaning when a new copy wipes out the last one." },
      { icon: "⚡", title: "A one-second draw for keyboard warriors", desc: "Hit ⌘⇧V to open your clipboard, then press a number key (0–9) to grab the exact slice you want. No reaching for the trackpad — one second, for real." },
      { icon: "🇰🇷", title: "Easy Korean/English switching", desc: "Flip between Korean and English with that idle right ⌘ key. It kills the input-source annoyance that quietly drives Mac users up the wall. (Toggle on or off.)" },
      { icon: "🔒", title: "Airtight local security", desc: "Worried a copied password or personal detail might slip out? Your whole history stays on your Mac and never touches an outside server." },
    ],
    downloadChecks: [
      "Free, zero bucks — grab it and go, no strings attached",
      "Made for your Mac — runs smooth on every model, whatever you’ve got",
      "Safe and sound — Apple-notarized, no virus or security warnings",
      "Updates itself — always current, nothing to chase down",
    ],
    shortcutsTitle: "Shortcuts at a glance 🍕",
    shortcutsSub: "One second, keyboard only. Pull out a copied slice and use it right away.",
    shortcuts: [
      { keys: "⌘⇧V", desc: "Open the clipboard history popup" },
      { keys: "⌘⌥⌃1 ~ 9", desc: "Paste item number 1–9 instantly" },
      { keys: "↑ ↓ / 1~9", desc: "Move and select items inside the popup" },
      { keys: "↵", desc: "Paste the selected item" },
      { keys: "0", desc: "Paste everything in sequence, 9 → 1" },
      { keys: "⌫", desc: "Delete an item · ⌘P to pin" },
      { keys: "Right ⌘", desc: "Switch Korean ↔ English input (when the option is on)" },
    ],
    downloadTitleA: "PizzaClip —",
    downloadTitleB: "the one topping your Mac can’t go without",
    downloadNote: "macOS 13+ · Works on every Mac · Free",
    heroImgAlt: "PizzaClip main illustration — a whole pizza you pull from the menu bar",
    billboardAlt: "PizzaClip subway ad — STILL HAVEN'T TRIED THE PIZZA CLIP?",
    videoTitle: "PizzaClip 🍕 Tutorial",
    metaDescription:
      "PizzaClip is a free macOS menu-bar clipboard manager. ⌘C anything — text, images, files — and recall it instantly with a shortcut. 100% local, nothing leaves your Mac.",
    featureList: [
      "Automatic clipboard history for text, images, and files",
      "Instant recall with a keyboard shortcut (⌘⇧V)",
      "Paste any saved item by number (⌘⌥⌃1–9)",
      "Pin favorite clips and sequential paste",
      "One-tap Korean/English input switching",
      "100% local — nothing is ever sent to the cloud",
    ],
  },
};
