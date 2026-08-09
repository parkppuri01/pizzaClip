/**
 * 개인정보처리방침(/privacy) 본문 — 한/영.
 *
 * ⚠️ 이 문서는 실제 코드 동작과 1:1로 맞춰 쓴 것이다. 아래를 바꾸면 이 문서도 고쳐야 한다:
 *   - `middleware.js` 의 노크 수집(real/ver/uniq/geo 키, 400일 TTL, IP 해시 방식)
 *   - `middleware.js` 의 언어 자동분기 쿠키(pclang, 1년)
 *   - 각 앱의 네트워크 사용 (현재 세 앱 모두 Sparkle 업데이트 확인 외 통신 없음)
 *
 * App Store Connect 는 개인정보처리방침 URL 을 필수로 요구한다 → https://pizza-clip.com/privacy
 */
import type { Lang } from "./ui.ts";

export type PrivacySection = {
  h: string;
  /** 섹션 맨 위에 눈에 띄게 박스로 뜨는 단서. 제목만 보고 오해할 수 있는 섹션에 쓴다. */
  note?: string;
  /** 문단들. HTML 을 넣지 말 것 (그대로 텍스트로 렌더된다) */
  body?: string[];
  bullets?: string[];
};

export type PrivacyContent = {
  metaTitle: string;
  metaDescription: string;
  headH1: string;
  headSub: string;
  updatedLabel: string;
  updatedDate: string;
  tldrH: string;
  tldr: string;
  sections: PrivacySection[];
  contactH: string;
  contactBody: string;
};

/** 방침을 실제로 고친 날. 문구만 다듬을 땐 굳이 바꾸지 않는다. */
const UPDATED = "2026-08-06";

export const privacy: Record<Lang, PrivacyContent> = {
  ko: {
    metaTitle: "개인정보처리방침",
    metaDescription:
      "Team JAM 의 macOS 앱(피자클립·피클·핫소스)과 pizza-clip.com 이 어떤 정보를 다루는지 — 그리고 다루지 않는지.",
    headH1: "개인정보처리방침",
    headSub: "Team JAM · 피자클립 · 피클 · 핫소스 · pizza-clip.com",
    updatedLabel: "최종 수정",
    updatedDate: UPDATED,
    tldrH: "한 줄 요약",
    tldr:
      "세 앱 모두 개인정보를 수집하지 않습니다. 앱이 다루는 데이터는 전부 사용자의 Mac 안에만 있고, 외부로 나가지 않습니다.",
    sections: [
      {
        h: "1. 앱이 수집하는 개인정보 — 없음",
        body: [
          "피자클립·피클·핫소스는 계정도 로그인도 없습니다. 광고 SDK 나 분석 SDK 를 넣지 않았고, 사용자를 식별하는 어떤 값도 만들지 않습니다.",
          "각 앱이 다루는 데이터는 다음과 같이 전부 기기 안에 머무릅니다.",
        ],
        bullets: [
          "핫소스 — CPU·메모리·저장 용량·배터리·네트워크 지표를 읽어 화면에 표시만 합니다. 어디로도 전송하지 않습니다.",
          "피자클립 — 복사한 클립보드 기록은 사용자의 Mac 안에만 저장됩니다.",
          "피클 — 캡처한 스크린샷과 이미지는 사용자의 Mac 안에만 저장됩니다.",
        ],
      },
      {
        h: "2. 업데이트 확인 시 서버에 남는 기록 (직접 다운로드 버전만 해당)",
        note:
          "Mac App Store 에서 설치한 버전에는 이 항목이 전혀 해당되지 않습니다. App Store 가 업데이트를 담당하므로, 앱이 저희 서버로 어떤 요청도 보내지 않습니다.",
        body: [
          "pizza-clip.com 에서 직접 내려받은 버전은 하루 한 번 새 버전이 있는지 확인하는 요청을 보냅니다. 이때 저희 서버에는 다음 통계만 남습니다.",
        ],
        bullets: [
          "앱 버전 — 어느 버전을 쓰는지 (요청에 이미 담겨 오는 값)",
          "접속 국가 — IP 로 추정한 국가 코드. 나라 단위이며 위치 권한을 쓰지 않습니다.",
          "중복 제거용 해시 — 같은 기기를 두 번 세지 않으려고 IP 를 매달 바뀌는 비밀값과 섞어 되돌릴 수 없는 형태로 변환한 값. IP 원문은 저장하지 않습니다.",
        ],
      },
      {
        h: "2-1. 그 기록으로 하는 일 · 안 하는 일",
        bullets: [
          "합니다 — “며칠에 대략 몇 명이 쓰는지” 총계 파악. 개발 우선순위를 정하는 데만 씁니다.",
          "안 합니다 — 개인 식별, 행동 추적, 프로파일링, 광고, 제3자 판매·공유.",
          "이 기록은 400일이 지나면 자동으로 삭제됩니다.",
          "Mac App Store 에서 설치한 버전은 업데이트를 App Store 가 담당하므로, 이 요청 자체가 발생하지 않습니다. 즉 저희 서버에 아무 기록도 남지 않습니다.",
        ],
      },
      {
        h: "3. 웹사이트(pizza-clip.com)",
        bullets: [
          "쿠키는 언어 선택을 기억하는 pclang 하나뿐이며 1년간 보관됩니다. 광고·추적 쿠키는 없습니다.",
          "처음 방문 시 IP 로 추정한 국가에 따라 한국어/영문 페이지로 한 번 자동 이동합니다. 이때 쓰는 국가 값은 이동 여부를 판단하는 데만 쓰고 저장하지 않습니다.",
          "사이트는 Vercel 에 호스팅되어 있어, 일반적인 웹 서버 접속 로그가 Vercel 측에 남을 수 있습니다.",
        ],
      },
      {
        h: "4. 제3자 제공",
        body: [
          "수집한 통계를 판매하거나 외부에 공유하지 않습니다. 저희가 쓰는 외부 서비스는 사이트 호스팅(Vercel)과 통계 저장소뿐이며, 어느 쪽에도 개인을 식별할 수 있는 정보를 넘기지 않습니다.",
          "Mac App Store 를 통한 설치·업데이트에 대해서는 Apple 이 자체적으로 통계를 제공하지만, 저희는 그 안에서 개인을 특정할 수 없습니다.",
        ],
      },
      {
        h: "5. 아동의 개인정보",
        body: [
          "만 14세 미만 아동의 개인정보를 의도적으로 수집하지 않습니다. 애초에 어떤 이용자의 개인정보도 수집하지 않습니다.",
        ],
      },
      {
        h: "6. 이용자의 권리",
        body: [
          "저희는 개인을 식별할 수 있는 정보를 보관하지 않으므로, 열람·정정·삭제를 요청할 대상 데이터가 존재하지 않습니다. 그럼에도 확인하고 싶은 점이 있으면 언제든 문의해 주세요.",
        ],
      },
      {
        h: "7. 방침 변경",
        body: [
          "이 방침이 바뀌면 이 페이지를 갱신하고 상단의 최종 수정일을 함께 바꿉니다.",
        ],
      },
    ],
    contactH: "문의",
    contactBody:
      "개인정보 처리에 대해 궁금한 점이 있으면 아래로 연락해 주세요.",
  },

  en: {
    metaTitle: "Privacy Policy",
    metaDescription:
      "What Team JAM's macOS apps (PizzaClip, PICkle, Hot Sauce) and pizza-clip.com do — and don't do — with your data.",
    headH1: "Privacy Policy",
    headSub: "Team JAM · PizzaClip · PICkle · Hot Sauce · pizza-clip.com",
    updatedLabel: "Last updated",
    updatedDate: UPDATED,
    tldrH: "In short",
    tldr:
      "None of our apps collect personal information. Everything the apps handle stays on your Mac and never leaves it.",
    sections: [
      {
        h: "1. What the apps collect — nothing",
        body: [
          "PizzaClip, PICkle, and Hot Sauce have no accounts and no sign-in. They contain no advertising or analytics SDKs, and they never generate any identifier for you.",
          "Everything each app works with stays on your device:",
        ],
        bullets: [
          "Hot Sauce — reads CPU, memory, storage, battery, and network figures purely to display them. Nothing is transmitted anywhere.",
          "PizzaClip — your clipboard history is stored only on your Mac.",
          "PICkle — your screenshots and images are stored only on your Mac.",
        ],
      },
      {
        h: "2. What our server records during update checks (direct downloads only)",
        note:
          "None of this applies to copies installed from the Mac App Store. The App Store handles updates there, so the app never sends any request to our server.",
        body: [
          "Copies downloaded directly from pizza-clip.com check once a day whether a new version exists. That request leaves only the following aggregate data on our server:",
        ],
        bullets: [
          "App version — which version you are running (already part of the request).",
          "Country — inferred from your IP address, at country granularity. No location permission is involved.",
          "A de-duplication hash — so one device isn't counted twice. Your IP is combined with a secret that rotates monthly and converted into an irreversible value. We never store the raw IP.",
        ],
      },
      {
        h: "2-1. What we do — and don't do — with it",
        bullets: [
          "We do — get a rough count of how many people use the apps on a given day, purely to prioritise development.",
          "We don't — identify individuals, track behaviour, build profiles, advertise, or sell/share data with third parties.",
          "These records are deleted automatically after 400 days.",
          "Copies installed from the Mac App Store never send this request at all, because the App Store handles updates. Nothing reaches our server.",
        ],
      },
      {
        h: "3. The website (pizza-clip.com)",
        bullets: [
          "The only cookie is pclang, which remembers your language choice for one year. There are no advertising or tracking cookies.",
          "On a first visit we may redirect you once to the Korean or English version based on the country inferred from your IP. That country value is used only to decide the redirect and is not stored.",
          "The site is hosted on Vercel, so ordinary web server access logs may exist on Vercel's side.",
        ],
      },
      {
        h: "4. Third parties",
        body: [
          "We do not sell or share the statistics we collect. The only external services we use are site hosting (Vercel) and the statistics store, and neither receives information that identifies an individual.",
          "For installs and updates through the Mac App Store, Apple provides its own aggregate reporting — within which we cannot identify any individual.",
        ],
      },
      {
        h: "5. Children's privacy",
        body: [
          "We do not knowingly collect personal information from children. In fact, we do not collect personal information from any user.",
        ],
      },
      {
        h: "6. Your rights",
        body: [
          "Because we hold no information that identifies you, there is no personal data to access, correct, or delete. If you would like to verify anything, please get in touch.",
        ],
      },
      {
        h: "7. Changes to this policy",
        body: [
          "If this policy changes, we will update this page along with the last-updated date shown above.",
        ],
      },
    ],
    contactH: "Contact",
    contactBody: "If you have any questions about privacy, please reach out:",
  },
};
