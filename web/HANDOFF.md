# Web Handoff — pizza-clip.com (랜딩 사이트)

마지막 업데이트: **2026-06-01** (① 🍕 이모지 파비콘 풀세트 정비 — favicon.ico 16/32/48 멀티사이즈 + apple-touch 180(크림배경) + android 192/512 png, BaseLayout `<head>` 링크 연결. ② Google Analytics(GA4) `G-30DB0P1HWL` gtag.js 를 BaseLayout `<head>` 상단에 삽입(`is:inline` 로 원문 보존, 전 페이지 자동 적용). ③ 푸터에 Team JAM 소셜(인스타/스레드) **공식 로고 SVG** 추가 — `instagram.com/team___jam/` , `threads.com/@team___jam`, currentColor 크림색+hover 노란색. 전부 master 푸시 → Vercel 라이브. 이전: 2026-05-31 비주얼 디테일 개편.)

> 이 문서는 **웹(`web/`) 전용 핸드오프**입니다. 앱(Swift) 쪽은 [`docs/HANDOFF.md`](../docs/HANDOFF.md) 참고.
> 진입 방법: "pizza-clip.com 수정하자" → `web/` 에서 작업 → `cd web && npm run build` 통과 확인 → master 푸시 = Vercel 자동배포.

---

## 1. 사이트 현황 (라이브)

- **호스팅**: Vercel, **Root Directory = `web`**, 도메인 `pizza-clip.com` (Cloudflare DNS, 회색 구름=DNS only). repo `parkppuri01/pizzaClip` **master 푸시 시 자동 재배포**.
- **스택**: Astro **6.4.2** (TypeScript strict, **추가 런타임 의존성 0** — astro만).
- **로컬 빌드**: `cd web && npm install && npm run build` (`dist/`·`node_modules`는 gitignore).
- **로컬 미리보기**: 루트 `.claude/launch.json` 의 `web` 설정으로 preview_start (포트 **4321**). 또는 `npm run dev`.
- **다운로드 링크**: `web/src/consts.ts` 의 `DOWNLOAD_URL` = `https://github.com/parkppuri01/pizzaClip/releases/latest/download/pizzaClip.dmg` — **클릭하면 최신 .dmg 바로 다운로드**(고정 파일명이라 버전 올라도 링크 수정 불필요. release.sh 가 매 릴리스마다 이 이름으로 업로드). `GITHUB_URL` = repo 주소.
- **자동업데이트 appcast**: `web/public/appcast.xml` 이 `pizza-clip.com/appcast.xml` 로 서빙됨(Sparkle). **앱 release.sh(PUBLISH=1)가 자동 재생성**하므로 웹 작업 중 직접 손대지 말 것.

## 2. 페이지 & 파일 구조

```
web/
├── src/
│   ├── consts.ts                 # 전역 상수: DOWNLOAD_URL / GITHUB_URL / SITE_* / NAV_LINKS
│   ├── layouts/BaseLayout.astro  # <head> 메타·OG·canonical·폰트, Navbar/Footer 틀
│   ├── components/
│   │   ├── Navbar.astro           # 상단 옐로우 네비 (HOME/HOW TO/INFO + Download). 무줄바꿈+clamp
│   │   ├── Footer.astro           # © 2026 pizzaClip · Team JAM, 메뉴 홈·사용법·깃허브
│   │   ├── Button.astro           # 알약 버튼 3종 (primary/secondary/tertiary)
│   │   ├── Card.astro             # 카드 2종 (menu=옐로우 / white=흰). 차콜 테두리 + 단단한 오프셋 그림자(menu=빨강/white=차콜)
│   │   └── SliceDivider.astro     # 피자 누적 디바이더 (count 1~4 → slice-N.png, 이모지 아님)
│   ├── pages/
│   │   ├── index.astro            # 홈: 히어로→후킹카드→광고판→기능→다운로드 (사이사이 SliceDivider 1~4)
│   │   ├── how-to.astro           # 사용법: 설치 3단계 + 단축키 표
│   │   ├── info.astro             # 정보: 전체 버전 릴리스노트 + Team JAM 소개
│   │   └── blog/                  # 블로그 — 폐기됨(2026-06-01), 미연결. 차후 파일 정리 대상
│   ├── content/blog/hello.md      # 블로그 작성 템플릿 (draft:true)
│   ├── content.config.ts          # Astro Content Layer (glob loader) — md 1개 떨구면 자동 등장
│   └── styles/{tokens,fonts,global}.css  # 디자인 토큰·@font-face·리셋
├── public/
│   ├── img/{billboard.jpg, pizza-store.jpg, storefront.jpg,   # 사진(차콜 2px 테두리)
│   │        slice-1~4.png, jam-logo.png}                       # 피자 디바이더 4종 · JAM 로고
│   ├── fonts/{RIDIBatang.woff2, OSP-DIN.woff2}
│   ├── appcast.xml                # Sparkle 피드 (앱 release.sh 가 관리)
│   └── robots.txt                 # AI 크롤러 허용 (sitemap 줄은 통합 후 주석 해제 예정)
└── guide/                         # 디자인 원본 에셋 (design.md=SSOT, *.png/jpg 목업·소스)
```

- **디자인 SSOT**: `web/guide/design.md` (색 5종·폰트 3종·버튼·카드·🍕디바이더 규칙). 토큰 값 헷갈리면 여기 따름.
- **컬러**: 크림 `#FCF6EF` / 벽돌빨강 `#A2371F`(포인트·CTA) / 피자옐로우 `#FFB703`(메뉴·카드) / 네이비 `#102138`(제목) / 차콜 `#333`(본문).
- **폰트**: Pretendard(한글 본문, CDN dynamic-subset) / 리디바탕(감성·블로그 본문, self-host) / OSP-DIN(영문 로고·메뉴·버튼, self-host).

## 3. 완료된 작업

### 2026-06-01 — 파비콘·GA4·소셜 (커밋 4개)
- `520b6ed` feat(web): 🍕 이모지 파비콘 풀세트 (멀티사이즈 ico + apple-touch + android png)
- `692a86f` feat(web): Google Analytics(GA4) 측정 태그 삽입
- `1453f66` feat(web): 푸터 SNS 공식 인스타/스레드 로고로 교체 + 주소 정정
  - (그 전 `520b6ed` 직전에 푸터 SNS 1차로 텍스트 링크 추가 → 이 커밋에서 로고로 교체)

무엇을 했나:
- **파비콘**: 어제 favicon.svg 는 이미 삭제, .ico 를 🍕 이모지로 통일. 맥 로컬에서 생성(swiftc 로 NSAttributedString 1024px 렌더 → sips 리사이즈 → 순수 파이썬으로 멀티사이즈 ico 패킹, 외부 변환 도구 없음). 산출: `public/favicon.ico`(16/32/48), `apple-touch-icon.png`(180, 크림배경 #FCF6EF+여백 ─ 애플이 투명을 검정으로 칠하므로), `android-chrome-192/512.png`(투명). BaseLayout `<head>` 66~70줄 부근에 link 4종.
- **GA4**: 측정ID `G-30DB0P1HWL`. gtag.js 스니펫을 BaseLayout `<head>` 상단(charset/viewport 직후)에 삽입. 두 번째 인라인 스크립트엔 **`is:inline`** 필수(없으면 Astro 가 번들링해서 gtag 깨짐). BaseLayout 공통이라 3페이지 전부 자동 적용. 다운로드 버튼 클릭 이벤트(전환) 추적은 아직 미설정 — 페이지뷰만 집계됨.
- **푸터 소셜**: `consts.ts` 에 `INSTAGRAM_URL`/`THREADS_URL` 추가, `Footer.astro` 에 `.footer__social` nav + 공식 로고 인라인 SVG(22×22, fill=currentColor). hover 시 노란색(--color-menu)+불투명. 원본 SVG 는 `web/guide/{instagram,threads}.svg`(Simple Icons).
- 검증: `npm run build` 통과 + preview(launch.json `web`, 포트 4321)로 푸터 캡처·링크 주소 확인. **참고**: preview_screenshot 이 캡처 직전 스크롤을 맨 위로 리셋하는 글리치 있음 → 푸터 보려면 `window.scrollTo(0, scrollHeight)` 후 바로 캡처하거나 eval 로 직접 측정.

⚠️ 다음 세션 정리거리(이번 세션이 만든 것 아님, 워킹트리에 남아있음): `web/HANDOFF.md`·`web/src/styles/global.css` 수정분, **블로그 파일 4개 삭제**(`content.config.ts`, `content/blog/hello.md`, `pages/blog/[...id].astro`, `pages/blog/index.astro`), `.claude/settings.local.json`. 의도 여부 확인 후 커밋 or `git checkout` 으로 결정 필요.

### 2026-05-31 — 비주얼 디테일 개편 (커밋 8개)
- `ac3efc8` feat(web): 피자 디바이더 이미지화 + info Team jAm 카드 + 매장 광고 사진
- `b350168` style(web): info 팀카드 본문 리디바탕 + 메인 다운로드 카드 제목 교체
- `6edcd82` style(web): info 팀카드 테두리 1.5→3px
- `90957cd` style(web): 네비 색상(로고 빨강/HOW TO 검정) + 카드 오프셋 그림자
- `04a0fc2`·`b3f7a53` style(web): how-to 단축키 박스 제목 아래 줄바꿈 한 줄
- `ed1676b` style(web): 카드 그림자 12→8px + 노란 카드 테두리
- `458b20d` style(web): 테두리색 #333 토큰화(--border-ink) + 사진 박스 테두리

무엇을 했나:
- **섹션 디바이더 이미지화**: `SliceDivider` 🍕 이모지 반복 → 실제 피자 그림 4종(`public/img/slice-1~4.png`, 1→4조각 차오름, height 64px). 원본은 `guide/bullet/`. 배경이 페이지 크림색이라 자연 합성.
- **info Team jAm 카드 재디자인**(`team jAm.png` 그대로): 노란 카드 → **흰 카드 + 차콜 3px 테두리**. 제목 `Team jAm`(대소문자 유지), 회색 이탤릭 인용, 본문 **리디바탕(serif)** — 단 영문 `PIZZA CLIP`=OSP-DIN·`Team jAm`=Pretendard 볼드로 유지(섞인 영문만 sans 고정), 멤버 `jae_keun`/`min_gyeol`, 우하단 영문 인용 + 검은 원형 JAM 로고(`public/img/jam-logo.png` ← `guide/info_logo.png`).
- **매장 광고 사진**: `guide/page2.png`(22MB) → `public/img/storefront.jpg`(1400px·232KB, `sips -Z 1400 fmt jpeg q82`). 4번째 디바이더 바로 아래 가운데정렬, 다운로드 카드 위.
- **메인 다운로드 카드 제목**: '어메이징, 피자클립' → **'Mac에 빼놓을 수 없는 토핑, 피자클립 🍕'**.
- **네비 색상**: 로고 → 빨강(`--color-point`), `HOW TO` → 검정(`#111`). 빨간 강조를 메뉴에서 로고로 이동(`[href="/how-to"]` 셀렉터로 지정).
- **카드/사진 프레임 통일**: 단단한 오프셋 그림자(블러 X, **8px**) — 노란 카드=빨강, 흰 카드=차콜. 모든 카드 + 사진(billboard·storefront)에 **2px 차콜 테두리**. 색은 `--border-ink:#333` 토큰 1곳에서 관리(`tokens.css`). 히어로 자판기 사진은 기존 부드러운 드롭섀도 유지(제외).
- **how-to 단축키 박스**: 제목 '단축키 한눈에' 바로 아래 `<br>` 한 줄 추가(margin은 원래 1.25rem).

### 2026-05-30 — 사이트 개편 (커밋 3개)
- `7a21a05` **feat(web): 랜딩 사이트 개편** — 카피·INFO·스케일·정렬 정비
- `a71247c` **style(web): 네비 로고·메뉴 + 버튼 폰트 한 단계 확대**
- `09cb042` **feat(web): 하단 다운로드·히어로 GitHub 버튼 제거 + 네비 줄바꿈 방지**

무엇을 했나:
- **전역 스케일 ~90% 축소**: `global.css` `html { font-size: 90% }` (root 14.4px) + `tokens.css` `--maxw: 970px`.
- **네비 정리**: `HOME / HOW TO / INFO` (BLOG는 파일 보존하되 `NAV_LINKS`에서 제외). 폰트 확대(로고 1.6rem / 메뉴 1.2rem / 버튼 1.1rem, clamp 상한). **무줄바꿈**: `flex-wrap: nowrap` + `clamp()` 유동 크기 → 좁아지면 글자·버튼이 함께 줄며 한 줄 유지(375px에서도 무오버플로 확인).
- **INFO 페이지 신설** (`info.astro`): 전체 버전 릴리스노트(v1.0.0~0.1.1을 일반 유저 문구로) + **Team JAM 소개**(jaekeun·mingyeol, 재미로 시작한 프로젝트 팀, 리디바탕 serif).
- **카피 전면 교체**: 히어로("Mac 메뉴바에 배달된 피자 한판"·배달 컨셉), 후킹("언제까지 ⌘C, ⌘V 무한 반복…"), 기능 4개(⌘C의 무한 보관소 등 펀치라인), 하단 장점 4줄(0원·모든 Mac·애플 인증·자동 업데이트 — 개발 용어 제거).
- **히어로 이미지 교체**: `guide/pizza store.jpg`(2205×2928, 7.4MB) → `public/img/pizza-store.jpg`(828×1100, **335KB**, `sips -Z 1100`). 기존 `app-icon.png` 삭제.
- **디바이더 누적**: `SliceDivider.astro` 신설, 홈에서 위→아래 🍕 **1→2→3→4개**.
- **푸터**: `© 2026 pizzaClip · Team JAM`, 메뉴 `홈·사용법·깃허브`만, 폰트 축소.
- **버튼 정리**: how-to·info 하단 중복 다운로드 버튼 제거(상단 네비 버튼으로 충분), 히어로 GitHub 버튼 제거.

### 2026-05-29 — 사이트 1차 완성 + 직접 다운로드
- Astro 스캐폴드 + 디자인 토큰 + 공용 컴포넌트(Navbar/Footer/Button/Card) + 3페이지(home/how-to/blog) + 폰트 self-host + robots.txt.
- 블로그 Content Layer 배선(`src/content/blog/*.md` 1개로 목록+상세 자동 생성, 검증됨).
- 다운로드 버튼을 **고정이름 직접 다운로드**(`…/releases/latest/download/pizzaClip.dmg`)로 전환.
- Vercel 배포 + 도메인 연결(Cloudflare 회색구름) 완료.

## 4. 교훈 / 함정 (다음에 또 헤매지 않으려고)

1. **Astro 스코프 스타일 × 컴포넌트 경계** ⚠️ 가장 중요: 부모 페이지의 `<style>`에서 `<Card class="x">`/`<Button class="y">`처럼 **자식 컴포넌트에 넘긴 class 를 그 컴포넌트 루트에 직접** 스타일하면 **안 먹힘**. (자식 컴포넌트 루트는 자식 파일의 scope 속성을 달아서 부모 scope 셀렉터와 안 맞음.) → 해결: ① 슬롯 안에 래퍼 div 를 두고 그걸 스타일(`.download__inner`, `.team-wrap`), ② `:global()` 사용(`.navbar :global(.navbar__cta)`). 슬롯 *내용*의 하위 요소(예: `.hook h2`, `.team__body`)는 부모 scope 가 정상 적용됨.
2. **전역 스케일은 `html { font-size: % }`**: rem 기반 타입·간격이 일괄 축소됨. `clamp(min-rem, vw, max-rem)`도 rem 상·하한이 비례 축소.
3. **preview 스크린샷 캡처 배율 artifact**: 일부 캡처가 콘텐츠를 한쪽으로 쏠려 좁게 보여줄 수 있음 → **DOM `getBoundingClientRect` 측정이 정답**. 정렬·폭은 측정으로 검증할 것.
4. **viewport는 페이지 네비게이션 후 초기화**될 수 있음 → resize 후 다시 측정.
5. **`scroll-behavior: smooth` 때문에 `window.scrollY` 즉시 읽기가 0** → 측정 직전 `document.documentElement.style.scrollBehavior='auto'`.
6. **preview MCP eval 글리치(2026-05-31 세션)**: eval 로 `window.location.href` 네비게이션을 하면 그 뒤 eval 컨텍스트의 `window.innerWidth`가 0으로 잡혀 측정값(getBoundingClientRect·margin 등)이 0/붕괴로 **오보**됨. 스크린샷도 한쪽으로 좁게 깨지거나 빈 화면이 나오기도 함. → 회피: ① 페이지가 통째로 들어갈 **긴 뷰포트**(`preview_resize` 높이 크게)로 잡고 스크롤 없이 한 번에 캡처, ② 깨졌으면 `preview_resize` 프리셋(desktop)으로 **리셋**하면 정상 렌더 복구. 같은 페이지 내 `scrollTo`(네비게이션 X)는 대체로 OK. 측정값은 정상 상태에서만 신뢰(테두리·색 같은 고정값은 비교적 잘 잡힘).

## 5. 남은 웹 Task (우선순위)

> **블로그 기능 폐기 (2026-06-01 결정)**: 블로그는 더 이상 사용하지 않기로 함. 네비에서 뺀 상태였고, 이제 재개 계획 없음. 남아있는 블로그 관련 파일(`src/pages/blog/`, `src/content/blog/hello.md`, `src/content.config.ts`)은 차후 정리 대상 — 당장 동작에 영향 없음.

1. **HOW TO 페이지 콘텐츠 강화** — 현재 `how-to.astro` 는 설치 3단계 + 단축키 표 위주. 보강 거리: 실제 사용 흐름 예시(⌘C 쌓기→⌘⇧V 팝업→숫자/↵ 붙여넣기), 직접붙여넣기(⌘⌥⌃1~9)·0=전체붙여넣기 설명, 한/영 토글·이스터에그 같은 숨은 기능 소개, 스크린샷/GIF, FAQ(권한·자동업데이트 등). 분량이 늘면 섹션·목차 구조도 고려.
2. **AEO/GEO 심화** — `@astrojs/sitemap` 통합 + `public/robots.txt` 의 Sitemap 줄 활성화(현재 `sitemap.xml` 을 가리키지만 실제 생성기 미설치), JSON-LD(SoftwareApplication / FAQ). `llms.txt` 는 이미 추가됨(`public/llms.txt`).
3. **INFO 릴리스노트 유지** — 새 버전 낼 때 `info.astro` 의 `releases` 배열에 항목 추가(현재 1.0.0~0.1.1 수기). TeamJAM 소개 문구도 원하면 다듬기.
4. **(선택)** 인트로 "커튼" 연출, 카피/이미지 추가 다듬기.

## 6. 작업 컨벤션

- 커밋: conventional commits(feat/style/fix/chore + `(web)` scope), 한국어 본문 2~3줄. **co-author 트레일러 없음**(단독/소규모 팀).
- **단일 브랜치(master)** 운영 — 별도 머지 단계 없음. master 푸시 = 배포.
- 수정 후 항상 `cd web && npm run build` 통과 확인. 가능하면 preview 로 데스크톱+모바일(375px) 정렬·무오버플로까지 검증.
