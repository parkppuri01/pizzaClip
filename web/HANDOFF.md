# Web Handoff — pizza-clip.com (랜딩 사이트)

마지막 업데이트: **2026-06-14** (🌐 **영문 사이트(EN/KO) + AEO/GEO 강화 — 빌드·프리뷰 검증 완료, ⚠️ 아직 미배포(커밋/푸시 안 함)**. 한국어는 루트 그대로, 영문은 `/en/` 4페이지(인트로·피자·피클·인포 / how-to 제외). 상단바 깃허브 오른쪽 **EN/KO 세로 토글**(위 KO/아래 EN) + **접속지역 자동 언어분기**(IP 국가 헤더, 위치권한 팝업 없음 — 한국=한글/그 외=영문, 첫 진입 1회·미들웨어, ⚠️배포 후 검증). 4개 페이지를 `lang` 받는 **공유 컴포넌트**(`src/components/pages/*`)로 리팩터링해 한·영이 마크업·CSS 1벌을 공유, 텍스트만 `src/i18n/*` 사전에서. hreflang·og:locale·JSON-LD inLanguage 언어별 분기, sitemap i18n alternate, llms.txt 영문·양앱 전면개정. 자세히는 §3 **2026-06-14 (i18n+AEO)**. 이전: 🚀 **튜토리얼 영상 팝업 + 피클 노크 카운트 — 둘 다 라이브 배포·검증 완료**. ① 피자·피클 히어로 다운로드 버튼 옆 '튜토리얼' 버튼 → 누르면 유튜브 영상 팝업(`VideoModal.astro` 신설, 커밋 ca3ac11). ② DAU 노크 카운트에 피클앱(`/pickle/appcast.xml`) 추가 — 앱별 키 분리, `/api/stats` 에 `apps.{pizza,pickle}`+`combined`(커밋 37d33e1). 자세히는 §3 2026-06-14. 이전: 가이드 풀버전 재반영 86a003c, PICkle 통일·파비콘 5bf3f80·9b2bcf2·214f95d.)

> 이 문서는 **웹(`web/`) 전용 핸드오프**입니다. 앱(Swift) 쪽은 [`docs/HANDOFF.md`](../docs/HANDOFF.md) 참고.
> 진입 방법: "pizza-clip.com 수정하자" → `web/` 에서 작업 → `cd web && npm run build` 통과 확인 → master 푸시 = Vercel 자동배포.

---

## 🔖 세션 이어받기 (2026-06-14, 🌐 영문 사이트 EN/KO + AEO/GEO 강화 — **빌드·프리뷰 검증 완료, 아직 미커밋·미배포**)

> ⚠️ **배포 전**: 이번 변경은 `git` 에 커밋/푸시하지 않았습니다(사용자 확인 후 배포). 배포하려면 master 푸시 = Vercel 자동배포.

이번 세션은 **사이트 전체를 한국어/영어 2개국어로** 만들고, 지난 AEO 작업의 미흡한 부분을 보강했습니다.

### 1) i18n 구조 (한국어=루트, 영문=`/en/`)
- **라우팅**: `astro.config.mjs` 에 `i18n: { defaultLocale:"ko", locales:["ko","en"], routing:{prefixDefaultLocale:false} }`. 한국어는 기존 URL 그대로(`/`,`/pizzaclip`,`/pickle`,`/info`), 영문은 `/en/`,`/en/pizzaclip`,`/en/pickle`,`/en/info`. **how-to 는 영문 제외**(한국어 전용 유지).
- **중복 방지 — 핵심**: 4개 페이지를 `lang` 프롭 받는 **공유 컴포넌트 `src/components/pages/{Intro,Pizza,Pickle,Info}Page.astro`** 로 리팩터링. 마크업·`<style>` 는 한 벌만 존재하고 한·영이 공유. **텍스트(카피)만** `src/i18n/{intro,pizza,pickle,info}.ts` 사전(`Record<"ko"|"en", …>`)에서 가져옴. → 앞으로 디자인/CSS 수정은 **공유 컴포넌트 1곳만** 고치면 양 언어에 동시 반영(절대 두 벌로 갈라지지 않음).
- 페이지 파일(`src/pages/*.astro`, `src/pages/en/*.astro`)은 전부 `<XxxPage lang="ko|en" />` 2~4줄짜리 래퍼.
- **i18n 중앙 헬퍼 `src/i18n/ui.ts`**: `type Lang`, `ROUTES`, `href(lang,key)`(내부 링크를 항상 같은 언어판으로), `enHref()`, `ui[lang]`(네비/푸터/소셜 aria·라벨), `siteMeta[site][lang]`(기본 title/description). **내부 링크는 전부 `href(lang,...)` 통과** — 한국어 페이지 링크는 ko 경로, 영문 페이지 링크는 `/en/` 경로로 자동.

### 2) EN/KO 토글 (상단바 깃허브 오른쪽) — **세로(위 KO / 아래 EN) 토글**
- `SocialIcons.astro` 에 `.langtog`(틸 테두리, **세로 2칸** — KO 위·EN 아래) 추가 — `koPath` 가 있을 때만 노출(양 언어판 존재 페이지). 현재 언어 칸이 채워진(틸) 상태, 반대 언어 누르면 **같은 페이지의 반대 언어판**으로 이동. 데이터 흐름: BaseLayout → NavMinimal → SocialIcons 로 `lang`·`koPath` 전달. (가로→세로 변경: 사용자 요청. 폭 22px 로 더 좁아져 모바일 여유↑.)
- **how-to 는 koPath 안 넘김** → 토글·hreflang 둘 다 안 나옴(영문판 없으니 정답). 데스크톱·**375px 모바일 모두 한 줄 유지·가로 오버플로 0**, 활성표시는 쿠키가 아니라 **현재 페이지 lang** 반영(측정 확인).

### 2-b) 접속지역 기반 언어 자동 분기 (위치권한 팝업 없음)
- **`middleware.js`(Vercel Edge) 에 로케일 리다이렉트 추가** — 노크 카운트 로직은 **그대로 보존**, matcher 에 8개 페이지 경로 추가.
- 판단 수단 = **`x-vercel-ip-country` 헤더**(Vercel 이 IP 로 붙여줌, **위치권한 확인창 안 뜸**). 한국(KR) 외 → 한국어 경로 진입 시 영문(`/en/…`)으로, 한국(KR) → 영문 경로 진입 시 한국어로 **307 1회** 리다이렉트.
- **과한 개입 방지 4중 가드**: ① `pclang` 쿠키 있으면(=이미 한 번 봄) 안 함 ② referer 가 우리 도메인(=토글/내부 링크 클릭)이면 안 함(토글 무한바운스 방지) ③ 검색/AI 크롤러 UA 면 안 함(두 언어 URL 모두 색인) ④ 국가 모르면 기본(한국어) 유지.
- **짝꿍 쿠키**: BaseLayout 인라인 스크립트가 첫 방문 후 `pclang`=현재언어 기록 + 토글 클릭 시 선택언어 기록 → 자동분기는 **첫 외부 진입 1회만**, 이후엔 사용자 네비 존중. 리다이렉트 응답에도 `Set-Cookie`.
- ⚠️ **로컬 검증 불가**: Edge 미들웨어는 Vercel 플랫폼에서만 실행됨(`astro build`/preview 에선 안 돎). `node --check` 구문검사 + 경로매핑 로직만 로컬 확인. **실제 지역 리다이렉트는 배포 후 확인**(예: VPN 으로 해외 IP → 한국어 페이지 접속 시 `/en/` 으로 튀는지). SEO 주의: 크롤러는 건드리지 않게 했고 hreflang 로 양 URL 안내하지만, 지역 리다이렉트는 일반적으로 신중히 — 문제 시 미들웨어 (2) 블록만 들어내면 됨.

### 3) AEO/GEO 보강 (지난 작업 대비 추가/수정)
- **hreflang**: 양 언어판 페이지에 `ko`·`en`·`x-default`(=ko) `<link rel=alternate>` 발행(BaseLayout, `koPath` 있을 때만). how-to 는 미발행.
- **og:locale + og:locale:alternate**, **`<html lang>`·JSON-LD `inLanguage`** 언어별 분기.
- **`@astrojs/sitemap` i18n**: `sitemap-0.xml` 에 4개 페이지 ko-KR/en-US `xhtml:link` alternate 자동 주석, how-to 는 alternate 없음(검증함).
- **SoftwareApplication 강화**(피자·피클만, 인트로/인포는 미발행): `featureList`(앱별 6개·언어별), `softwareVersion`(피자 1.1.0·피클 1.0.0), `operatingSystem:"macOS 13.0+"`, `applicationSubCategory`, `isAccessibleForFree`, `offers`(price 0 USD), `author`+`publisher`, `screenshot`, 피자 ko 에 `softwareHelp`(how-to). **가짜 aggregateRating 은 의도적으로 넣지 않음**(가이드라인 위반).
- **Organization**: `logo` + `sameAs`(github×2 + instagram + threads).
- **robots 메타**: `index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1`.
- **llms.txt 전면 개정**: 기존(한국어·피자만) → **영문·양 앱(PIZZA CLIP+PICkle)·FAQ 10문항·페이지 목록(ko+en URL)**. AI 답변엔진(ChatGPT/Perplexity/Claude/구글 AI) 핵심 콘텐츠 통로.

### 검증
- `cd web && npm run build` → **9페이지 통과**(ko 5 + en 4). 콘솔 에러 0.
- 프리뷰: 한국어 피자 페이지 **스티커·띠·straddle·뱃지 전부 원위치(회귀 0)**, 영문 4페이지 모두 영문 렌더, 토글 양방향 동작·현재언어 하이라이트, 375px 무오버플로, hreflang/og:locale/inLanguage/sitemap alternate HTML 산출물 직접 확인. `set:html` 로 들어가는 팀소개 brand 스팬은 `:global(.brand)` 로 폰트 적용됨(스코프 함정 회피, 검증).

### 영문 카피 메모
- 마케팅 톤(피자=조각 쌓기, 피클=절임/병 은유)을 영어로 자연스럽게 재창작(직역 X). 단축키 글리프(⌘⇧V 등)·버전·이모지·브랜드명(PizzaClip/PICkle/Team JAM) 보존.
- **튜토리얼 영상은 한·영 동일 videoId**(영문 전용 영상 없음) — EN 페이지는 버튼·제목 라벨만 영문. 영문 영상 생기면 `VideoModal videoId` 만 교체.
- **OG 이미지는 ko·en 공용**(`og-*.jpg` 한국어 텍스트 포함) — 영문 전용 OG 는 차후 과제(이미지 자산 없음).

### 이어받기 팁(이번 세션)
- 새 카피 수정 = **`src/i18n/{intro,pizza,pickle,info}.ts` 의 `ko`/`en` 만** 고침. 디자인/레이아웃 = **`src/components/pages/*Page.astro`** 만 고침(양 언어 동시 반영). 새 내부 링크 = `href(lang, "intro|pizza|pickle|info")` 사용(직접 `/pickle` 쓰지 말 것 — 영문에서 깨짐).
- 새 페이지를 양 언어로 추가 = ① `ROUTES` 에 키 추가 ② 공유 컴포넌트에서 `koPath={ROUTES.key}` ③ `src/pages/key.astro`(ko) + `src/pages/en/key.astro`(en) 래퍼. hreflang·sitemap·토글이 자동으로 따라옴.
- `eval` 로 `location.href` 네비게이션 후 `window.innerWidth=0` 글리치 여전 → `preview_resize` 프리셋으로 리셋 후 측정(기존 함정 §4-6 재확인).

---

## 🔖 (이전) 세션 이어받기 (2026-06-14, 튜토리얼 영상 팝업 + 피클 노크 카운트 — **둘 다 라이브 배포·검증 완료**)

이번 세션 작업은 **커밋 37d33e1·ca3ac11 master 푸시 = Vercel 라이브**. 워킹트리 잔여는 **이번 세션 무관**(`web/guide/**` 디자인 원본 등 미커밋 참고 자산).

- **① 튜토리얼 영상 팝업**(`ca3ac11`):
  - **재사용 컴포넌트 `web/src/components/VideoModal.astro` 신설** — 페이지당 1개 두고, 여는 버튼에 `data-open-video` 속성만 달면 동작. 어두운 오버레이(`position:fixed; inset:0; z-index:1000`) 위 16:9(`aspect-ratio`) 유튜브 iframe. **닫기 3종**(✕/배경/ESC), 닫을 때 `iframe.src="about:blank"` 로 **영상 정지**(빈 문자열은 현재 페이지를 다시 로드하므로 about:blank). **클릭 전엔 iframe 미로드**(초기 가벼움), 열 때 `autoplay=1` 주입. `<script is:inline define:vars={{videoId}}>` 로 videoId 주입.
  - **피자**(`pizzaclip.astro`): `.hero__cta` 에 `<Button variant="secondary" data-open-video>튜토리얼</Button>` + 페이지 끝 `<VideoModal videoId="9nhJBjU_JtQ" title="피자클립🍕튜토리얼" />`.
  - **피클**(`pickle.astro`): `<button class="pill pill--tut" data-open-video>튜토리얼</button>`(신규 `.pill--tut` 외곽선 올리브 스타일) + `<VideoModal videoId="HJ1hLgfnWfQ" title="PICkle🥒튜토리얼" />`.
  - **`Button.astro` 보강**: `...rest` 스프레드로 `data-*` 등 임의 속성 통과(기존 사용처 무영향). Props interface 에 `[key:string]:unknown` 추가.
  - 버튼 텍스트 '튜토리얼'(4자)=' 다운로드'(4자) → **다운로드와 정확히 같은 크기**(피자 111×52 / 피클 98×44, 측정 확인). 사용자 요청으로 재생 세모(▶)는 제거함.
- **② 피클 노크 카운트**(`37d33e1`): `middleware.js` matcher 를 `['/appcast.xml','/pickle/appcast.xml']` 로 확장, 경로로 앱 구분해 **앱별 키 분리** — 피자 `knock:`(기존 그대로=과거 데이터 보존), 피클 `knock:pickle:`. `api/stats.js` 는 두 앱 병렬 read → 최상위 `today/byDay`(피자 기준, **호환 유지**) + `apps.{pizza,pickle}` + `combined`(합산) 반환. ⚠️ 피클 카운트는 **배포 시점부터 0에서 시작**(과거 소급 불가). 조회: `https://pizza-clip.com/api/stats?key=<STATS_KEY>`.
- **검증**: `npm run build` 5페이지 통과 · 콘솔 에러 0 · preview 에서 두 페이지 팝업 열림/닫힘/영상 src·중앙정렬·16:9(데스크톱 960×540, 모바일 345×194)·가로 오버플로 0 확인 · 유튜브 oembed 200 · 라이브 `data-open-video` 노출 + stats `combined` 필드 라이브 확인.
- **이어받기 팁(이번 세션)**:
  - **유튜브 팝업 = `position:fixed` 오버레이** → preview_screenshot 의 스크롤 리셋 글리치로 **모달이 하단에 잘려 보이는 착시** 발생. `preview_resize`(desktop) 리셋 후 `getBoundingClientRect` 로 중앙정렬·치수 측정이 진실(§4-6 재확인).
  - **preview_click(합성 클릭)이 인라인 리스너를 못 깨우는 경우** 있었음 → `preview_eval` 로 `el.click()` 직접 호출하면 정상 동작 확인됨(실제 사용자 클릭은 문제없음).
  - 영상 추가/교체 시 **`youtube oembed`로 임베드 가능 먼저 확인**(200=OK). `VideoModal` 에 videoId 만 넘기면 됨.

---

## 🔖 (이전) 세션 이어받기 (2026-06-11 2차, 가이드 풀버전 재반영 — '하는 일' 박스 분산 + 신규 스티커)

이번 세션 작업은 **커밋 86a003c master 푸시 = Vercel 라이브**(파일 10개).

- **가이드 = `web/site-renewal/{피자클립,피클}guide.png`(1500×6000 원본, gitignore)**. 읽을 때 `sips -c 1000 1500 --cropOffset (i*1000) 0` 로 6조각씩 잘라 Read. 빨간 테두리 박스 = 콘텐츠 패널, 그 주변에 스티커.
- **피자 페이지 — 기능 본문 3개를 색 띠 패널에 1개씩 분산**(`features[]`):
  - peach=기능1(자동저장, `.featpanel--accent` 제목만 빨강) / yellow=기능2(단축키 소환) 아래 **I'm a PizzaClip + 컬러 하이피자(`mascot-hi.png` 신규)** 줄 / green=기능3(로컬보안) **패널이 노랑/초록 경계 걸침**(`.panel--straddle` 음수 margin-top) + 아래 **흑백 하이피자·원형뱃지** 줄.
  - coral=광고판(`billboard.jpg`)+자판기(`pizza-store.jpg`) 흰테두리 스티커 + **크라프트 원형 `badge-kraft.png`(Another Tasty Clip, 신규)**.
  - **박스 D = 기존 '피자클립이 하는 일' 아이콘 4개 복원**(`classicFeatures[]`, ⌘C 무한보관소·1초 컷·한영전환·로컬보안). 단축키 띠(peach) 맨 위에 두고 **green/peach 경계 걸침**(`.bandwrap .features` 음수 margin-top). 그 위 **스캘럽 PIZZA CLIP `badge-scallop.png`(신규) + CLIPBOARD 타원** 뱃지 줄.
- **피클 페이지**:
  - **히어로 이미지 → PIC/KLE 그린 포스터 `hero-poster.jpg`**(원본 `피클 메인 페이지 상단 이미지.png`). h1 문구는 **사용자 직접 수정**("…반복되는 삽질 고쳐드립니다").
  - **기능 본문 3개를 올리브·블루·샌드 패널에 1개씩**(`pickleFeatures[]`, `.featpanel`).
  - **가이드 X표시 섹션 자리 = 이모지 4개 '피클이 하는 일'**(`picklePoints[]`: 🫙 무한보관소 · ⚡️ 1초편집 · 🍱 슥-꺼내기 · 🔒 철통보안), 올리브 띠.
  - 샌드 아래 **맥북 닌자 피클 `mascot-laptop.png` + 파란 스케이트 뱃지 `badge-skate.png`(둘 다 신규)** 줄. 단축키는 **크림 띠로 이동**, 위에 **I'm a PICkle `sticker-imapickle.png`(신규) + 스냅툴** 줄.
  - **기능 박스 3개 길쭉하게**: `.featpanel { min-height: clamp(240px,23vw,300px); display:flex; flex-direction:column; justify-content:center }` → 185px→294px(데스크톱), 내용 세로 가운데. (가이드 비율 맞춤)
  - **경계 간격 조정**: 1번 올리브↔블루 넓힘(`#pk-start` padding-bottom `clamp(13rem,18vw,16rem)`), 2번 샌드↔올리브 줄임(`.band--sand` padding-bottom↓·`#pk-features` padding-top↓), 3번 올리브↔크림 약간 넓힘(`#pk-shortcuts` padding-top↑). 스케이트 뱃지 **z-index:4**(패널 위로).
- **신규 이미지 7종**(원본 트림+리사이즈+FASTOCTREE 경량화, 9~83KB; 히어로만 290KB jpg): `pizza/{badge-kraft,badge-scallop,mascot-hi}.png`, `pickle/{badge-skate,hero-poster.jpg,mascot-laptop,sticker-imapickle}.png`. **+ 지난 세션 미완 해결**: 흑백 하이피자 `mascot-hi-bw.png`를 사용자 흑백본 `site-renewal/피자클립 캐릭터/하이피자 복사본.png`로 교체.
- **검증**: `npm run build` 5페이지 통과 · 데스크톱+모바일(375) 가로 오버플로 0 · 콘솔 에러 0.
- **다음 세션 후보**: (1) 홈화면 아이콘(apple-touch/android-chrome) 아직 전체 🍕. (2) 영문 페이지. (3) how-to·info 새 톤 리디자인. (4) 스티커 미세정렬은 가이드 풀버전 기준.
- **이어받기 팁(이번 세션 추가)**:
  - **`.bandwrap .panel { margin:0 }` 우선순위 함정**: 패널 margin override는 같은 깊이 선택자(`​.bandwrap .panel--straddle`, `.bandwrap .features`)로 해야 먹힘. 단순 `.panel--straddle`은 무시됨.
  - **패널 길게 = `min-height` + flex column `justify-content:center`** (내용 위 쏠림 방지, 세로 가운데).
  - 패널이 색 띠 경계에 걸치게 = **음수 `margin-top`**(DOM 뒤 띠가 위에 그려지므로 다음 색 위로 올라감). px가 아니라 `calc(-1*띠padding - Nrem)`로.
  - 스티커 위치=각 페이지 `<style>`의 `.s-*`(left/right·top/bottom·`--sw`크기·rotate). 흐름배치 스티커 줄(`.stickerline`)은 모바일 안전(절대배치 X). 피클 경계 스티커는 `--pk-gap-pt` 연동.
  - **`clamp(min,val,max)`는 반드시 min<max**(min>max면 값이 min 고정돼 반응형 깨짐).
  - preview 측정 글리치: 네비게이션 후 `innerWidth/clientWidth=0` 나오면 `preview_resize`로 한 번 리셋하면 정상화. 긴 페이지는 뷰포트 높이를 docH로 키워 한 번에 캡처.

> ℹ️ 워킹트리 잔여(이번 세션 무관, 커밋 안 함): 앱(Swift) 변경분, 디자인 원본(`web/guide/**`, `guide/**`, `web/site-renewal/**` — 빌드 무관 참고 자산), `.claude/settings.local.json`.

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
│   │   ├── Navbar.astro           # 피자 옐로우 네비 (HOME→/pizzaclip / HOW TO / INFO + Download). 무줄바꿈+clamp
│   │   ├── Footer.astro           # 피자 네이비 푸터. 인트로·홈·사용법·깃허브 + 소셜
│   │   ├── NavMinimal.astro       # ★신규 미니멀 네비. theme="intro"(크림 알약+JAM) / "pickle"(크림 바+PICKle)
│   │   ├── SocialIcons.astro      # ★신규 인스타·스레드·깃허브 묶음(틸 테두리 버튼). github prop 으로 레포 분기
│   │   ├── PickleFooter.astro     # ★신규 피클 푸터(진한 올리브 그린). 인트로·피자클립·깃허브
│   │   ├── Button.astro           # 알약 버튼 3종 (primary/secondary/tertiary) — 피자/서브페이지 전용
│   │   ├── Card.astro             # 카드 2종 (menu=옐로우 / white=흰) — how-to/info 에서 사용
│   │   └── SliceDivider.astro     # 피자 누적 디바이더 (현재 미사용 — 리뉴얼 후 .panel 로 대체)
│   ├── pages/                     # ── 리뉴얼(2026-06-09) 후 구조 ──
│   │   ├── index.astro            # 루트(/) = 인트로 선택화면(피자/피클). site="intro" 슬레이트블루
│   │   ├── pizzaclip.astro        # 피자클립 홈(/pizzaclip). 색 띠 섹션 + 스티커 콜라주. site="pizza"
│   │   ├── pickle.astro           # 피클 홈(/pickle) 단일 페이지. site="pickle". 출시예정(비활성 다운로드)
│   │   ├── how-to.astro           # 사용법(디자인 유지). 네비 HOME 만 /pizzaclip 로 갱신됨
│   │   ├── info.astro             # 정보(디자인 유지). 전체 버전 릴리스노트 + Team JAM 소개
│   │   └── blog/                  # 블로그 — 폐기됨(2026-06-01), 미연결. 차후 파일 정리 대상
│   ├── content/blog/hello.md      # 블로그 작성 템플릿 (draft:true)
│   ├── content.config.ts          # Astro Content Layer (glob loader) — md 1개 떨구면 자동 등장
│   └── styles/{tokens,fonts,global}.css  # 디자인 토큰·@font-face·리셋
├── middleware.js                 # Edge 미들웨어: /appcast.xml 노크 → KV INCR (DAU 집계, §5-5)
├── api/stats.js                  # Vercel 함수: /api/stats?key= → 최근 30일 노크 수 JSON
├── public/
│   ├── img/{billboard.jpg, pizza-store.jpg, storefront.jpg,   # 사진(차콜 2px 테두리)
│   │        slice-1~4.png, jam-logo.png}                       # 피자 디바이더 4종 · JAM 로고
│   ├── fonts/{RIDIBatang.woff2, OSP-DIN.woff2}
│   ├── appcast.xml                # Sparkle 피드 (앱 release.sh 가 관리)
│   └── robots.txt                 # AI 크롤러 허용 (sitemap 줄은 통합 후 주석 해제 예정)
└── guide/                         # 디자인 원본 에셋 (design.md=SSOT, *.png/jpg 목업·소스)
```

- **🌐 i18n(2026-06-14 추가) — 어디를 고치나**:
  - `src/i18n/ui.ts` = 중앙 헬퍼(`Lang`·`ROUTES`·`href(lang,key)`·`enHref`·`ui[lang]` UI문자열·`siteMeta` 메타기본값). `src/i18n/{intro,pizza,pickle,info}.ts` = 페이지별 카피 사전(`ko`/`en`).
  - `src/components/pages/{Intro,Pizza,Pickle,Info}Page.astro` = **마크업+CSS 공유 컴포넌트**(한·영 공용, `lang` 프롭). ← **디자인/레이아웃 수정은 여기서만**.
  - `src/pages/*.astro`(ko) + `src/pages/en/*.astro`(en) = `<XxxPage lang=… />` 래퍼만.
  - 내부 링크는 항상 `href(lang, "intro|pizza|pickle|info")` 사용(영문에서 `/en/` 자동). how-to 는 한국어 전용(영문·토글·hreflang 없음).
- **디자인 SSOT**: `web/guide/design.md` (색 5종·폰트 3종·버튼·카드·🍕디바이더 규칙). 토큰 값 헷갈리면 여기 따름.
- **컬러**: 크림 `#FCF6EF` / 벽돌빨강 `#A2371F`(포인트·CTA) / 피자옐로우 `#FFB703`(메뉴·카드) / 네이비 `#102138`(제목) / 차콜 `#333`(본문).
- **폰트**: Pretendard(한글 본문, CDN dynamic-subset) / 리디바탕(감성·블로그 본문, self-host) / OSP-DIN(영문 로고·메뉴·버튼, self-host).

## 3. 완료된 작업

### 2026-06-14 (i18n+AEO) — 영문 사이트 EN/KO + AEO/GEO 강화(⚠️ 미커밋·미배포)

**무엇을/왜:** 검색 노출(특히 AI 답변엔진)을 위해 ① 지난 AEO 작업의 미흡분을 보강하고 ② 사이트 전체를 한국어/영어 2개국어로 만듦. 상단바 깃허브 오른쪽에 EN/KO 토글, 영문 4페이지(인트로·피자클립·피클·인포 / how-to 제외).

- **i18n 아키텍처**: Astro 내장 i18n(ko 기본=루트, en=`/en/`, `prefixDefaultLocale:false`). 4개 페이지를 `lang` 받는 **공유 컴포넌트**(`src/components/pages/*Page.astro`)로 리팩터링 → 한·영이 마크업·CSS 1벌 공유, 텍스트만 `src/i18n/*` 사전에서. 중앙 헬퍼 `src/i18n/ui.ts`(`href()`/`ui`/`siteMeta`). 자세한 위치는 §2 i18n 항목.
- **EN/KO 토글**: `SocialIcons.astro` `.langtog`(틸 두칸 알약), 현재 페이지의 반대 언어판으로. `koPath` 있을 때만 노출(how-to 제외). 데스크톱·375px 무오버플로.
- **AEO/GEO**: hreflang(ko/en/x-default)·og:locale(+alternate)·`<html lang>`·JSON-LD `inLanguage` 언어별, `@astrojs/sitemap` i18n alternate, SoftwareApplication 강화(featureList·softwareVersion·operatingSystem"macOS 13.0+"·offers·screenshot·softwareHelp), Organization logo+sameAs(인스타·스레드 추가), robots `max-image-preview:large`, **llms.txt 영문·양앱·FAQ 전면개정**.
- **검증**: `npm run build` 9페이지 통과·콘솔 0, 프리뷰로 한국어 회귀 0·영문 4페이지·토글 양방향·모바일·산출물 hreflang/sitemap 직접 확인.
- **남은 것/주의**: 커밋·푸시 안 함(배포 전). 영문 튜토리얼 영상·영문 전용 OG 이미지는 차후(현재 한·영 공용).

### 2026-06-14 — 튜토리얼 영상 팝업 + 피클 노크 카운트(라이브, 커밋 37d33e1·ca3ac11)

**무엇을/왜:** ① 두 서브페이지 히어로의 다운로드 버튼 옆에 '튜토리얼' 버튼을 달아, 누르면 유튜브 사용법 영상이 팝업으로 뜨게 함(앱 처음 쓰는 사람용 진입점). ② 매일 보는 DAU 노크 카운트가 피자앱만 세고 있던 것을 피클앱까지 확장.

- **VideoModal.astro(신설)**: 어두운 오버레이 + 16:9 유튜브 iframe 팝업. `data-open-video` 버튼이 열고, ✕/배경/ESC 로 닫음(닫을 때 `src="about:blank"` 로 재생 정지). 클릭 전엔 미로드, 열 때 `autoplay=1`. 피자=`9nhJBjU_JtQ`, 피클=`HJ1hLgfnWfQ`.
- **피자/피클 페이지**: 히어로에 '튜토리얼' 버튼 추가(피자=`Button` secondary, 피클=`.pill--tut` 신규) + 페이지 끝에 `<VideoModal>` 1개. 다운로드와 같은 크기(세모 ▶ 제거).
- **Button.astro**: `...rest` 스프레드로 `data-*` 통과 허용(기존 무영향).
- **노크 카운트**: `middleware.js` 가 `/pickle/appcast.xml` 도 감시, 앱별 키 분리(피자 `knock:` 유지, 피클 `knock:pickle:`). `api/stats.js` 에 `apps.{pizza,pickle}`+`combined` 추가, 최상위는 피자 기준 호환 유지. 피클은 배포 시점부터 0 시작(소급 불가).

**교훈(다음 세션 주의):**
- 유튜브 팝업처럼 **`position:fixed` 오버레이는 preview_screenshot 스크롤 글리치로 하단에 잘려 보임** → `preview_resize`(desktop) 리셋 후 `getBoundingClientRect` 측정이 진실.
- **preview_click 합성 클릭이 인라인 리스너를 못 깨우면** `preview_eval` 로 `el.click()` 직접 호출해 검증(실사용 클릭은 정상).
- 영상 추가/교체 = `youtube oembed` 200 확인 후 videoId 만 `VideoModal` 에 전달.

### 2026-06-11 (2차) — 가이드 풀버전 재반영: '하는 일' 박스 분산 + 신규 스티커(라이브, 커밋 86a003c)

**무엇을/왜:** 사용자가 가이드 풀버전(`web/site-renewal/{피자클립,피클}guide.png`, 1500×6000)을 새로 그려, 빨간 박스 구조 그대로 콘텐츠를 재배치. 핵심은 **'하는 일' 기능 본문을 한 카드에 몰아넣지 않고 각 색 띠 패널에 1개씩 분산**한 것.

- **피자**(`pizzaclip.astro`): 기능 3개(`features[]`)를 peach(자동저장)·yellow(단축키 소환)·green(로컬보안) 패널에 분산. green 패널은 노랑/초록 경계 걸침(`.panel--straddle`). yellow 아래 I'm a PizzaClip+컬러 하이피자, green 아래 흑백 하이피자+원형뱃지 줄. coral에 광고판·자판기 사진+크라프트 원형. **박스 D = 기존 '피자클립이 하는 일' 아이콘 4개**(`classicFeatures[]`)를 단축키 띠 위에 복원(green/peach 경계 걸침) + 스캘럽·CLIPBOARD 뱃지.
- **피클**(`pickle.astro`): 히어로를 PIC/KLE 포스터로 교체(h1 문구는 사용자 수정). 기능 3개(`pickleFeatures[]`)를 올리브·블루·샌드 패널에 분산. 가이드 X표시 섹션 자리에 **이모지 4개 '피클이 하는 일'**(`picklePoints[]`). 샌드 아래 맥북피클+스케이트뱃지, 단축키는 크림 띠로 이동(위에 I'm a PICkle+스냅툴). **기능 박스 3개 `min-height`로 길쭉하게**(185→294px) + 내용 세로 가운데. 경계 간격 1·2·3번 조정, 스케이트 뱃지 z-index:4.
- **신규 이미지 7종** + 흑백 하이피자(`mascot-hi-bw.png`) 사용자 흑백본으로 교체(지난 세션 미완 해결). 전부 알파 트림+리사이즈+FASTOCTREE 경량화.

**교훈(다음 세션 주의):**
- **`.bandwrap .panel { margin:0 }` 우선순위** — 패널 margin을 override하려면 같은 깊이 선택자(`.bandwrap .panel--straddle`)로. 단순 클래스만으론 안 먹힘.
- **패널을 길게 = `min-height` + flex column `justify-content:center`**. 패널을 색 경계에 걸치게 = 음수 `margin-top`(`calc(-1*띠padding - Nrem)`).
- 가이드 원본이 6000px 세로라 **`sips`로 1000px씩 6조각 크롭** 후 Read 했음.
- preview 네비게이션 직후 `clientWidth=0` 글리치 → `preview_resize`로 리셋하면 정상화.

### 2026-06-11 — PICkle 표기 통일 + 스티커/콘텐츠 정비 + 페이지별 파비콘(라이브, 커밋 5bf3f80·9b2bcf2·214f95d)

**무엇을/왜:** 사용자가 localhost 보며 단계별로 수정 요청 → 브랜드 표기 일관화, 콘텐츠 카피 교체, 사진을 스티커로 바꿔 가이드처럼 배치, 페이지별 파비콘. 가이드 기준 = `web/site-renewal/{피자클립가이드,피클가이드}.png`(원본 풀버전).

- **PICkle 표기 통일**(`5bf3f80`): 화면에 보이는 `PICKle`(대문자 K) 전부 `PICkle`로. 위치 — `NavMinimal`(피클 로고 line37·피자 크로스링크 line21), `PickleFooter`(브랜드·카피라이트), `info.astro`(🥒 릴리스노트 헤딩·팀소개), `BaseLayout`(intro 메타 타이틀 2곳), `consts.PICKLE_TITLE`. (※ `.astro`/`css` **주석엔 PICKle 잔존** — 화면 무관이라 그대로 둠.)
- **피자 페이지 콘텐츠**(`5bf3f80`): ① 다운로드 카드 제목 🍕 제거 ② '피자클립이 하는 일' = 기능 3개로 교체(아이콘 그리드 → **번호 뱃지+헤드라인+본문** 세로 리스트 `.feature-list`/`.feature__num`/`.feature__body`; 한/영 전환 기능 항목 삭제) ③ 'I'm a PizzaClip' CSS 텍스트 스티커 → **이미지**(`sticker-imapizzaclip.png`).
- **피클 페이지**(`5bf3f80`): **'피클이 하는 일' 신규 섹션**(올리브 띠, 회색 CTA 바로 위, 피자와 동일 번호리스트 톤, `pickleFeatures` 3개).
- **INFO 하단**(`5bf3f80`): "보러가기" 텍스트 링크 → **인트로 카드 축소 버튼**(`/img/intro/card-{pizza,pickle}.png`, `.info__appbtn`).
- **피클 올리브↔블루 간격 + 스티커**(`9b2bcf2`): 두 박스 사이 좁아 스티커가 박스에 겹치던 것 → `#pk-start` padding-bottom↑로 간격 확대, `.band--blue{--pk-gap-pt}` 변수 도입해 s-easy/s-snap/s-jar `top`을 `calc(-1*var(--pk-gap-pt) - N)`(경계선 기준, 폭 무관). 모바일은 s-easy 1개만(간격 축소).
- **피자 사진 2장 → 스티커**(`9b2bcf2`): coral 광고판·green 매장이 `<figure.photo-frame>`(흐름배치)였음 → **`<img.sticker.s-billboard/.s-store>`**(절대배치, 흰 테두리·기울임). 중복 figcaption 제거(글자는 이미지에 박혀있음). coral에 `bandwrap--tall`, `.bandwrap--tall` min-height 320/33vw/440으로↑. **모바일 `@media`에서 `position:static`+가운데**로 안 잘리게.
- **띠 높이↑**(`9b2bcf2`): 피자 `.band` padding-block `clamp(4.75rem,8.5vw,7rem)`, 피클 `clamp(5rem,9vw,8rem)`.
- **clamp 오타 수정**(`9b2bcf2`): `min>max`(값이 min으로 고정돼 반응형 깨짐) 2곳 — 피클 `.band`, 피자 `.s-vending`.
- **페이지별 파비콘**(`214f95d`): `BaseLayout`에 `const faviconSvg = site==="pickle" ? "/favicon-pickle.svg" : site==="intro" ? "/favicon-jam.svg" : "/favicon-pizza.svg"` + `<link rel="icon" type="image/svg+xml" href={faviconSvg}>`(favicon.ico 폴백 위에 추가). 피자🍕·피클🥒 = 이모지 SVG(`<text>` 92px), JAM = 로고 PNG 64px를 base64로 `<image>` 임베드한 SVG. **how-to·info도 자동 분기**(site=pizza→🍕, site=intro→JAM).

**교훈(다음 세션 주의):**
- **`clamp(min, val, max)`는 min<max 필수.** min>max면 브라우저가 min으로 고정 → 반응형이 죽고 모바일까지 큰 값 박힘. 스티커 크기/띠 높이 clamp 만질 때 항상 확인. (이번에 사용자가 시각 조정하다 2곳 발생.)
- **사진을 절대배치 스티커로 바꾸면 그 띠가 높이를 잃음** → `bandwrap--tall`(min-height)로 받치고, **모바일에선 `position:static`으로 되돌려** 안 잘리고 가로 오버플로 안 나게.
- **피클 경계 스티커는 `--pk-gap-pt` 연동** — 올리브/블루 간격(`#pk-start` padding) 바꾸면 스티커 위치도 따라 움직이니 같이 확인.
- **이모지 파비콘은 SVG `<text>`가 최선**(바이너리 생성 불필요, 모든 모던 브라우저 탭에서 우선 사용). 로고처럼 래스터면 PNG를 SVG `<image>`에 base64 임베드하면 SVG 취급돼 안정적.
- 파비콘은 **브라우저 캐시가 강함** → 확인 시 새 탭/시크릿창/탭 재오픈.

### 2026-06-10 — 🚀 2차 개편 + 피클 1.0 출시(라이브)

상세는 상단 **🔖 세션 이어받기** 블록 참고. 한 줄 요약: 상단바 전 페이지 `NavMinimal` 통합(+크로스링크 `↗`+ⓘ 인포버튼), INFO 인트로풍 재구성(+피클 릴리스노트), **피클 1.0 다운로드 활성화**(자체호스팅 `/pickle/PICkle-1.0.0.dmg` + appcast 커밋), 피클 단축키 섹션(실제 `⇧⌥S/D/A/F`), JAM 로고 회색·피클 로고 Alfa Slab One·푸터 인라인 아이콘 복원, 띠 높이↑ + 스티커 재정렬. 교훈: **띠 padding 키우면 카드가 가운데로 밀려 boundary-straddle 스티커가 다 헐거워짐** → 높이는 적당히(피자 6rem/피클 6.5rem) + 스티커 top% 재조정. 미세조정은 가이드 `web/guide/renewal/pizzaclip.png` 기준.

### 2026-06-09 — 🎨 사이트 전체 리뉴얼(피클 앱 추가 + 풀 리디자인)

**무엇을/왜:** 피클(PICKle, 맥 스크린샷 정리 앱)이 새로 만들어져, 두 앱을 함께 소개하려고 사이트 구조를 바꾸고 전체를 새 비주얼로 리디자인. 디자인 가이드 3종(`site-renewal/{사이트인트로,피자클립가이드,피클가이드}.png`, **283MB 원본은 gitignore** — 축소본 `guide/renewal/*.png` 만 커밋)을 거의 그대로 구현.

**라우팅 변경(중요):**
- `/` = **인트로 선택화면**(신설) — 피자/피클 두 앱 카드. 기존 피자 홈을 밀어내고 루트 차지.
- `/pizzaclip` = **피자클립 홈**(기존 `/` 콘텐츠를 새 디자인으로 이전).
- `/pickle` = **피클 홈**(신설, 단일 페이지).
- `/how-to`·`/info` = **디자인 유지**(피자클립용). 네비/푸터 HOME 링크만 `/pizzaclip` 로 갱신(`consts.ts` `PIZZA_HOME`).
- ⚠️ 루트가 바뀌었으므로 기존 `pizza-clip.com/` 북마크/SEO 는 인트로로 가고, 피자 홈은 한 단계 안으로 들어감. appcast(`/appcast.xml`)·DAU 미들웨어는 무관(정적 파일 그대로).

**구조/구현:**
- **BaseLayout `site` prop**(`"pizza"|"pickle"|"intro"`)으로 네비/푸터/메타(JSON-LD·OG·title) 분기. 기본 `"pizza"`라 how-to/info 무영향.
  - pizza → Navbar+Footer / pickle → NavMinimal(pickle)+PickleFooter / intro → NavMinimal(intro), 푸터 없음.
- **색 띠 섹션 + 스티커 콜라주** 패턴: 각 섹션 `.band`(색 배경) 안에 `.panel`(크림 카드+차콜 오프셋 그림자=빈 콘텐츠 카드 채움) + `.sticker`(절대배치 데코 이미지, 캐릭터·뱃지·사진). global.css 에 `.band/.panel/.sticker/.photo` + 스크롤등장 유틸 추가.
- **팔레트**(tokens.css, 가이드 좌측 픽셀에서 추출): 인트로 `--intro-bg #7499B2`/`--intro-nav #F0EBEB`/`--teal #0A807B`. 피자 띠 `--pz-peach #F2BC7E`/`--pz-coral #F1765C`/`--pz-yellow #FFDC83`/`--pz-green #468365`. 피클 `--pk-olive #B0BB51`/`--pk-olive-ink #798904`/`--pk-blue #97B7CD`/`--pk-sand #E5BD68`/`--pk-gray #D5D5D5`/`--pk-green #2F5E2C`/`--pk-red #BC3F24`.
- **자산**: `site-renewal/` 하위 원본 PNG(스티커·캐릭터·뱃지·카드)를 알파 트림+리사이즈+FASTOCTREE 양자화(pngquant 없음)로 경량화 → `public/img/{intro,pizza,pickle}/`. 사진(billboard/pizza-store/storefront)은 기존 것 재사용. hero-poster 는 투명0%라 jpg 변환. 페이지별 OG: `og-intro.jpg`(인트로 전체)/`og-pickle.jpg`(피클 히어로)/`og-home.jpg`(피자 히어로, 재생성).
- **피클은 아직 미출시** → 다운로드 버튼은 **'출시 예정'**(빗금 비활성 span) + '출시 알림 받기'(인스타 링크). `consts.ts` `PICKLE_RELEASED=false`. 출시되면 `PICKLE_RELEASED=true` + `PICKLE_DOWNLOAD_URL`(이미 `pickle.dmg` 가정값) 만 확인. 빈 `public/pickle/appcast.xml` 는 그대로.
- **인터랙션**: 스크롤 등장(`data-reveal`, IntersectionObserver, **점진적 향상** — JS/IO 없으면 항상 보임, reduced-motion 존중), 카드/버튼 호버 리프트.

**교훈(다음 세션 주의):**
- **`.band { overflow: clip }` 함정** ⚠️: 양축을 다 자르면 **위로 삐져나와 이전 띠에 얹히는 스티커가 세로로 잘려 사라진다**. → `overflow-x: clip` 만 써서 가로 스크롤만 막고 세로 겹침은 허용.
- **스티커 겹침 방향 규칙**: 띠는 DOM 순서대로 칠해지므로 **아래로 삐지는 스티커(bottom:음수)는 다음 띠 배경에 가려진다.** 항상 **다음 띠에서 `top:음수`로 위로 삐져나오게** 하거나 띠 안쪽(양수 offset)에 둘 것.
- **preview_screenshot 스크롤 리셋 글리치 재확인**: 스크롤 후 캡처해도 위치가 어긋나 푸터 아래 빈 공간처럼 보일 수 있음 → **DOM 측정(footerBottom==docH, scrollWidth==clientWidth)이 진실.** 긴 페이지는 **뷰포트 높이를 docH 만큼 키워 한 번에 캡처**가 안전(단 뷰포트가 docH보다 많이 크면 캡처가 축소돼 작게 나옴 → docH 에 근접하게).
- **스티커 위치는 '띠'가 아니라 '카드(텍스트 박스)' 기준**: 각 띠 안에 `.bandwrap`(position:relative, max-width=카드폭, 가운데정렬)을 두고 스티커를 그 안에 절대배치 → 가이드처럼 카드 모서리에 정확히 붙음. 띠 전체(left:2%/right:2%)에 붙이면 양쪽 끝으로 퍼져 어긋난다(2026-06-09 수정).
- **⚠️ Astro dev(HMR) scoped-style stale 함정**: `.astro` 의 `<style>` 을 크게 갈아엎으면 **HTML(클래스)은 갱신되는데 scoped CSS 가 안 따라와** 규칙이 통째로 안 먹는 일이 있음(증상: 스티커가 전부 좌상단에 기본크기로 쌓임, `getComputedStyle` 에 `--sw`/left/top 미적용, `document.styleSheets` 에 해당 규칙 없음). **빌드 dist 엔 정상**. → preview_stop + preview_start 로 **dev 서버 재시작**하면 해결. CSS 검증은 항상 재시작 후 또는 `getComputedStyle` 로 확인.
- 검증: `npm run build` 통과(5페이지), 3페이지 데스크톱+375px 가로 오버플로 0, 스티커/카드/사진 가이드 대조 일치 확인.

**남은 것**: 피클 정식 출시 시 다운로드 활성화 / (선택) how-to·info 새 톤 리디자인 / 블로그 잔여 파일 정리.

### 2026-06-03 — HOW TO 페이지 대개편 + 동적 OG + 사용법 영상 인트로

**무엇을 했나 (모두 master 푸시·라이브):**
- **HOW TO 실사진 개편**(`d63748a`,`b35d274`): 설치 3단계에 실제 화면 사진(Applications 드래그 / '열기' 클릭 / 손쉬운 사용 권한 — `guide/howto_guide/{1-2,1,2}.png` → `public/img/howto-step-1~3.jpg`), 데모 GIF, FAQ 5문항 + **FAQPage 구조화 데이터(AEO)** 추가. 단계 레이아웃은 번호→제목→설명→사진 세로 가운데 정렬.
- **히어로 투명 PNG**(`c38f4bb`): 배경 제거된 맥북 목업(`guide/howto_guide/0-dive.png`) → `public/img/howto-hero.png`(투명 유지 위해 png, 프레임 제거).
- **페이지별 동적 OG 이미지**(`f5b2c8c`): `guide/og_image{1,2,3}` → 1200×630 최적화. HOME=지하철 광고판(`og-home.jpg`), HOW TO=맥북 목업 크림합성(`og-howto.jpg`), INFO=자판기 간판(`og-info.jpg`). BaseLayout 기본 og를 `og-home.jpg`로, how-to/info는 `image` prop 지정.
- **데모 GIF**(`7784ff8`,`82abef0`): 두 개 중 왼쪽(메뉴바 차오름)만 사용, 작게(170px) + ffmpeg 팔레트 2-pass로 경량화(`public/img/howto-demo-1.gif`).
- **사용법 영상 + 인트로 연출**(`4e6bfb8`→`ab3496e`): HOW TO 상단에 사용법 영상 임베드. 연출은 시행착오 끝에 **"제자리 크로스페이드"** 로 확정 — 히어로(글자+맥북)가 sticky로 한 자리에 고정된 채 스크롤하면 사르륵 사라지고 **같은 자리에 영상이 떠오름**(밑에서 올라오는 슬라이드 ❌), 그 아래 본문이 이어짐. 영상 나타날 때 **음소거 자동재생**. (중간에 커튼·풀스크린 색 스냅 패널을 시도했다 "과하다"고 전부 롤백 → 크로스페이드가 사용자 확정안.)
- **영상 소스 우여곡절**(`29bf111`,`b73c23d`,`3fcef8d`,`3897c32`): 유튜브 채널 삭제 → 자체 호스팅 mp4 임시 → 채널 복구되어 **새 유튜브 임베드 `9nhJBjU_JtQ`**("피자클립🍕튜토리얼")로 최종 복귀. 영상 표시 크기 100%, 제목 "피자클립🍕튜토리얼".

**현재 HOW TO 구조**: (인트로: 히어로↔영상 크로스페이드) → 설치 3단계(사진) → 데모 GIF → 단축키 표 → 팁 → FAQ.

**교훈 (다음 세션 주의):**
- **preview(헤드리스)는 `requestAnimationFrame`/`IntersectionObserver`/CSS transition 이 진행 안 됨** → 스크롤 연출은 rAF 비의존(`scroll` 이벤트 + `getBoundingClientRect`)로 짜고, 검증은 DOM 측정(opacity/transform 목표값을 transition 끄고 읽기)으로. preview_screenshot 은 스크롤을 맨 위로 리셋하는 글리치 있어 스크롤 위치 캡처가 빈 화면/엉뚱하게 나옴 → DOM 측정 신뢰.
- **git add 함정(2회 발생)**: `git rm` 으로 이미 스테이징한 삭제 파일을 `git add` 에 또 지정하면 pathspec 불일치로 **git add 전체가 실패** → 정작 코드 변경이 스테이징 안 된 채 커밋되어 핵심 변경 누락. **삭제는 git rm 으로 끝내고 add 목록에 다시 넣지 말 것.** 커밋 후 `git show --stat` 로 의도한 파일이 들어갔는지 항상 확인.
- **유튜브 임베드 가능 여부**는 `curl -s -o /dev/null -w "%{http_code}" "https://www.youtube.com/oembed?url=<url>&format=json"` 로 사전 확인 — **200=공개/임베드 OK, 404/401=비공개·임베드 차단**(임베드 페이지 자체는 200이라 속지 말 것). 비공개면 코드 문제 아님 → YouTube Studio 에서 공개/일부공개 + 퍼가기 허용.
- **GIF/mp4 경량화**: gif=ffmpeg 팔레트 2-pass(`palettegen`+`paletteuse=dither=bayer`), mp4=`-c:v libx264 -crf 30 -movflags +faststart -pix_fmt yuv420p`. **원본 대용량 소스(`guide/howto_guide/*`, `guide/og_image*`, `guide/튜토리얼.mp4`)는 레포 비대화 방지로 미커밋** — 로컬에만 보관, 최적화 산출물만 `public/` 에 커밋.

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

1. **INFO 릴리스노트 유지** — 새 버전 낼 때 `info.astro` 의 `releases` 배열에 항목 추가(현재 1.0.0~0.1.1 수기). TeamJAM 소개 문구도 원하면 다듬기.
2. **GA4 다운로드 전환 추적(선택)** — 현재 GA4는 페이지뷰만. 다운로드 버튼 클릭 이벤트(`gtag('event', ...)`) 미설정.
3. **(선택)** 인트로 "커튼" 연출, 카피/이미지 추가 다듬기.
4. **동적 OG 이미지** (2026-06-02 요청) — 현재 OG는 `BaseLayout.astro`의 단일 정적 이미지(`og:image`/`twitter:image`, line 95/101). 사용자 불만: 링크 붙여넣을 때마다 **항상 같은 이미지**라 마케팅 효율↓. → "매 붙여넣기마다 랜덤"으로 만들고 싶어함.
   - ⚠️ **제약(중요)**: 소셜 플랫폼(카톡/iMessage/트위터/디스코드)은 **URL 단위로 OG 이미지를 캐시**함. 같은 `pizza-clip.com` 주소면 누가 붙여도 캐시된 같은 이미지가 나옴 → **"매 붙여넣기마다 다른 이미지"는 단일 URL로는 불가능.** 이 점을 사용자에게 다시 확인하고 기대치 맞출 것.
   - 현실적 구현안: ① **동적 생성 OG** — Vercel OG(`@vercel/og`) 또는 Satori 로 버전/카피/문구를 이미지에 자동 렌더(릴리스·캠페인마다 새 비주얼 손쉽게). Vercel 호스팅이라 궁합 좋음. ② **페이지별 OG** — 랜딩/INFO/HOW-TO 각 페이지에 다른 `image` prop 전달(`BaseLayout`이 이미 `image` 파라미터 받음 → 페이지에서 넘기기만 하면 됨).
   - 관련 파일: `src/layouts/BaseLayout.astro`(`ogImage` 구성부 line 25/39/95/101), 정적 이미지는 `public/`.
5. ✅ **완료 (2026-06-05, 라이브 검증됨) — 📊 활성 유저(DAU) 카운팅 = appcast 노크 세기**. 설치본 Sparkle 이 **하루 1번** `pizza-clip.com/appcast.xml` 을 두드림(업데이트 확인) → **그 노크 수 ≈ 일일 활성 기기 수**. **(2026-06-14 갱신: 피클앱 `/pickle/appcast.xml` 도 추가 집계 — 앱별 키 분리. `/api/stats` 응답에 `apps.{pizza,pickle}`+`combined` 추가, 최상위는 피자 기준 호환 유지. §3 2026-06-14 참고.)**
   - **구현(Edit 함수 대신 Edge 미들웨어 채택 — 더 안전)**: `web/middleware.js` 가 `/appcast.xml` 요청을 가로채 Upstash(KV)에 `knock:YYYY-MM-DD`(KST) 카운터를 **INCR**(REST `…/incr/…`, `@vercel/edge` 의 `next()`+`context.waitUntil` 로 **비동기**). 응답은 **기존 정적 `public/appcast.xml` 그대로** 서빙 → 카운트가 실패/미설정이어도 **자동업데이트 피드 안 깨짐**. **rewrite 안 씀**(정적 파일이 있으면 vercel.json `rewrites`=afterFiles 라 안 걸림 → 미들웨어가 정답). URL·앱·release.sh **무수정**.
   - **저장소**: Upstash Redis(Vercel Marketplace, **Free** 플랜, DB명 `upstash-kv-sky-candle`, region Washington DC). `pizza-clip` 프로젝트에 prefix `KV` 로 연결 → env `KV_REST_API_URL`/`KV_REST_API_TOKEN` 자동 주입. 미들웨어는 `KV_*` 우선, `UPSTASH_*` 폴백.
   - **조회**: `https://pizza-clip.com/api/stats?key=<STATS_KEY>` → `{today, last30dTotal, byDay}` JSON(최근 30일, KST 일별). `web/api/stats.js`(Vercel Node 함수). ⚠️ **레포 public 이라** 비밀값은 코드에 두지 말고 env `STATS_KEY` 로만 보호(설정 시 `?key` 일치 필수, 미설정이면 누구나 조회).
   - **검증**: 노크 전 today=0 → `/appcast.xml` 5회 curl → today=5 (캐시 `x-vercel-cache: HIT` 여도 미들웨어 정상 카운트 확인). 단, 이 **테스트 노크 5건이 2026-06-05 에 섞여 있음**(Upstash REPL 에서 `DEL knock:2026-06-05` 로 0 초기화 가능).
   - **한계**: 방식 1(요청 수 그대로) — 기기 중복제거 없음, **대략치**. 한 기기가 하루 여러 번(재실행/수동 체크) 두드리면 중복 카운트. 정밀히 필요하면 방식 2(앱이 익명 UUID 동봉 → `SADD dau:<날짜> <uuid>` 로 유니크 집계)로 업그레이드. **무료 한도**(Upstash Free 일 10k 커맨드)는 개인 앱 규모에 차고 넘침.
   - <details><summary>(역사적) 요청 당시 메모</summary>

   - ✅ **확정 방향(방식 1, 가벼움)**: **요청 수 그대로 카운트**(익명 식별자 없음, 대략치로 충분). 정확한 기기별 중복제거(방식 2: 앱이 익명 UUID 동봉)는 나중에 필요해지면 업그레이드.
   - ✅ **확정 방향(방식 1, 가벼움)**: **요청 수 그대로 카운트**(익명 식별자 없음, 대략치로 충분). 정확한 기기별 중복제거(방식 2: 앱이 익명 UUID 동봉)는 나중에 필요해지면 업그레이드.
   - ⚠️ **핵심 제약 — URL 은 절대 바꾸지 말 것**: 기존 설치본은 SUFeedURL 이 `appcast.xml` 로 **이미 박혀있음**. 새 주소(`/api/appcast`)로 바꾸면 **앱 업데이트한 사람만** 잡힘 → **기존 사용자 누락**. 따라서 **주소는 `appcast.xml` 그대로 두고, 그 요청만 함수로 가로채는(rewrite)** 방식이어야 기존 사용자까지 즉시 카운트됨. **앱쪽 수정 0** (순수 웹 작업).
   - 구현 3요소: ① **가로채는 함수**(`appcast.xml` 요청 → 카운트 +1 후 **현재 release.sh 가 생성하는 최신 XML 내용 그대로 응답**) ② **저장소**(Vercel KV/Upstash Redis 에 `count:YYYY-MM-DD` 날짜별 카운터 INCR — Hobby 무료한도 충분) ③ Vercel **rewrite 설정**으로 `/appcast.xml` → 함수 라우팅. ⚠️ 함수가 항상 **최신 appcast 내용**을 돌려주도록 연결할 것(릴리스마다 XML 바뀜).
   - 참고: Vercel **Web Analytics**(`@vercel/analytics`, Analytics 탭 Get Started)는 **웹 페이지뷰**용이라 XML 노크는 못 셈 → 이 용도엔 부적합. (랜딩 방문자만 궁금하면 그건 그것대로 설치 가능, 단 프레임워크는 **Astro** 선택.)
   </details>

> ✅ **HOW TO 콘텐츠 강화 완료(2026-06-02)** — 히어로 목업 이미지 + 동작 데모 영상 2종 + "이런 것도 돼요" 팁 + FAQ(FAQPage 구조화 데이터 포함) 추가. 기존 설치 3단계·단축키 표는 유지.
> ✅ **AEO/GEO sitemap 완료(2026-06-02)** — `@astrojs/sitemap` 통합, 낡은 수기 `public/sitemap.xml` 제거, robots.txt 가 자동 생성본(`sitemap-index.xml`) 가리키도록 수정. JSON-LD(SoftwareApplication/WebSite/Organization)는 BaseLayout 에 이미 있었고, FAQPage 는 how-to 에 추가됨. `llms.txt` 도 이미 있음.

## 6. 작업 컨벤션

- 커밋: conventional commits(feat/style/fix/chore + `(web)` scope), 한국어 본문 2~3줄. **co-author 트레일러 없음**(단독/소규모 팀).
- **단일 브랜치(master)** 운영 — 별도 머지 단계 없음. master 푸시 = 배포.
- 수정 후 항상 `cd web && npm run build` 통과 확인. 가능하면 preview 로 데스크톱+모바일(375px) 정렬·무오버플로까지 검증.
