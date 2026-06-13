/** 정보(/info) 페이지 콘텐츠 — 한국어/영문. 마크업·스타일은 components/pages/InfoPage.astro. */
import type { Lang } from "./ui.ts";

export type Release = { version: string; label: string; notes: string[] };

export type InfoContent = {
  headH1: string;
  headSub: string;
  relHeadingSuffix: string; // "릴리스노트" / "Release Notes"
  releases: Release[]; // 피자클립
  pickleReleases: Release[];
  infoMore: string;
  infoMoreLinkPizza: string;
  infoMoreLinkPickle: string;
  relMoreBold: string;
  relMoreRest: string;
  teamTitle: string;
  teamTagline: string; // 해당 언어 문구(이탤릭)
  teamBody1Html: string; // brand 스팬 포함 HTML
  teamBody2: string;
  teamSignQuote: string; // 반대 언어 문구(서명 위치)
  appbtnPizza: string;
  appbtnPickle: string;
  metaTitle: string;
  metaDescription: string;
};

export const info: Record<Lang, InfoContent> = {
  ko: {
    headH1: "Info · 정보",
    headSub: "두 앱의 버전 기록과 만드는 사람들을 소개합니다.",
    relHeadingSuffix: "릴리스노트",
    releases: [
      {
        version: "1.1.0",
        label: "팝업 잠금 · 여러 개 고정",
        notes: [
          "팝업 상단에 자물쇠 버튼이 생겼어요 — 잠그면 다른 곳을 눌러도 팝업이 닫히지 않아요.",
          "⌘P로 여러 항목을 한꺼번에 고정 — 고정한 순서대로 1, 2, 3번 자리를 차지해요.",
          "팝업 상단에 보관 개수 배지와 닫기 버튼을 더해 한눈에 보기 좋아졌어요.",
          "오른쪽 ⌘ 한/영 전환이 더 안정적으로 동작하도록 다듬었어요.",
          "업데이트 창에서 새 버전의 바뀐 점을 바로 확인할 수 있어요.",
        ],
      },
      {
        version: "1.0.0",
        label: "정식 출시 🎉",
        notes: [
          "복사한 텍스트·이미지·파일을 메뉴바에 차곡차곡 보관",
          "단축키 한 번으로 원하는 항목 바로 붙여넣기",
          "히스토리가 쌓일수록 메뉴바 피자가 한 조각씩 늘어나요",
          "Apple 인증 완료로 설치 경고 없이 깔끔하게 실행",
          "새 버전이 나오면 알아서 업데이트",
        ],
      },
      { version: "0.1.7", label: "자동 업데이트 도입", notes: ["앱이 스스로 최신 버전을 확인하고 받아오기 시작했어요."] },
      {
        version: "0.1.6",
        label: "Apple 인증 + 🍕 ‘피자’ 깜짝 연출",
        notes: [
          "Apple 개발자 인증을 받아 설치 시 보안 경고가 사라졌어요.",
          "‘피자’ 또는 ‘pizza’를 복사하면 화면에 피자가 팡팡 터집니다.",
        ],
      },
      { version: "0.1.5", label: "한/영 전환 추가", notes: ["오른쪽 ⌘ 키 한 번으로 한국어 ↔ 영문 전환 (켜고 끌 수 있는 옵션)."] },
      { version: "0.1.4", label: "🍕 이스터에그", notes: ["‘pizza’를 복사하면 피자가 튀어오르는 깜짝 애니메이션을 넣었어요."] },
      { version: "0.1.3", label: "새 앱 아이콘 · pizzaClip 으로 이름 정리", notes: ["앱 아이콘과 메뉴바 피자 그림을 새로 단장했어요."] },
      { version: "0.1.1", label: "첫 공개", notes: ["자동 복사 기록, 팝업, 핀 고정, 전체 비우기 등 기본기를 갖췄어요."] },
    ],
    pickleReleases: [
      {
        version: "1.0.0",
        label: "정식 출시 🥒",
        notes: [
          "스크린샷을 찍으면 자동으로 문서 속 ‘피클병’ 폴더에 차곡차곡 저장돼요.",
          "메뉴바 아이콘에서 최근 캡처를 미리보기로 확인하고, 드래그 한 번으로 어디든 붙여넣기.",
          "잃어버린 캡처 찾으려고 폴더를 뒤질 필요가 없어요.",
          "가격은 0원, Intel·Apple Silicon 모든 Mac 지원.",
          "Apple 인증 완료로 설치 경고 없이 실행, 새 버전은 알아서 업데이트.",
        ],
      },
    ],
    infoMore: "자세한 변경 내역은 GitHub에서 —",
    infoMoreLinkPizza: "피자클립",
    infoMoreLinkPickle: "피클",
    relMoreBold: "피클은 이제 막 1.0으로 출발했어요.",
    relMoreRest: "새 소식이 쌓이면 여기에 담을게요 — 피클 둘러보기 →",
    teamTitle: "Team jAm",
    teamTagline: "“모든 것은 장난스러운 상상에서 시작된다.”",
    teamBody1Html: `<span class="brand">PIZZA&nbsp;CLIP</span> 과 <span class="brand">PICkle</span> 을 만든 '<strong>Team&nbsp;jAm</strong>'은 jae_keun과 min_gyeol, 두 사람이 가벼운 상상을 현실로 옮기며 시작한 작은 프로젝트 팀입니다.`,
    teamBody2: "우리가 필요해서 만들었고, 만드는 과정 자체가 즐거워서 오늘도 기분 좋은 상상을 더해가며 계속 만들고 있습니다.",
    teamSignQuote: "“It all starts with a playful imagination.”",
    appbtnPizza: "피자클립 보러가기 →",
    appbtnPickle: "피클 보러가기 →",
    metaTitle: "Info",
    metaDescription:
      "PIZZA CLIP 과 PICkle 의 버전 기록과 만드는 사람들(Team JAM) 소개. 두 macOS 메뉴바 앱의 릴리스노트를 한곳에서.",
  },
  en: {
    headH1: "Info",
    headSub: "Version history for both apps — and the people behind them.",
    relHeadingSuffix: "Release Notes",
    releases: [
      {
        version: "1.1.0",
        label: "Lock the Popup · Pin Several at Once",
        notes: [
          "There’s a lock button at the top of the popup now — lock it and the popup stays open even when you click elsewhere.",
          "Pin several items at once with ⌘P — they land in spots 1, 2, 3 in the order you pinned them.",
          "A count badge and a close button up top make the popup easy to read at a glance.",
          "Made the right-⌘ 한/영 toggle more reliable.",
          "Check what’s new in each version right from the update window.",
        ],
      },
      {
        version: "1.0.0",
        label: "Official Launch 🎉",
        notes: [
          "Stacks the text, images, and files you copy neatly in the menu bar.",
          "Paste any item instantly with a single shortcut.",
          "The more your history grows, the more your menu-bar pizza fills out — one slice at a time.",
          "Apple-notarized, so it runs clean with no install warnings.",
          "Updates itself whenever a new version lands.",
        ],
      },
      { version: "0.1.7", label: "Auto-Update Arrives", notes: ["The app now checks for the latest version and pulls it down on its own."] },
      {
        version: "0.1.6",
        label: "Apple Notarization + 🍕 ‘Pizza’ Surprise",
        notes: [
          "Apple developer notarization is in, so the security warning on install is gone.",
          "Copy ‘pizza’ (or ‘피자’) and watch pizzas burst across your screen.",
        ],
      },
      { version: "0.1.5", label: "한/영 Toggle Added", notes: ["Switch Korean ↔ English with one tap of the right ⌘ key — toggle it on or off."] },
      { version: "0.1.4", label: "🍕 Easter Egg", notes: ["Copy ‘pizza’ and a pizza pops up with a little surprise animation."] },
      { version: "0.1.3", label: "New App Icon · Renamed to pizzaClip", notes: ["Gave the app icon and the menu-bar pizza a fresh new look."] },
      { version: "0.1.1", label: "First Release", notes: ["The essentials are in: auto copy-history, the popup, pinning, and clear-all."] },
    ],
    pickleReleases: [
      {
        version: "1.0.0",
        label: "Official Launch 🥒",
        notes: [
          "Take a screenshot and it’s auto-saved, neatly tucked into a ‘pickle jar’ folder in your Documents.",
          "Preview recent captures right from the menu-bar icon, and drag one anywhere to drop it in.",
          "No more digging through folders for that lost capture.",
          "Free, and it runs on every Mac — Intel and Apple Silicon.",
          "Apple-notarized, so it runs with no install warnings, and new versions update themselves.",
        ],
      },
    ],
    infoMore: "For the full change log, head to GitHub —",
    infoMoreLinkPizza: "PizzaClip",
    infoMoreLinkPickle: "PICkle",
    relMoreBold: "PICkle just launched at 1.0.",
    relMoreRest: "As the news piles up, we’ll jar it right here — take a look around PICkle →",
    teamTitle: "Team jAm",
    teamTagline: "“It all starts with a playful imagination.”",
    teamBody1Html: `Team jAm — the makers of <span class="brand">PIZZA&nbsp;CLIP</span> and <span class="brand">PICkle</span> — is a tiny project team started by jae_keun and min_gyeol, two people turning light little ideas into real things.`,
    teamBody2: "We built these because we wanted them ourselves, and because making them is just plain fun. So we keep going, adding a few more feel-good ideas every day.",
    teamSignQuote: "“모든 것은 장난스러운 상상에서 시작된다.”",
    appbtnPizza: "See PizzaClip →",
    appbtnPickle: "See PICkle →",
    metaTitle: "Info",
    metaDescription:
      "Release notes for PIZZA CLIP and PICkle, two macOS menu-bar apps — plus the story of Team JAM, the two-person crew turning playful ideas into real Mac apps.",
  },
};
