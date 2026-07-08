// Vercel Edge Middleware
//  (1) appcast 노크 카운트 (앱 일일 활성 기기 ≈ 측정)
//  (2) 접속지역 기반 언어 자동 분기 (한국=한국어 / 그 외=영문) — 위치권한 팝업 없이 IP 국가 헤더로 판단
//
// ── (1) 노크 카운트 ──
// 설치된 앱들의 Sparkle 은 하루 1회 자기 appcast 로 업데이트 확인 요청을 보낸다.
// 그 요청 수 ≈ 일일 활성 기기 수. 아래 두 경로 요청마다 앱별 카운터를 +1 한 뒤
// 요청을 그대로 통과시켜 정적 appcast.xml 이 평소처럼 서빙되게 한다.
//   - 피자앱 : /appcast.xml        → knock:YYYY-MM-DD          (기존 키 그대로 = 과거 데이터 보존)
//   - 피클앱 : /pickle/appcast.xml → knock:pickle:YYYY-MM-DD   (피클 전용 키)
// 안전장치: 카운트는 next() 를 막지 않고 waitUntil 로 흘려보낸다(저장소 장애/미설정이어도 피드 안 깨짐).
//
// ── (2) 언어 자동 분기 ──
// Vercel 이 붙여주는 `x-vercel-ip-country` 헤더(IP 기반, 권한 팝업 없음)로 접속 국가를 판단해
// 한국(KR) 외 지역의 한국어 페이지 진입은 영문(/en/…)으로, 한국에서의 영문 페이지 진입은 한국어로
// **단 한 번** 307 리다이렉트한다. 자동 분기는 아래 경우엔 하지 않는다(과한 개입/SEO 보호):
//   - 사용자가 이미 언어를 본 적 있음(pclang 쿠키 존재)
//   - 사이트 내부에서 넘어온 이동(referer 가 우리 도메인 = 토글 클릭/내부 링크) → 사용자가 고른 링크 존중
//   - 검색/AI 크롤러(User-Agent) → 두 언어 URL 모두 색인되도록 그대로 통과
//   - 국가 정보를 알 수 없음 → 기본(요청한 경로) 유지
import { next } from '@vercel/edge';

export const config = {
  matcher: [
    // (1) 노크 카운트
    '/appcast.xml',
    '/pickle/appcast.xml',
    '/hotsauce/appcast.xml',
    // (2) 언어 자동 분기 대상(한국어 4 + 영문 4, 트레일링 슬래시 변형 포함)
    '/',
    '/pizzaclip',
    '/pizzaclip/',
    '/pickle',
    '/pickle/',
    '/hotsauce',
    '/hotsauce/',
    '/info',
    '/info/',
    '/en',
    '/en/',
    '/en/pizzaclip',
    '/en/pizzaclip/',
    '/en/pickle',
    '/en/pickle/',
    '/en/hotsauce',
    '/en/hotsauce/',
    '/en/info',
    '/en/info/',
  ],
};

// 한국어(기본) 경로 → 영문 경로
const KO_TO_EN = {
  '/': '/en/',
  '/pizzaclip': '/en/pizzaclip',
  '/pickle': '/en/pickle',
  '/hotsauce': '/en/hotsauce',
  '/info': '/en/info',
};
// 영문 경로 → 한국어 경로
const EN_TO_KO = {
  '/en': '/',
  '/en/pizzaclip': '/pizzaclip',
  '/en/pickle': '/pickle',
  '/en/hotsauce': '/hotsauce',
  '/en/info': '/info',
};

export default function middleware(request, context) {
  const url = new URL(request.url);
  const path = url.pathname;

  // (1) 노크 카운트 — 기존 raw 카운터(knock:) 유지 + 정밀 지표 추가 수집
  if (path === '/appcast.xml' || path === '/pickle/appcast.xml' || path === '/hotsauce/appcast.xml') {
    const app = path === '/pickle/appcast.xml' ? 'pickle'
              : path === '/hotsauce/appcast.xml' ? 'hotsauce'
              : 'pizza';
    const prefix = app === 'pickle' ? 'knock:pickle:'
                 : app === 'hotsauce' ? 'knock:hotsauce:'
                 : 'knock:';
    // 정밀 지표용 부가정보: UA(Sparkle 여부·앱 버전) / IP(중복제거 해시) / 국가.
    const ua = request.headers.get('user-agent') || '';
    const xff = request.headers.get('x-forwarded-for') || '';
    const ip = (xff.split(',')[0] || '').trim() || request.headers.get('x-real-ip') || '';
    const country = (request.headers.get('x-vercel-ip-country') || '').toUpperCase();
    context.waitUntil(countKnock(app, prefix, { ua, ip, country }));
    return next();
  }

  // (2) 언어 자동 분기
  return localeRedirect(request, url, path);
}

function localeRedirect(request, url, rawPath) {
  // 트레일링 슬래시 정규화 (루트 '/' 는 그대로)
  const path = rawPath.length > 1 ? rawPath.replace(/\/+$/, '') : rawPath;

  // 이미 언어를 본 적 있으면(쿠키) 자동 분기 안 함
  const cookie = request.headers.get('cookie') || '';
  if (/(?:^|;\s*)pclang=(?:ko|en)\b/.test(cookie)) return next();

  // 사이트 내부 이동(토글/내부 링크)은 사용자가 고른 링크를 존중 — 자동 분기 안 함
  const ref = request.headers.get('referer') || '';
  if (ref) {
    try { if (new URL(ref).host === url.host) return next(); } catch { /* ignore */ }
  }

  // 검색/AI/미리보기 크롤러는 그대로 통과(두 언어 URL 모두 색인)
  const ua = request.headers.get('user-agent') || '';
  if (/bot|crawl|spider|slurp|mediapartners|facebookexternalhit|embed|preview|whatsapp|telegram|slack|discord|googlebot|applebot|gptbot|chatgpt|claudebot|perplexity|bingbot|yeti|daum/i.test(ua)) {
    return next();
  }

  // IP 기반 접속 국가(권한 팝업 없음). 모르면 기본 유지.
  const country = (request.headers.get('x-vercel-ip-country') || '').toUpperCase();
  if (!country) return next();

  let dest = null;
  let lang = null;
  if (country !== 'KR') {
    // 한국 외 → 영문 (한국어 경로일 때만)
    if (Object.prototype.hasOwnProperty.call(KO_TO_EN, path)) { dest = KO_TO_EN[path]; lang = 'en'; }
  } else {
    // 한국 → 한국어 (영문 경로일 때만)
    if (Object.prototype.hasOwnProperty.call(EN_TO_KO, path)) { dest = EN_TO_KO[path]; lang = 'ko'; }
  }
  if (!dest) return next();

  // 분기 결과를 쿠키로 기억 → 다음부턴 자동 분기 안 하고 사용자 네비 존중.
  return new Response(null, {
    status: 307,
    headers: {
      Location: new URL(dest + url.search, url).toString(),
      'Set-Cookie': `pclang=${lang}; Path=/; Max-Age=31536000; SameSite=Lax`,
      'Cache-Control': 'no-store',
    },
  });
}

// ── 정밀 지표 수집 ──
// 기존 raw 카운터(knock:*)는 그대로 두고(과거 데이터·호환 보존), 아래 새 키를 추가한다.
// 새 키는 "진짜 앱 요청"(User-Agent 에 Sparkle 포함)일 때만 기록 → 봇/크롤러 자동 제외.
//   real:<app>:<day>  INCR    — 봇 제외 실사용 노크 수
//   ver:<app>:<day>   HINCRBY — 앱 버전별 카운트(Sparkle UA 가 이미 보내는 버전 파싱)
//   uniq:<app>:<day>  PFADD   — 중복 제거 순 기기 수(HyperLogLog). IP 를 소금+월 해시 → 원문 IP 저장 안 함
//   geo:<app>:<day>   HINCRBY — 국가별(Vercel IP 국가 헤더)
// 새 키는 400일 뒤 자동 만료(EXPIRE). 모든 명령은 파이프라인 1회 요청으로 묶는다(무료 한도 절약).
const SPARKLE_RE = /Sparkle/i;
const NEW_KEY_TTL = 60 * 60 * 24 * 400; // 400일

// Sparkle UA 예: "PicKle/1.3.2 Sparkle/2.6.4" → 앱 버전 "1.3.2"
function parseAppVersion(ua) {
  const m = ua.match(/\/([0-9][\w.\-]*)\s+Sparkle/i);
  return m ? m[1] : 'unknown';
}

// IP 를 소금(월 단위 자동 회전)과 함께 SHA-256 해시 → 원문 IP 는 절대 저장/전송하지 않음.
async function hashIp(ip, day) {
  const salt = (process.env.STATS_SALT || 'pizzaclip-fallback-salt') + ':' + day.slice(0, 7);
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(salt + '|' + ip));
  return [...new Uint8Array(buf)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

// Upstash 파이프라인: 명령 배열을 한 번의 POST 로 실행.
async function redisPipeline(url, token, commands) {
  await fetch(`${url}/pipeline`, {
    method: 'POST',
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
    body: JSON.stringify(commands),
  });
}

async function countKnock(app, prefix, meta) {
  const url = process.env.KV_REST_API_URL || process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.KV_REST_API_TOKEN || process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return; // 저장소 미설정이면 조용히 통과 (집계만 안 됨)

  // 한국 시간(KST = UTC+9) 기준 날짜 키. stats.js 와 반드시 동일 규칙.
  const kst = new Date(Date.now() + 9 * 3600 * 1000);
  const day = kst.toISOString().slice(0, 10); // YYYY-MM-DD

  // raw 카운터 — 기존 키/동작 그대로.
  const cmds = [['INCR', prefix + day]];

  // 진짜 앱 요청(Sparkle)일 때만 정밀 지표 기록 → 봇 자동 제외.
  const ua = meta.ua || '';
  if (SPARKLE_RE.test(ua)) {
    const ver = parseAppVersion(ua);
    const kReal = `real:${app}:${day}`;
    const kVer = `ver:${app}:${day}`;
    const kUniq = `uniq:${app}:${day}`;
    const kGeo = `geo:${app}:${day}`;
    cmds.push(['INCR', kReal], ['EXPIRE', kReal, NEW_KEY_TTL]);
    cmds.push(['HINCRBY', kVer, ver, 1], ['EXPIRE', kVer, NEW_KEY_TTL]);
    if (meta.ip) {
      const h = await hashIp(meta.ip, day);
      cmds.push(['PFADD', kUniq, h], ['EXPIRE', kUniq, NEW_KEY_TTL]);
    }
    if (meta.country) {
      cmds.push(['HINCRBY', kGeo, meta.country, 1], ['EXPIRE', kGeo, NEW_KEY_TTL]);
    }
  }

  try {
    await redisPipeline(url, token, cmds);
  } catch {
    // 카운트 실패는 무시 — 업데이트 피드에 영향 주지 않는다.
  }
}
