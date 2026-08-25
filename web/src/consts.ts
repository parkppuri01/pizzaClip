/** 사이트 전역 상수 — 한 곳에서 관리 */

// 최신 릴리스 DMG 바로 다운로드. 고정 파일명(pizzaClip.dmg)이라 버전이 올라가도
// 항상 최신 릴리스를 가리킴 — release.sh 가 매 릴리스마다 이 이름으로도 업로드한다.
export const DOWNLOAD_URL =
  "https://github.com/parkppuri01/pizzaClip/releases/latest/download/pizzaClip.dmg";

export const GITHUB_URL = "https://github.com/parkppuri01/pizzaClip";

// Team JAM 소셜 계정 (두 제품 공통)
export const INSTAGRAM_URL = "https://www.instagram.com/team___jam/";
export const THREADS_URL = "https://www.threads.com/@team___jam";

// 지원·문의 메일 — /privacy 페이지와 App Store Connect 의 지원 연락처에 쓰인다.
// ⚠️ 공개 페이지에 그대로 노출되는 주소다. 개인 메일 대신 별도 문의용 주소를 쓰려면
//    여기만 바꾸면 전 페이지에 반영된다.
export const SUPPORT_EMAIL = "jekeun.p@gmail.com";

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
export const PICKLE_DOWNLOAD_URL = "/pickle/PICkle-1.4.0.dmg";
export const PICKLE_TITLE = "PICkle";
export const PICKLE_DESC =
  "캡처한 건 다 보관해주는 macOS 스크린샷 정리 앱. 찍는 즉시 ‘피클병’ 폴더에 차곡차곡.";

// ── 핫소스(Hot Sauce) ──
// 모노레포(pizzaClip) 안에만 존재 — 전용 저장소가 없어 GitHub 은 모노레포로 링크.
export const HOTSAUCE_GITHUB_URL = "https://github.com/parkppuri01/pizzaClip";

// 🍎 2026-08-25 Mac App Store 출시 → 배포는 App Store 로 일원화했다.
// 스토어 이름은 "HotSauce - System Monitor" (Apple ID 6801170433).
//
// ⚠️ 국가 코드를 명시하는 이유: 미국·한국 2개국에만 출시했다. 국가 없는 주소
//    (apps.apple.com/app/id…)는 접속 지역으로 자동 분기하는데, 미출시 지역에서는
//    "사용할 수 없음"이 뜬다. 언어별로 실제 출시 국가를 가리키게 둔다.
// ⚠️ mt=12 는 Mac App Store 지정 — 빼면 iOS App Store 로 해석될 수 있다.
export const HOTSAUCE_APPSTORE_URL: Record<"ko" | "en", string> = {
  ko: "https://apps.apple.com/kr/app/hotsauce/id6801170433?mt=12",
  en: "https://apps.apple.com/us/app/hotsauce/id6801170433?mt=12",
};

export const HOTSAUCE_RELEASED = true;
// 🗄 직접배포(DMG) 채널은 1.3.0 을 끝으로 마감했다 — 페이지 어디에도 링크하지 않는다.
//
// 그래도 상수와 파일을 지우지 않는 이유: web/public/hotsauce/appcast.xml 의
// enclosure 가 이 DMG 를 가리킨다. 파일을 내리면 아직 구버전을 쓰는 사용자의
// Sparkle 업데이트 확인이 404 로 실패해 "마지막 안내"조차 못 받게 된다.
// 앱 안 이전 안내(AppStoreMigration)가 충분히 돌 때까지는 그대로 둔다.
export const HOTSAUCE_LAST_DMG_URL = "/hotsauce/HotSauce-1.3.0.dmg";
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
