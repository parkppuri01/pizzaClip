// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  // 사이트 도메인 (canonical / og / sitemap 기준). Cloudflare 등록 도메인.
  site: 'https://pizza-clip.com',

  // ── 다국어(i18n) ──
  // 한국어(기본)는 루트 그대로(/, /pizzaclip …), 영문은 /en/ 접두어(/en/, /en/pizzaclip …).
  // prefixDefaultLocale:false = 기본 언어(ko)에는 접두어를 붙이지 않음(기존 URL 보존).
  i18n: {
    defaultLocale: 'ko',
    locales: ['ko', 'en'],
    routing: { prefixDefaultLocale: false },
  },

  integrations: [
    // sitemap.xml 자동 생성 + 언어별 hreflang 대체링크 자동 주석(SEO/AEO).
    // i18n 옵션을 주면 /en/ 경로를 en 으로 인식해 ko↔en alternate 를 sitemap 에 박아준다.
    sitemap({
      i18n: {
        defaultLocale: 'ko',
        locales: { ko: 'ko-KR', en: 'en-US' },
      },
    }),
  ],
});
