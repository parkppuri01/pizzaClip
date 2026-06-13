/** 피클(/pickle) 페이지 콘텐츠 — 한국어/영문. 마크업·스타일은 components/pages/PicklePage.astro. */
import type { Lang } from "./ui.ts";
import type { Shortcut, Classic } from "./pizza.ts";

export type PickleContent = {
  heroH1a: string;
  heroH1b: string;
  heroLead: string;
  ctaDownload: string;
  ctaTutorial: string;
  features: { title: string; desc: string }[]; // 3개 (olive/blue/sand)
  pointsTitle: string;
  points: Classic[]; // 4개 (이모지 요약)
  shortcutsTitle: string;
  shortcutsSub: string;
  shortcuts: Shortcut[]; // 5개
  ctaH2: string;
  ctaLead: string;
  ctaNote: string;
  heroImgAlt: string;
  videoTitle: string;
  metaDescription: string;
  featureList: string[];
};

export const pickle: Record<Lang, PickleContent> = {
  ko: {
    heroH1a: "“캡처는 했는데 어디 갔지...?”",
    heroH1b: "반복되는 삽질 고쳐드립니다.",
    heroLead:
      "“어라, 분명히 찍어뒀는데…” 스크린샷 실종사건 이제 그만. 중요한 스크린샷을 피클처럼 새콤하게 절여두세요. 필요할 때마다 쏙쏙, 가장 신선한 상태로 찾아 드립니다.",
    ctaDownload: "다운로드",
    ctaTutorial: "튜토리얼",
    features: [
      {
        title: "당신의 바탕화면도 스크린샷으로 테트리스 중인가요? (저만 그런 거 아니죠? 🫣)",
        desc: "찍을 땐 좋았지만 돌아서면 미아가 되는 스크린샷들. 이제 여기저기 헤매지 말고 [문서] 폴더 속 ‘피클병’ 하나만 기억하세요. 스크린샷을 찍는 순간, 피클병이 알아서 쏙쏙 받아 담아둡니다. 바탕화면은 미니멀하게, 스크린샷 찾기는 심플하게.",
      },
      {
        title: "스크린샷 한 장 편집하자고 포토샵까지 소환하긴 솔직히 귀찮잖아요. 🤫",
        desc: "계좌번호 가리기, 서명 넣기, 필요한 부분만 싹둑 자르기… 이 모든 걸 프로그램 하나로 손쉽게 해결할 수 있다면? 번거로운 이리저리 이동 없이, 스크린샷 찍고 피클 안에서 한 번에 슥- 이제 보안도, 편집도 피클 하나로 가볍게 ‘싹 가능’입니다.",
      },
      {
        title: "메뉴바 위에 동동 떠 있는 가장 귀여운 보관함",
        desc: "아까 찍은 스크린샷이 필요할 땐, 메뉴바에 상주하는 귀여운 피클병을 톡- 클릭하세요. 무엇이 들어있는지 한눈에 확인하고, 필요한 곳으로 드래그 앤 드롭하면 끝! 작업의 흐름을 깨지 않는 가장 우아하고 직관적인 스크린샷 보관함, 피클병입니다.",
      },
    ],
    pointsTitle: "피클이 하는 일",
    points: [
      { icon: "🫙", title: "스크린샷 무한 보관소", desc: "스크린샷을 찍는 즉시 바탕화면 대신 ‘문서 속 피클병’ 폴더로 자동 저장됩니다. 찍을 때마다 바탕화면이 스크린샷으로 어지럽혀지던 답답함은 이제 끝!" },
      { icon: "⚡️", title: "포토샵 없이 1초 편집", desc: "번거롭게 무거운 편집 프로그램을 켤 필요가 없습니다. 스크린샷을 찍고 그 자리에서 바로 블러, 펜, 워터마크, 크롭 기능으로 간단한 편집과 서명을 손쉽게 처리하세요." },
      { icon: "🍱", title: "메뉴바에서 슥- 꺼내 쓰기", desc: "아까 찍은 스크린샷이 필요할 땐 메뉴바에 있는 귀여운 피클병 아이콘을 톡 누르세요. 어떤 스크린샷이 담겼는지 한눈에 확인하고, 원하는 곳으로 드래그 앤 드롭하면 끝!" },
      { icon: "🔒", title: "프라이버시 철통 보안", desc: "계좌번호나 개인정보가 포함된 민감한 스크린샷도 안심하고 찍으세요. 피클앱의 모든 데이터는 외부 클라우드 서버로 가지 않고 오직 내 기기 안에서만 안전하게 보관됩니다." },
    ],
    shortcutsTitle: "단축키 한눈에 🥒",
    shortcutsSub: "찍는 즉시 저장·편집·복사까지. 전부 Settings에서 바꿀 수 있어요.",
    shortcuts: [
      { keys: "⇧⌥S", desc: "영역 선택 → ‘피클병’ 폴더에 바로 저장" },
      { keys: "⇧⌥D", desc: "영역 선택 → 편집창에서 펜·블러·자르기" },
      { keys: "⇧⌥A", desc: "영역 선택 → 저장 없이 클립보드로 복사" },
      { keys: "⇧⌥F", desc: "보관함(최근 캡처) 열기 · 닫기" },
      { keys: "편집창 ⌘Z · ↵ · esc", desc: "되돌리기 · 자르기 적용 · 취소" },
    ],
    ctaH2: "피클, 지금 바로 받아보세요",
    ctaLead:
      "가격은 0원, 모든 Mac 지원. 스크린샷을 찍는 즉시 ‘피클병’에 차곡차곡 담아드릴게요. 잃어버린 캡처 찾느라 폴더 뒤지는 일은 이제 끝.",
    ctaNote: "macOS 13 이상 · 모든 Mac 지원 · 무료",
    heroImgAlt: "PICkle 포스터 — 연두 배경 위의 피클",
    videoTitle: "PICkle🥒튜토리얼",
    metaDescription:
      "캡처한 건 다 보관해주는 macOS 스크린샷 정리 앱. 찍는 즉시 ‘피클병’ 폴더에 자동 저장, 펜·블러·크롭 즉석 편집, 메뉴바에서 드래그. 무료·100% 로컬.",
    featureList: [
      "스크린샷을 찍는 즉시 ‘피클병’ 폴더에 자동 저장",
      "펜·블러·워터마크·크롭 즉석 편집",
      "메뉴바 보관함에서 드래그 앤 드롭",
      "100% 로컬 저장 — 외부 서버 전송 없음",
      "전역 캡처 단축키, 모두 변경 가능",
      "무료 · macOS 13+ 모든 Mac 지원",
    ],
  },
  en: {
    heroH1a: "“You took the screenshot… so where’d it go?”",
    heroH1b: "We’ll end the endless digging.",
    heroLead:
      "“Wait, I definitely captured that…” — case closed on the missing-screenshot mystery. Pickle every screenshot that matters and keep it crisp and tangy. Pull any one back the moment you need it, fresh as the day you took it.",
    ctaDownload: "Download",
    ctaTutorial: "Tutorial",
    features: [
      {
        title: "Is your desktop a game of screenshot Tetris too? (It’s not just me, right? 🫣)",
        desc: "Great in the moment, gone the second you look away — that’s the life of a screenshot. So stop digging through folders and just remember one thing: the “Pickle Jar” in your Documents. The instant you capture, the jar quietly catches it for you. A minimal desktop, and screenshots you can actually find.",
      },
      {
        title: "Let’s be honest — firing up Photoshop to tweak one screenshot is a pain. 🤫",
        desc: "Blur an account number, drop in a signature, crop to just the part you need… what if one little app did all of it? No bouncing between programs — capture, then edit right inside PICkle in one smooth move. Security and editing, both handled, both light. Pickle’s got it.",
      },
      {
        title: "The cutest little stash, floating right in your menu bar.",
        desc: "Need that shot from earlier? Just tap the cute pickle jar living in your menu bar. See everything inside at a glance, then drag and drop it wherever you need it. The most elegant, intuitive screenshot stash there is — and it never breaks your flow.",
      },
    ],
    pointsTitle: "What PICkle does",
    points: [
      { icon: "🫙", title: "A bottomless screenshot pantry", desc: "The moment you capture, it lands in your “Pickle Jar” folder in Documents instead of cluttering the desktop. No more desktop buried under stray screenshots every time you snap one." },
      { icon: "⚡️", title: "One-second edits, no Photoshop", desc: "No need to fire up a heavy editor. Capture, then right there on the spot — blur, draw, watermark, or crop. Quick edits and signatures, handled in a tap." },
      { icon: "🍱", title: "Grab it from the menu bar in a snap", desc: "Need that earlier shot? Just tap the cute pickle-jar icon in your menu bar. See what’s inside at a glance, then drag and drop it wherever you want — done!" },
      { icon: "🔒", title: "Privacy, locked down tight", desc: "Capture sensitive shots — account numbers, personal info — with total peace of mind. None of PICkle’s data ever touches an outside cloud server; it all stays safe right on your Mac." },
    ],
    shortcutsTitle: "Shortcuts at a glance 🥒",
    shortcutsSub: "Capture, then save, edit, or copy on the spot. Change any of them in Settings.",
    shortcuts: [
      { keys: "⇧⌥S", desc: "Select an area → save straight to your “Pickle Jar” folder" },
      { keys: "⇧⌥D", desc: "Select an area → pen, blur, and crop in the editor" },
      { keys: "⇧⌥A", desc: "Select an area → copy to the clipboard without saving" },
      { keys: "⇧⌥F", desc: "Open / close the stash (recent captures)" },
      { keys: "In editor: ⌘Z · ↵ · esc", desc: "Undo · apply crop · cancel" },
    ],
    ctaH2: "Get PICkle right now",
    ctaLead:
      "Zero dollars, every Mac welcome. The second you capture, we’ll tuck it neatly into your “Pickle Jar.” No more digging through folders for that lost screenshot.",
    ctaNote: "macOS 13+ · works on every Mac · free",
    heroImgAlt: "PICkle poster — a pickle on a fresh green background",
    videoTitle: "PICkle 🥒 Tutorial",
    metaDescription:
      "Free macOS menu-bar app that auto-saves every screenshot to a Pickle Jar folder. Quick edit, drag from the tray, 100% local. macOS 13+.",
    featureList: [
      "Auto-saves every screenshot to a Pickle Jar folder",
      "Quick edit: blur, pen, watermark, crop",
      "Menu-bar tray — drag and drop captures",
      "100% local, nothing leaves your Mac",
      "Global capture shortcuts, fully customizable",
      "Free for every Mac on macOS 13+",
    ],
  },
};
