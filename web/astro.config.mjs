// @ts-check
import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';

// https://astro.build/config
export default defineConfig({
  // 사이트 도메인 (canonical / og / sitemap 기준). Cloudflare 등록 도메인.
  site: 'https://pizza-clip.com',
  // sitemap.xml 자동 생성 (robots.txt 의 Sitemap 줄이 가리킴 → SEO/AEO)
  integrations: [sitemap()],
});
