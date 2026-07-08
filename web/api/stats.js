// GET /api/stats?key=<STATS_KEY>
//   • 브라우저로 열면  → 보기 편한 HTML 대시보드(세 앱 카드 + 30일 막대그래프)
//   • format=json 또는 브라우저가 아닌 요청(모니터링/curl) → 기존과 동일한 JSON
//
// 미들웨어(middleware.js)가 쌓은 앱별 노크 카운터를 읽어 돌려준다.
//   - 피자앱  : knock:YYYY-MM-DD          (KST)
//   - 피클앱  : knock:pickle:YYYY-MM-DD   (KST)
//   - 핫소스앱: knock:hotsauce:YYYY-MM-DD (KST)
// 레포가 public 이므로 비밀값은 절대 코드에 두지 않고 환경변수 STATS_KEY 로 보호한다.
//   - STATS_KEY 가 설정돼 있으면 ?key 가 일치해야만 응답.
//   - 미설정이면(초기) 누구나 조회 가능 → 가능하면 STATS_KEY 를 꼭 설정할 것.
//
// 응답 호환성: JSON 최상위 today/last30dTotal/byDay 는 '피자앱' 수치 그대로 유지(기존 모니터링 보존).
// 앱별 상세는 apps.{pizza,pickle,hotsauce} 에, 세 앱 합계는 combined 에 담는다.

// 대시보드에 그릴 앱 목록(표시 순서·라벨·색·이모지·읽을 Redis 접두어).
const APPS = [
  { id: 'pizza',    name: '피자클립', emoji: '🍕', prefix: 'knock:',          color: '#A2371F' },
  { id: 'pickle',   name: '피클',     emoji: '🥒', prefix: 'knock:pickle:',   color: '#798904' },
  { id: 'hotsauce', name: '핫소스',   emoji: '🌶️', prefix: 'knock:hotsauce:', color: '#3E9E90' },
];

export default async function handler(req, res) {
  const url = process.env.KV_REST_API_URL || process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.KV_REST_API_TOKEN || process.env.UPSTASH_REDIS_REST_TOKEN;
  const secret = process.env.STATS_KEY;

  const reqUrl = new URL(req.url, 'http://x');
  const provided = (req.query && req.query.key) || reqUrl.searchParams.get('key');
  const format = (req.query && req.query.format) || reqUrl.searchParams.get('format');

  // 브라우저(Accept: text/html)면 HTML, 아니면 JSON. ?format=json|html 로 강제 가능.
  const accept = String((req.headers && req.headers.accept) || '');
  const wantsHtml = format === 'html' || (format !== 'json' && accept.includes('text/html'));

  res.setHeader('cache-control', 'no-store');

  if (secret && provided !== secret) {
    res.statusCode = 401;
    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ error: 'unauthorized' }));
    return;
  }
  if (!url || !token) {
    res.statusCode = 500;
    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ error: 'storage not configured (KV env vars missing)' }));
    return;
  }

  // 최근 30일 키 (KST 기준 — 미들웨어와 동일 규칙). days[0] = 오늘.
  const baseKst = Date.now() + 9 * 3600 * 1000;
  const days = [];
  for (let i = 0; i < 30; i++) {
    days.push(new Date(baseKst - i * 86400000).toISOString().slice(0, 10));
  }

  // 한 앱(접두어)의 30일치를 Redis 에서 읽어 {byDay,today,last30dTotal} 로 집계.
  async function readApp(prefix) {
    const keys = days.map((d) => encodeURIComponent(prefix + d));
    const r = await fetch(`${url}/mget/${keys.join('/')}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
    const json = await r.json();
    const values = Array.isArray(json.result) ? json.result : [];

    const byDay = {};
    let total = 0;
    days.forEach((d, i) => {
      const n = Number(values[i]) || 0;
      byDay[d] = n;
      total += n;
    });
    return { today: byDay[days[0]], last30dTotal: total, byDay };
  }

  try {
    // 세 앱을 병렬로 읽는다.
    const results = await Promise.all(APPS.map((a) => readApp(a.prefix)));
    const stats = {};
    APPS.forEach((a, i) => { stats[a.id] = results[i]; });

    // 세 앱 합계(일별·오늘·30일).
    const combinedByDay = {};
    days.forEach((d) => {
      combinedByDay[d] = APPS.reduce((sum, a) => sum + (stats[a.id].byDay[d] || 0), 0);
    });
    const combined = {
      today: APPS.reduce((s, a) => s + stats[a.id].today, 0),
      last30dTotal: APPS.reduce((s, a) => s + stats[a.id].last30dTotal, 0),
      byDay: combinedByDay,
    };

    if (wantsHtml) {
      res.statusCode = 200;
      res.setHeader('content-type', 'text/html; charset=utf-8');
      res.end(renderHtml({ stats, combined, days, baseKst, provided }));
      return;
    }

    res.statusCode = 200;
    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.end(
      JSON.stringify(
        {
          // ── 호환 유지: 최상위는 '피자앱' 수치 그대로 ──
          today: stats.pizza.today,
          last30dTotal: stats.pizza.last30dTotal,
          byDay: stats.pizza.byDay,
          // ── 앱별 상세 + 합계 ──
          apps: stats,        // {pizza,pickle,hotsauce} 각각 {today,last30dTotal,byDay}
          combined,           // 세 앱 합산 {today,last30dTotal,byDay}
          note: 'knock ≈ 1 device/day (Sparkle checks once per day). 대략치. 최상위 today/byDay 는 pizza 기준(호환), 전체는 apps/combined 참고. HTML 대시보드는 브라우저로 열거나 ?format=html.',
        },
        null,
        2
      )
    );
  } catch (e) {
    res.statusCode = 502;
    res.setHeader('content-type', 'application/json; charset=utf-8');
    res.end(JSON.stringify({ error: 'read failed', detail: String(e) }));
  }
}

// ─────────────────────────────────────────────────────────────────────────
// HTML 대시보드 렌더링 (외부 의존성 없는 자체 완결 문자열)
// ─────────────────────────────────────────────────────────────────────────
function renderHtml({ stats, combined, days, baseKst, provided }) {
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) =>
    ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const nf = (n) => Number(n).toLocaleString('ko-KR');
  const iso = new Date(baseKst).toISOString();      // KST 벽시계(‘Z’ 무시)
  const stamp = iso.slice(0, 10) + ' ' + iso.slice(11, 16) + ' KST';
  const refresh = '/api/stats?format=html' + (provided ? '&key=' + encodeURIComponent(provided) : '');
  const chronoDays = [...days].reverse();           // 과거 → 오늘 (왼→오른쪽)

  // 30일 막대그래프 한 개. 오늘 막대는 진하게 강조.
  const chart = (byDay, color) => {
    const max = Math.max(1, ...chronoDays.map((d) => byDay[d] || 0));
    const bars = chronoDays.map((d, i) => {
      const v = byDay[d] || 0;
      const h = Math.round((v / max) * 100);
      const isToday = i === chronoDays.length - 1;
      return `<div class="bar" title="${d}: ${nf(v)}" style="height:${Math.max(v ? 6 : 2, h)}%;background:${color};opacity:${isToday ? 1 : 0.5}"></div>`;
    }).join('');
    return `<div class="chart">${bars}</div>`;
  };

  // 앱/합계 카드 한 개.
  const card = (name, emoji, color, s, isTotal) => `
    <section class="card${isTotal ? ' total' : ''}" style="--accent:${color}">
      <header><span class="emoji">${emoji}</span><h2>${esc(name)}</h2></header>
      <div class="today"><span class="num">${nf(s.today)}</span><span class="unit">오늘 활성 기기</span></div>
      <div class="sub">
        <div><b>${nf(s.last30dTotal)}</b><span>30일 합계</span></div>
        <div><b>${nf(Math.round(s.last30dTotal / 30))}</b><span>일평균</span></div>
      </div>
      ${chart(s.byDay, color)}
    </section>`;

  const appCards = APPS.map((a) => card(a.name, a.emoji, a.color, stats[a.id], false)).join('');
  const totalCard = card('전체 합계', '📊', '#102138', combined, true);

  return `<!doctype html>
<html lang="ko"><head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="robots" content="noindex,nofollow">
<title>PizzaClip · 사용 현황</title>
<style>
  :root{--bg:#FCF6EF;--ink:#102138;--text:#333;--surface:#fff;--line:#e7ddd0}
  *{box-sizing:border-box}
  body{margin:0;background:var(--bg);color:var(--text);
    font-family:"Pretendard",system-ui,-apple-system,"Apple SD Gothic Neo",sans-serif;
    -webkit-font-smoothing:antialiased;padding:24px 16px 48px}
  .wrap{max-width:1000px;margin:0 auto}
  .top{display:flex;align-items:baseline;justify-content:space-between;gap:12px;flex-wrap:wrap;margin-bottom:4px}
  h1{font-size:clamp(1.4rem,4vw,2rem);color:var(--ink);margin:0;letter-spacing:-.02em}
  .stamp{color:#8a7f70;font-size:.85rem}
  .stamp a{color:var(--ink);text-decoration:none;border-bottom:1px dashed #b9ad9c;padding-bottom:1px}
  .note{color:#9a8f80;font-size:.8rem;margin:6px 0 22px}
  .grid{display:grid;gap:16px;grid-template-columns:repeat(auto-fit,minmax(240px,1fr))}
  .card{background:var(--surface);border:1px solid var(--line);border-radius:20px;
    padding:20px;box-shadow:0 1px 2px rgba(16,33,56,.04);border-top:4px solid var(--accent)}
  .card.total{grid-column:1/-1;background:linear-gradient(180deg,#fff, #fbf7f1)}
  .card header{display:flex;align-items:center;gap:8px;margin-bottom:14px}
  .card .emoji{font-size:1.3rem}
  .card h2{font-size:1.05rem;margin:0;color:var(--ink);font-weight:700}
  .today{display:flex;align-items:baseline;gap:8px;margin-bottom:14px}
  .today .num{font-size:2.6rem;font-weight:800;line-height:1;color:var(--accent);letter-spacing:-.03em}
  .today .unit{font-size:.85rem;color:#8a7f70}
  .sub{display:flex;gap:20px;margin-bottom:16px}
  .sub div{display:flex;flex-direction:column}
  .sub b{font-size:1.2rem;color:var(--ink);font-weight:700}
  .sub span{font-size:.75rem;color:#8a7f70}
  .chart{display:flex;align-items:flex-end;gap:2px;height:56px;padding-top:4px;border-top:1px dashed var(--line)}
  .chart .bar{flex:1;min-height:2px;border-radius:2px 2px 0 0;transition:opacity .15s}
  .chart .bar:hover{opacity:1!important}
  .legend{color:#9a8f80;font-size:.72rem;text-align:right;margin-top:6px}
</style>
</head><body>
<div class="wrap">
  <div class="top">
    <h1>📊 PizzaClip 사용 현황</h1>
    <div class="stamp">기준 ${stamp} · <a href="${esc(refresh)}">새로고침 ↻</a></div>
  </div>
  <p class="note">숫자 = Sparkle 자동 업데이트 확인 요청 수 ≈ 하루에 앱을 켠 기기 수(대략치). 막대그래프는 최근 30일(왼쪽=과거, 오른쪽 진한 막대=오늘).</p>
  <div class="grid">
    ${totalCard}
    ${appCards}
  </div>
  <p class="legend">JSON 원본이 필요하면 주소 끝에 <code>&amp;format=json</code> 을 붙이세요.</p>
</div>
</body></html>`;
}
