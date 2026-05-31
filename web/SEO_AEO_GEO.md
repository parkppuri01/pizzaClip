# PIZZA CLIP 사이트 — SEO / AEO / GEO 정리

> 검색엔진·AI가 사이트를 잘 이해하고 인용하게 만드는 작업을 비개발자도 알게 정리.
> 스택: **Astro (정적 빌드)**, 도메인 `https://pizza-clip.com` (Cloudflare DNS → **Vercel** 호스팅).

## 용어 한 줄 정리
- **SEO**: 구글·네이버 "검색"에 잘 걸리게
- **AEO** (Answer Engine Optimization): ChatGPT·음성비서 같은 "답변엔진"이 우리 정보를 정확히 답하게
- **GEO** (Generative Engine Optimization): Perplexity·Gemini 같은 "생성형 AI"가 우리를 출처로 인용하게

---

## 이번에 적용한 것 ✅

| 항목 | 파일 | 내용 |
|---|---|---|
| 파비콘 | `public/favicon.svg` | 🍕 벡터 피자(빨강 배경+치즈 슬라이스+페퍼로니). Safari·네이버 포함 어디서나 동일 렌더 |
| robots.txt | `public/robots.txt` | 네이버 `Yeti`·다음 `Daumoa` 추가, AI봇 확장, **Sitemap 활성화** |
| 사이트맵 | `public/sitemap.xml` | `/`, `/how-to`, `/info` 등록 (정적 파일이라 의존성 없이 즉시 동작) |
| AI 요약 | `public/llms.txt` | AI 전용 사이트 요약(기능·FAQ·링크) |
| 구조화 데이터 | `src/layouts/BaseLayout.astro` | **SoftwareApplication + WebSite + Organization** JSON-LD (전 페이지) |
| 메타 보강 | `src/layouts/BaseLayout.astro` | theme-color, og:locale, twitter title/desc/image |
| 네이버 인증 | `src/layouts/BaseLayout.astro` | `naver-site-verification` 메타 자리(코드만 붙여넣으면 됨) |

> 참고: Astro는 **정적 HTML로 미리 렌더**되므로 AEO/GEO에 유리합니다(크롤러가 JS 없이 본문을 읽음). React SPA였다면 별도 프리렌더가 필요했지만 지금 구조는 그 점이 이미 좋습니다.

---

## 🔴 네이버 "robots.txt 없음" — 진단 결과

**확인 결과: 사이트는 정상입니다.** 실제로 확인해 보니
`https://pizza-clip.com/robots.txt` 는 **HTTP 200**, `content-type: text/plain` 으로
정상 응답합니다 (서버: **Vercel**. Cloudflare는 DNS만 담당하고 요청을 가로채지 않음 → 봇 차단 아님).
즉 "서버가 죽어서 못 읽는" 문제가 **아닙니다**.

그렇다면 네이버가 "없음"이라고 하는 흔한 진짜 원인은:

1. **등록한 사이트 주소(변형) 불일치** ← ⭐ 가장 유력. 실제로 확인해 보니
   `www.pizza-clip.com` 은 **DNS 자체가 안 잡힘(없는 주소)**, `http://` 는 https로 308 리다이렉트됨.
   → 네이버에 `www.` 붙여서, 또는 `http://` 로 등록했다면 robots.txt 수집이 실패합니다.
   → 서치어드바이저 등록 주소를 **정확히 `https://pizza-clip.com`** (www 없이, https) 로 맞추세요.
2. **robots.txt를 사이트 등록 *뒤에* 추가** → 네이버가 옛 결과(없음)를 들고 있음.
   → 서치어드바이저에서 **robots.txt 수집 요청(재검증)** 을 한 번 눌러 갱신.
3. (참고) **지금 라이브 robots.txt 는 옛 버전**이라 `Yeti`·`Sitemap` 줄이 아직 없음.
   아래 개선본을 **재배포(deploy)** 해야 네이버 크롤러 명시 허용 + 사이트맵이 적용됨.

### 해야 할 일 순서
1. 이번 변경분을 **Vercel에 재배포** (보통 GitHub에 push 하면 자동 배포).
2. 배포 후 브라우저로 확인:
   - `https://pizza-clip.com/robots.txt` 에 `Yeti` 와 `Sitemap:` 줄이 보이는지
   - `https://pizza-clip.com/sitemap.xml` 이 열리는지
3. 서치어드바이저: 등록 주소가 `https://pizza-clip.com` 인지 확인 →
   **소유확인**(HTML 메타 자리 이미 넣어둠, 코드만 붙여넣고 재배포) →
   **robots.txt 수집 요청** → **사이트맵 제출**(`https://pizza-clip.com/sitemap.xml`).

---

## 더 하면 좋은 것 (우선순위)

- [ ] **FAQ 섹션 + FAQPage 구조화 데이터** (AEO 최고 효율). `/info` 또는 `/how-to`에
      "자주 묻는 질문"을 눈에 보이게 넣고, 같은 Q&A를 `FAQPage` JSON-LD로 마크업.
      (화면 내용과 schema가 일치해야 효과 있음 → llms.txt에 넣어둔 Q&A를 재활용 가능)
- [ ] **og:image 전용 이미지** 점검 — 현재 `/img/billboard.jpg` 사용 중. SNS/AI 카드용 1200×630 권장.
- [ ] **블로그 글 발행** (`src/content/blog`의 `hello.md`는 draft). 클립보드 사용 팁 등
      실제 본문이 늘수록 검색 유입 + AI 인용 대상이 늘어남.
- [ ] **favicon.ico 갱신**: 현재 .ico는 옛 흑백 디자인. 새 벡터에서 .ico/PNG로 재생성하면 완벽.
      (대부분 브라우저는 SVG를 먼저 쓰므로 화면상은 이미 새 피자로 보임)
- [ ] **@astrojs/sitemap** 도입 시 자동 사이트맵으로 교체 가능(지금은 정적이라 페이지 추가 때 수동 갱신 필요).
- [ ] **구글 서치콘솔**도 같이 등록 (BaseLayout에 google 인증 메타 자리만 추가하면 됨).

## 메모
이 문서는 내부 참고용이며 검색결과에 노출되지 않습니다.
