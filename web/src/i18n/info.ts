/** 정보(/info) 페이지 콘텐츠 — 한국어/영문. 마크업·스타일은 components/pages/InfoPage.astro. */
import type { Lang } from "./ui.ts";

export type Release = { version: string; label: string; notes: string[] };

export type InfoContent = {
  headH1: string;
  headSub: string;
  relHeadingSuffix: string; // "릴리스노트" / "Release Notes"
  releases: Release[]; // 피자클립
  pickleReleases: Release[];
  hotsauceReleases: Release[];
  infoMore: string;
  infoMoreLinkPizza: string;
  infoMoreLinkPickle: string;
  teamTitle: string;
  teamTagline: string; // 해당 언어 문구(이탤릭)
  teamBody1Html: string; // brand 스팬 포함 HTML
  teamBody2: string;
  teamSignQuote: string; // 반대 언어 문구(서명 위치)
  appbtnPizza: string;
  appbtnPickle: string;
  appbtnHotsauce: string;
  metaTitle: string;
  metaDescription: string;
};

export const info: Record<Lang, InfoContent> = {
  ko: {
    headH1: "Info · 정보",
    headSub: "세 앱의 버전 기록과 만드는 사람들을 소개합니다.",
    relHeadingSuffix: "릴리스노트",
    releases: [
      {
        version: "1.3.1",
        label: "설정창 정리 · 자동 업데이트 옵션",
        notes: [
          "설정 일반 탭을 형제 앱(피클·핫소스)과 같은 모양으로 통일했어요.",
          "업데이트를 자동으로 받는 옵션과 ‘지금 업데이트 확인’ 버튼을 더했어요.",
          "기록 개수 설정은 저장공간 탭으로 옮겼어요.",
        ],
      },
      {
        version: "1.3.0",
        label: "새 아이콘 · 더 먹음직한 피자 폭죽 🍕",
        notes: [
          "‘I’m a PizzaClip’ 스티커가 붙은 산뜻한 새 앱 아이콘으로 바뀌었어요.",
          "기록이 가득 찼을 때 보이는 메뉴바 아이콘도 새 ‘피자 박스’ 그림으로 단장했어요.",
          "‘pizza’·‘피자’를 복사하면 터지는 피자 폭죽이, 이모지 대신 통통한 피자 그림으로 더 크고 먹음직스러워졌어요.",
        ],
      },
      {
        version: "1.2.0",
        label: "한국어 지원 · 개인정보 설정 간편화",
        notes: [
          "이제 앱을 한국어로 쓸 수 있어요 — 설정 → 일반 → 언어에서 시스템·English·한국어 중 선택.",
          "‘기록하지 않을 앱’을 앱 아이콘과 이름으로 보면서 ‘앱 추가…’ 버튼으로 손쉽게 골라 넣어요(복잡한 식별자 입력은 이제 끝).",
          "자물쇠를 잠그고 붙여넣으면 포커스가 팝업으로 돌아와, 숫자키·클릭으로 여러 개를 쭉쭉 붙여넣기 좋아졌어요.",
        ],
      },
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
        version: "1.3.3",
        label: "저장 용량 버그 수정 · 편집기 확대/축소 🥒",
        notes: [
          "사진에 워터마크만 넣고 저장해도 파일이 몇 배로 커지던 문제를 고쳤어요 — 이제 원본 포맷과 용량을 그대로 유지해요.",
          "편집 중 사진을 최대 8배까지 확대할 수 있어요. 트랙패드 핀치와 ⌘+ / ⌘− / ⌘0(맞춤)으로 조절해요.",
          "블러 도구가 고해상도 사진에서도 버벅임 없이 부드럽게 칠해져요.",
          "설정 일반 탭을 형제 앱(피자클립·핫소스)과 같은 모양으로 통일하고, 자동 업데이트 옵션을 더했어요.",
        ],
      },
      {
        version: "1.3.2",
        label: "저장 폴더 바로가기 · 매끄러운 자동 업데이트 🥒",
        notes: [
          "보관함 팝업 아래에 저장 폴더 경로가 보여요 — 누르면 ‘PICkle bottle’ 폴더가 Finder에서 바로 열려요.",
          "새 버전이 나오면 백그라운드에서 알아서 받아 조용히 업데이트돼요 — 이제 직접 확인하지 않아도 최신 상태로 유지돼요.",
        ],
      },
      {
        version: "1.3.1",
        label: "더 가볍고 조용하게 ⚡",
        notes: [
          "편집 창을 열어두기만 해도 CPU 사용량이 계속 높던 문제를 고쳤어요 — 이제 편집 중에도 팬 소음이나 배터리 걱정 없이 조용해요.",
        ],
      },
      {
        version: "1.3.0",
        label: "열린 메뉴도 그대로 캡처 📸",
        notes: [
          "이제 메뉴나 팝업을 펼친 상태 그대로 캡처할 수 있어요 — 캡처를 시작해도 열려 있던 메뉴가 닫히지 않아요.",
          "캡처를 macOS 기본 방식으로 바꿔서, 드래그 중 픽셀 크기 표시와 스페이스로 영역 옮기기도 자연스럽게 돼요.",
          "화면 깜빡임 없이 매끄럽게 찍혀요.",
        ],
      },
      {
        version: "1.2.0",
        label: "또렷한 십자선 · 방해 없는 캡처 🥒",
        notes: [
          "캡처를 시작하면 마우스에 십자선이 항상 또렷하게 따라와요.",
          "전체화면으로 보던 사진·영상이 캡처를 시작해도 닫히지 않아요.",
          "보관함 썸네일의 🍕 버튼으로 이미지를 바로 클립보드에 복사 — PizzaClip이 깔려 있으면 그쪽으로 이어붙여요.",
          "설정 일반 탭에 버전·빌드 번호를 표시해요.",
        ],
      },
      {
        version: "1.1.0",
        label: "펜 색상, 마음대로 🎨",
        notes: [
          "펜 색을 고를 때 무지개 버튼을 누르면 그 자리에서 색상 피커가 열려요.",
          "채도·명도 사각형과 색조 바를 움직여 원하는 색을 직접 만들 수 있어요.",
          "스포이드로 화면 어디든 클릭하면 그 픽셀의 색을 펜 색으로 쏙 뽑아와요.",
          "색상 코드(#RRGGBB)를 보여주고, 누르면 클립보드로 바로 복사돼요.",
          "작은 편집 창에서도 도구 옵션 팝업이 잘리지 않게 다듬었어요.",
        ],
      },
      {
        version: "1.0.0",
        label: "정식 출시 🥒",
        notes: [
          "단축키 한 번으로 화면 영역을 슥 캡처 — 저장·편집·클립보드 복사 중에 골라서.",
          "찍은 자리에서 바로 편집 — 펜·블러(모자이크)·워터마크(글자+로고)·자르기, ⌘Z 되돌리기까지.",
          "캡처는 문서 속 ‘피클병’ 폴더에 자동으로 차곡차곡, 메뉴바에서 미리보고 드래그 한 번으로 어디든 붙여넣기.",
          "정해둔 기간이 지난 캡처는 알아서 휴지통으로 정리 — 잃어버린 캡처 찾아 폴더 뒤질 일이 없어요.",
          "가격은 0원, Intel·Apple Silicon 모든 Mac 지원 · Apple 인증 완료로 경고 없이 실행, 새 버전은 알아서 업데이트.",
        ],
      },
    ],
    hotsauceReleases: [
      {
        version: "1.1.2",
        label: "위치 권한 없이 · 설정창 정리 🌶️",
        notes: [
          "첫 실행 때 뜨던 위치 권한 요청을 없앴어요 — 이제 위치 허용 팝업 없이 바로 쓸 수 있어요.",
          "설정 일반 탭을 형제 앱(피자클립·피클)과 같은 모양으로 통일하고, 업데이트 자동 다운로드 옵션과 ‘지금 업데이트 확인’ 버튼을 더했어요.",
        ],
      },
      {
        version: "1.1.1",
        label: "잠금 버튼 · 자잘한 다듬기",
        notes: [
          "팝업의 자물쇠 버튼이 제대로 눌리도록 고쳤어요.",
          "타이틀 글씨와 몇몇 배치를 형제 앱과 맞춰 다듬었어요.",
        ],
      },
      {
        version: "1.1.0",
        label: "팝업 잠금 · 충전 아이콘 · 깜짝 폭발",
        notes: [
          "팝업 상단에 자물쇠 버튼이 생겼어요 — 잠그면 다른 곳을 눌러도 팝업이 닫히지 않아요.",
          "충전 중일 때 배터리 아이콘이 플러그 모양으로 바뀌어요.",
          "시스템이 아주 바쁠 때 핫소스 병이 팡 터지는 깜짝 연출을 넣었어요.",
          "새 버전을 백그라운드에서 알아서 받아 조용히 업데이트해요.",
        ],
      },
      {
        version: "1.0.0",
        label: "정식 출시 🌶️",
        notes: [
          "메뉴바 핫소스 병 아이콘으로 CPU·메모리·배터리·디스크·네트워크를 한눈에.",
          "부하에 따라 병 색이 바뀌어요 — 쾌적할 땐 빨강, 바쁠 땐 노랑, 아주 뜨거우면 레인보우.",
          "팝업에서 CPU·메모리·저장용량·배터리·네트워크 5개 섹션을 상세히 확인.",
          "Apple 인증 완료로 경고 없이 실행, 새 버전은 알아서 업데이트.",
          "가격은 0원, Intel·Apple Silicon 모든 Mac 지원 · 100% 로컬.",
        ],
      },
    ],
    infoMore: "자세한 변경 내역은 GitHub에서 —",
    infoMoreLinkPizza: "피자클립",
    infoMoreLinkPickle: "피클",
    teamTitle: "Team jAm",
    teamTagline: "“모든 것은 장난스러운 상상에서 시작된다.”",
    teamBody1Html: `<span class="brand">PIZZA&nbsp;CLIP</span>, <span class="brand">PICkle</span>, <span class="brand">Hot&nbsp;Sauce</span> 를 만든 '<strong>Team&nbsp;jAm</strong>'은 jae_keun과 min_gyeol, 두 사람이 가벼운 상상을 현실로 옮기며 시작한 작은 프로젝트 팀입니다.`,
    teamBody2: "우리가 필요해서 만들었고, 만드는 과정 자체가 즐거워서 오늘도 기분 좋은 상상을 더해가며 계속 만들고 있습니다.",
    teamSignQuote: "“It all starts with a playful imagination.”",
    appbtnPizza: "피자클립 보러가기 →",
    appbtnPickle: "피클 보러가기 →",
    appbtnHotsauce: "핫소스 보러가기 →",
    metaTitle: "Info",
    metaDescription:
      "PIZZA CLIP · PICkle · Hot Sauce 의 버전 기록과 만드는 사람들(Team JAM) 소개. 세 macOS 메뉴바 앱의 릴리스노트를 한곳에서.",
  },
  en: {
    headH1: "Info",
    headSub: "Version history for all three apps — and the people behind them.",
    relHeadingSuffix: "Release Notes",
    releases: [
      {
        version: "1.3.1",
        label: "Tidied-Up Settings · Auto-Update Option",
        notes: [
          "The Settings → General tab now matches its sibling apps (PICkle and HotSauce).",
          "Added an option to download updates automatically, plus a ‘Check for Updates’ button.",
          "Moved the history-count setting to the Storage tab.",
        ],
      },
      {
        version: "1.3.0",
        label: "New Icon · Tastier Pizza Burst 🍕",
        notes: [
          "A fresh new app icon with an ‘I’m a PizzaClip’ sticker.",
          "The menu-bar icon you see when your history is full got a makeover too — a new ‘pizza box’ look.",
          "Copy ‘pizza’ (or ‘피자’) and the burst is now a plump pizza illustration instead of an emoji — bigger, tastier, and bouncing at all sorts of heights.",
        ],
      },
      {
        version: "1.2.0",
        label: "Korean Support · Easier Privacy Setup",
        notes: [
          "You can now use the app in Korean — Settings → General → Language, then pick System, English, or Korean.",
          "Add apps to your ‘don’t record’ list by icon and name with an ‘Add App…’ button — no more typing cryptic identifiers.",
          "Lock the popup and paste, and focus returns to the popup — rattle off several items with number keys or clicks.",
        ],
      },
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
        version: "1.3.3",
        label: "Save-Size Fix · Zoom in the Editor 🥒",
        notes: [
          "Fixed a bug where adding just a watermark ballooned the file size — it now keeps the original format and size.",
          "Zoom into a photo up to 8× while editing — pinch on the trackpad or use ⌘+ / ⌘− / ⌘0 (fit).",
          "The blur tool now paints smoothly even on high-resolution photos.",
          "The Settings → General tab now matches its sibling apps (PizzaClip and HotSauce), with an auto-update option added.",
        ],
      },
      {
        version: "1.3.2",
        label: "Quick Jump to Your Folder · Smoother Auto-Update 🥒",
        notes: [
          "Your bottle folder path now shows at the bottom of the popup — click it to open the ‘PICkle bottle’ folder in Finder.",
          "New versions now download in the background and install themselves quietly — you stay on the latest without ever checking manually.",
        ],
      },
      {
        version: "1.3.1",
        label: "Lighter, Quieter Editing ⚡",
        notes: [
          "Fixed a bug where just having the editor open kept the CPU busy — editing is now quiet and easy on your battery.",
        ],
      },
      {
        version: "1.3.0",
        label: "Capture Open Menus, As-Is 📸",
        notes: [
          "You can now capture a menu or popup while it’s open — starting a capture no longer dismisses whatever menu was showing.",
          "Capture now uses the native macOS flow, so live pixel dimensions and Space-to-move come built in.",
          "Captures come out smooth, with no screen flicker.",
        ],
      },
      {
        version: "1.2.0",
        label: "Crisp Crosshair · Distraction-Free Capture 🥒",
        notes: [
          "A crosshair follows your mouse, sharp and steady, the moment you start a capture.",
          "Full-screen photos and videos you were viewing stay open when you begin a capture.",
          "The 🍕 button on a stored thumbnail copies the image straight to the clipboard — and hands off to PizzaClip if it’s installed.",
          "Settings → General now shows the version and build number.",
        ],
      },
      {
        version: "1.1.0",
        label: "Pen Colors, Your Way 🎨",
        notes: [
          "Hit the rainbow button while picking a pen color and a full color picker opens right there.",
          "Drag the saturation/brightness square and the hue bar to mix any color you want.",
          "Use the eyedropper to click anywhere on screen and lift that pixel’s color into your pen.",
          "Shows the hex code (#RRGGBB) — click it to copy straight to your clipboard.",
          "Tidied things up so the tool-option popup no longer gets clipped in a small editor window.",
        ],
      },
      {
        version: "1.0.0",
        label: "Official Launch 🥒",
        notes: [
          "Grab any area of the screen with a single shortcut — save it, edit it, or copy it to the clipboard.",
          "Edit right where you captured — pen, blur/mosaic, watermark (text + logo), crop, and ⌘Z to undo.",
          "Captures auto-save into a ‘pickle jar’ folder in your Documents; preview from the menu bar and drag one anywhere to drop it in.",
          "Captures past the age you set tidy themselves into the Trash — no more digging through folders for a lost one.",
          "Free, runs on every Mac (Intel + Apple Silicon), Apple-notarized so it opens with no warnings, and it updates itself.",
        ],
      },
    ],
    hotsauceReleases: [
      {
        version: "1.1.2",
        label: "No Location Prompt · Tidied-Up Settings 🌶️",
        notes: [
          "Removed the location-permission request that popped up on first launch — HotSauce now starts with no location prompt.",
          "The Settings → General tab now matches its sibling apps (PizzaClip and PICkle), with an auto-download update option and a ‘Check for Updates’ button.",
        ],
      },
      {
        version: "1.1.1",
        label: "Lock Button · Small Polish",
        notes: [
          "Fixed the lock button in the popup so it clicks reliably.",
          "Tuned the title text and a few positions to match the sibling apps.",
        ],
      },
      {
        version: "1.1.0",
        label: "Lock the Popup · Charging Icon · Surprise Burst",
        notes: [
          "A lock button at the top of the popup — lock it and it stays open when you click elsewhere.",
          "The battery icon switches to a plug shape while charging.",
          "A little ‘burst’ surprise when your system gets really busy.",
          "Downloads new versions in the background and updates quietly.",
        ],
      },
      {
        version: "1.0.0",
        label: "Official Launch 🌶️",
        notes: [
          "See CPU, memory, battery, disk, and network at a glance from a menu-bar hot-sauce bottle.",
          "The bottle changes color with load — red when idle, yellow when busy, rainbow when it’s really hot.",
          "A popup with five detailed sections: CPU, memory, storage, battery, and network.",
          "Apple-notarized so it opens with no warnings, and it updates itself.",
          "Free, runs on every Mac (Intel + Apple Silicon), 100% on-device.",
        ],
      },
    ],
    infoMore: "For the full change log, head to GitHub —",
    infoMoreLinkPizza: "PizzaClip",
    infoMoreLinkPickle: "PICkle",
    teamTitle: "Team jAm",
    teamTagline: "“It all starts with a playful imagination.”",
    teamBody1Html: `Team jAm — the makers of <span class="brand">PIZZA&nbsp;CLIP</span>, <span class="brand">PICkle</span>, and <span class="brand">Hot&nbsp;Sauce</span> — is a tiny project team started by jae_keun and min_gyeol, two people turning light little ideas into real things.`,
    teamBody2: "We built these because we wanted them ourselves, and because making them is just plain fun. So we keep going, adding a few more feel-good ideas every day.",
    teamSignQuote: "“모든 것은 장난스러운 상상에서 시작된다.”",
    appbtnPizza: "See PizzaClip →",
    appbtnPickle: "See PICkle →",
    appbtnHotsauce: "See Hot Sauce →",
    metaTitle: "Info",
    metaDescription:
      "Release notes for PIZZA CLIP, PICkle, and Hot Sauce — three macOS menu-bar apps — plus the story of Team JAM, the two-person crew turning playful ideas into real Mac apps.",
  },
};
