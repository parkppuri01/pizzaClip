# PIZZA CLIP — 웹사이트 디자인 명세 (Web Design Spec)

> `web/guide/design.png` (디자인 시스템 가이드) + `web/guide/pizza web.png` (랜딩 목업)을 분석해
> **랜딩/가이드/블로그 사이트(`web/`, Astro)** 제작에 바로 쓸 수 있도록 정리한 문서.
> 이 문서가 사이트 디자인의 **단일 진실 소스(SSOT)** 입니다. 토큰 값이 헷갈리면 여기를 따릅니다.

---

## 0. 톤 & 무드

- **컨셉**: 피자 가게의 따뜻함 + 레트로 광고판 감성. 장난스럽고(playful) 친근한 톤.
- **분위기 키워드**: 크림빛 종이 배경 · 피자 옐로우 카드 · 벽돌빛 빨강 포인트 · 굵고 또렷한 영문 타이포.
- **브랜드 모티프**: **피자 조각이 한 조각씩 늘어나는** 일러스트 — 앱의 메뉴바 아이콘 단계(`PizzaIcon0~9`)와 동일한 언어. 사이트에서는 **섹션 구분/번호 표시**로 재사용.

---

## 1. 컬러 (Color Tokens)

가이드의 5색 팔레트. 역할 이름 그대로 CSS 변수로 박아두고 쓰면 됩니다.

| 역할 | HEX | 이름 | 용도 |
|---|---|---|---|
| 바탕색 | `#FCF6EF` | 크림 (cream) | 페이지 전체 배경 |
| 포인트 | `#A2371F` | 벽돌 빨강 (brick) | 1차 버튼, 강조 단어, 링크 hover |
| 메뉴 | `#FFB703` | 피자 옐로우 (amber) | 메뉴바, 카드 배경, 버튼 테두리 |
| 폰트 | `#102138` | 네이비 (navy) | 제목·헤딩 텍스트 |
| 폰트 | `#333333` | 차콜 (charcoal) | 본문 텍스트 |

```css
/* web/src/styles/tokens.css  (또는 global.css 상단) */
:root {
  --color-bg:      #FCF6EF; /* 크림 배경 */
  --color-point:   #A2371F; /* 벽돌 빨강 — 포인트 */
  --color-menu:    #FFB703; /* 피자 옐로우 — 메뉴/카드 */
  --color-ink:     #102138; /* 네이비 — 제목 */
  --color-text:    #333333; /* 차콜 — 본문 */

  /* 파생 토큰 (대비/표면용, 위 5색에서 안전하게 유도) */
  --color-surface: #FFFFFF; /* 화이트 카드 (마지막 다운로드 카드 등) */
  --color-on-menu: var(--color-ink);   /* 옐로우 위 글자 기본색 */
  --color-on-point:var(--color-menu);  /* 빨강 버튼 위 글자색 = 옐로우 */
}
```

### 색 조합 규칙 (대비)
- **옐로우(`--color-menu`) 위 글자** → 네이비(`#102138`) 또는 빨강(`#A2371F`). 흰색·연회색 금지(대비 부족).
- **빨강 버튼(`--color-point`) 위 글자** → **옐로우(`#FFB703`)** (가이드 1차 버튼이 이 조합).
- **크림 배경 위 본문** → 차콜(`#333333`), 제목은 네이비(`#102138`).

---

## 2. 타이포그래피 (Typography)

가이드 지정 서체. **한글/영문을 분리**해서 씁니다.

| 구분 | 서체 | 무게 | 용도 | 라이선스/조달 |
|---|---|---|---|---|
| 한글 본문 | **Pretendard** | Regular(400) / Bold(700) | 한글 본문·UI 전반 | 오픈소스(OFL). CDN·fontsource 가능 |
| 한글 강조/세리프 | **리디바탕 (RIDIBatang)** | Regular | 인용·감성 카피·블로그 제목 등 세리프가 어울리는 곳 | RIDI 무료배포(웹 사용 허용). 웹폰트 변환 필요 |
| 영문/숫자 | **OSP-DIN** | Regular / Bold | 로고·메뉴·버튼·헤드라인의 영문(`PIZZA CLIP`, `DOWNLOAD` 등) | 오픈소스(OSP, 무료) |

### 역할별 매핑
- **로고 / 메뉴바 영문 / 버튼 라벨**: OSP-DIN (대문자, 자간 살짝 넓게).
- **페이지 제목(H1·H2)**: 영문은 OSP-DIN Bold, 한글은 Pretendard Bold(또는 감성 섹션은 리디바탕).
- **본문(p)**: Pretendard Regular.
- **숫자·버전 표기(예: v0.1.7)**: OSP-DIN.

> ⚠️ **혼용 폴백**: 한 줄에 한글+영문이 섞이면 `font-family`에 영문 서체 → 한글 서체 순서로 나열해 글리프별로 자동 적용되게 합니다. (예: `font-family: "OSP-DIN", "Pretendard", sans-serif;`)

```css
:root {
  --font-en:     "OSP-DIN", "Pretendard", sans-serif;       /* 로고/메뉴/버튼/헤드라인 영문 */
  --font-sans:   "Pretendard", "OSP-DIN", system-ui, sans-serif; /* 한글 본문·UI */
  --font-serif:  "RIDIBatang", "Pretendard", serif;          /* 감성 카피·인용·블로그 제목 */
}

/* 타입 스케일 (제안 — 모바일 우선, clamp로 반응형) */
:root {
  --fs-h1:   clamp(2.2rem, 6vw, 4rem);
  --fs-h2:   clamp(1.6rem, 4vw, 2.4rem);
  --fs-h3:   clamp(1.2rem, 3vw, 1.5rem);
  --fs-body: 1rem;        /* 16px */
  --fs-small:0.875rem;    /* 14px */
  --lh-tight: 1.15;       /* 헤딩 */
  --lh-body:  1.6;        /* 본문 */
}
```

### 웹폰트 로딩 (Astro)
1. **Pretendard**: `@fontsource/pretendard` 설치 또는 jsDelivr CSS 링크.
   - CDN: `https://cdn.jsdelivr.net/gh/orioncactus/pretendard/dist/web/static/pretendard.css`
2. **OSP-DIN / 리디바탕**: 공식 배포본(.otf/.ttf)을 `.woff2`로 변환 → `web/public/fonts/`에 두고 `@font-face` 직접 선언.
   - 변환 도구: `fonttools`(`pip install fonttools[woff]`) 또는 온라인 변환기.
   - `font-display: swap;` 권장(폰트 늦게 떠도 텍스트 먼저 보이게).

```css
/* web/src/styles/fonts.css  — 로컬 폰트 예시 */
@font-face {
  font-family: "OSP-DIN";
  src: url("/fonts/osp-din.woff2") format("woff2");
  font-weight: 400 700;       /* DIN은 Regular/Bold 두 무게 사용 */
  font-display: swap;
}
@font-face {
  font-family: "RIDIBatang";
  src: url("/fonts/ridibatang.woff2") format("woff2");
  font-weight: 400;
  font-display: swap;
}
```

---

## 3. 컴포넌트 (Components)

### 3-1. 메뉴바 / 네비게이션 (Nav bar)
- **배경**: 피자 옐로우(`--color-menu`).
- **항목 배열(가이드)**: `PIZZA` `CLIP` `피자` `클립` — 영문/한글 두 벌. 실제 사이트는 메뉴 라벨로 치환(예: `HOME` `HOW TO` `BLOG`).
- **글자색 교차 규칙**: 홀수 항목 = 네이비(`#102138`), 짝수 항목 = 빨강(`#A2371F`). 가이드에서 `PIZZA`(네이비)·`CLIP`(빨강)·`피자`(네이비)·`클립`(빨강) 패턴.
- **영문 라벨**은 OSP-DIN 대문자, **한글 라벨**은 Pretendard.
- 목업(`pizza web.png`) 상단 바: 좌측 로고 `PIZZA CLIP`, 가운데 `HOW TO`, 우측 인포 아이콘 + `EXIT/DOWNLOAD` 버튼. 크림 배경 + 옐로우 밑줄.

```html
<!-- 구조 예시 -->
<nav class="navbar">
  <a class="nav-logo" href="/">PIZZA CLIP</a>
  <ul class="nav-links">
    <li><a class="is-ink"  href="/how-to">HOW TO</a></li>
    <li><a class="is-point" href="/blog">BLOG</a></li>
  </ul>
  <a class="btn btn--primary" href="#download">DOWNLOAD</a>
</nav>
```

### 3-2. 버튼 (Buttons) — 3종
모두 **알약(pill) 모양**(`border-radius: 999px`).

| 종류 | 배경 | 테두리 | 글자색 | 쓰임 |
|---|---|---|---|---|
| **Primary (채움)** | `#A2371F` | 없음 | `#FFB703` | 핵심 CTA (다운로드 등) |
| **Secondary (선)** | 투명 | `#FFB703` 2px | `#102138` (네이비) | 보조 행동 |
| **Tertiary (선)** | 투명 | `#FFB703` 2px | `#A2371F` (빨강) | 약한 행동 |

```css
.btn {
  display: inline-flex; align-items: center; justify-content: center;
  font-family: var(--font-en); font-weight: 700; letter-spacing: 0.02em;
  text-transform: uppercase;
  padding: 0.7em 1.6em; border-radius: 999px; border: 2px solid transparent;
  cursor: pointer; transition: transform .12s ease, filter .12s ease;
}
.btn:hover  { transform: translateY(-1px); filter: brightness(1.05); }
.btn:active { transform: translateY(0); }

.btn--primary   { background: var(--color-point); color: var(--color-menu); }
.btn--secondary { background: transparent; border-color: var(--color-menu); color: var(--color-ink); }
.btn--tertiary  { background: transparent; border-color: var(--color-menu); color: var(--color-point); }
```

### 3-3. 섹션 구분 / 번호 (Pizza Slice Divider)
- **단락구분 번호** = 피자 조각이 **1조각 → 2조각 → … → 한 판**으로 늘어나는 일러스트. 가이드에 6단계, 앱 아이콘과 같은 모티프.
- **용도**: 페이지 섹션의 순번 마커(① 한 조각, ② 두 조각 …) 또는 스크롤 진행 표시.
- **에셋**: 앱의 `pizzaClip/Resources/Assets.xcassets/PizzaIcon{0..9}` PNG를 웹용으로 재활용하거나 동일 톤 SVG로 다시 그림. `web/public/img/slice-1.svg …` 형태로 둘 것.
- **접근성**: 장식용이면 `alt=""`, 번호 의미가 있으면 `alt="섹션 3"`처럼 명시.

### 3-4. 카드 (Card)
목업의 큰 블록들. 두 종류:
- **옐로우 카드**: 배경 `#FFB703`, 큰 라운드(약 `24px`), 안쪽 여백 넉넉히. 제목은 네이비/빨강. (예: "아직도 피자 클립 안써요? 왜요?")
- **화이트 카드**: 배경 흰색, 옐로우 테두리, 체크리스트 + Primary 버튼. (예: 마지막 "어메이징 피자클립!!!!!" 다운로드 카드)

```css
.card        { border-radius: 24px; padding: clamp(1.5rem, 4vw, 3rem); }
.card--menu  { background: var(--color-menu); color: var(--color-ink); }
.card--white { background: var(--color-surface); border: 2px solid var(--color-menu); }
```

---

## 4. 레이아웃 & 페이지 구조 (목업 기준)

`pizza web.png` 랜딩 흐름(위 → 아래):

1. **상단 네비**: 로고 / HOW TO / 인포·EXIT.
2. **히어로**: 제품 비주얼(피자 자판기/박스 + "PIZZA CLIP" 라벨) + 버튼 묶음(Primary 1 + 선 버튼 2) + 🍕 조각 장식.
3. **후킹 섹션**: 옐로우 카드 "아직도 피자 클립 안써요? 왜요?" + 한 줄 서브카피.
4. **🍕 조각 디바이더**로 섹션 구분(반복).
5. **이미지/광고판 섹션**: 레트로 빌보드 느낌(`Billboard 1910.png`, `pizza store.png` 톤 참고) + 짧은 카피.
6. **빈 옐로우 카드 섹션**: 기능 소개/스크린샷 들어갈 자리.
7. **다운로드 카드(화이트)**: 체크리스트(✓ 항목들) + `DOWNLOAD` Primary 버튼 → GitHub Releases 최신 `.dmg`로 연결.

### 레이아웃 토큰
```css
:root {
  --maxw: 1080px;        /* 콘텐츠 최대 폭 */
  --gutter: clamp(1rem, 4vw, 2rem);
  --section-gap: clamp(3rem, 8vw, 6rem);
  --radius-card: 24px;
  --radius-pill: 999px;
}
.container { max-width: var(--maxw); margin-inline: auto; padding-inline: var(--gutter); }
```
- **모바일 우선** 반응형. 카드는 모바일에서 가로 꽉 차게, 데스크톱에서 중앙 정렬.
- 섹션 사이 간격 `--section-gap`, 피자 디바이더는 섹션 경계 중앙에 배치.

---

## 5. Astro 적용 체크리스트

- [ ] `web/src/styles/tokens.css`에 §1·§2·§4 변수 정의 → 레이아웃에서 1회 import.
- [ ] `web/public/fonts/`에 OSP-DIN·리디바탕 `.woff2` 배치 + `@font-face` 선언, Pretendard는 fontsource/CDN.
- [ ] `web/src/components/`에 `Navbar.astro` / `Button.astro`(variant prop: primary·secondary·tertiary) / `Card.astro`(variant: menu·white) / `SliceDivider.astro`.
- [ ] `web/public/img/`에 피자 조각 디바이더 에셋(SVG 권장).
- [ ] `body { background: var(--color-bg); color: var(--color-text); font-family: var(--font-sans); line-height: var(--lh-body); }` 전역 기본값.
- [ ] 다운로드 버튼 링크 = `https://github.com/parkppuri01/pizzaClip/releases/latest` (첫 릴리스 전엔 404 주의 — HANDOFF §10 참고).

---

## 6. 원본 에셋 위치

| 파일 | 내용 |
|---|---|
| `web/guide/design.png` | 디자인 시스템 가이드(폰트·컬러·컴포넌트) — **이 문서의 출처** |
| `web/guide/pizza web.png` | 랜딩 페이지 목업(섹션 흐름) |
| `web/guide/Billboard 1910.png` | 레트로 광고판 톤 참고 |
| `web/guide/pizza store.png` | 피자 가게 비주얼 톤 참고 |

> 색·폰트 값이 의심되면 `design.png`를 다시 열어 대조하세요. 이 `.md`와 그림이 다르면 **그림이 우선**이고, 그때 이 문서를 고칩니다.
