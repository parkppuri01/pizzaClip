# Web Handoff — pizza-clip.com (랜딩 사이트)

마지막 업데이트: **2026-06-09** (🎨 **사이트 전체 리뉴얼 — 피클 앱 추가 + 풀 리디자인**. 루트(/)=인트로 선택화면 신설, 피자클립 홈은 `/pizzaclip` 으로 이동, 피클(`/pickle`) 단일 페이지 신설. 색 띠 섹션 + 스티커 콜라주. 자세히는 §3 2026-06-09 항목. 이전: 2026-06-05 INFO v1.1.0 + GA4 전환 + appcast DAU 집계(§5-5).)

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

- **디자인 SSOT**: `web/guide/design.md` (색 5종·폰트 3종·버튼·카드·🍕디바이더 규칙). 토큰 값 헷갈리면 여기 따름.
- **컬러**: 크림 `#FCF6EF` / 벽돌빨강 `#A2371F`(포인트·CTA) / 피자옐로우 `#FFB703`(메뉴·카드) / 네이비 `#102138`(제목) / 차콜 `#333`(본문).
- **폰트**: Pretendard(한글 본문, CDN dynamic-subset) / 리디바탕(감성·블로그 본문, self-host) / OSP-DIN(영문 로고·메뉴·버튼, self-host).

## 3. 완료된 작업

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
- **preview_screenshot 스크롤 리셋 글리치 재확인**: 스크롤 후 캡처해도 위치가 어긋나 푸터 아래 빈 공간처럼 보일 수 있음 → **DOM 측정(footerBottom==docH, scrollWidth==clientWidth)이 진실.** 긴 페이지는 **뷰포트 높이를 docH 만큼 키워 한 번에 캡처**가 안전.
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
5. ✅ **완료 (2026-06-05, 라이브 검증됨) — 📊 활성 유저(DAU) 카운팅 = appcast 노크 세기**. 설치본 Sparkle 이 **하루 1번** `pizza-clip.com/appcast.xml` 을 두드림(업데이트 확인) → **그 노크 수 ≈ 일일 활성 기기 수**.
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
