// GET /api/stats?key=<STATS_KEY>
//   • 브라우저로 열면  → 보기 편한 HTML 대시보드(세 앱 카드 + 정밀 지표 + 30일 추이)
//   • format=json 또는 브라우저가 아닌 요청(모니터링/curl) → 기존과 동일한 JSON(+ 신규 필드)
//
// 미들웨어(middleware.js)가 쌓은 카운터를 읽어 돌려준다. (KST 날짜 규칙은 미들웨어와 동일)
//   raw 노크(과거 데이터·호환):  knock: / knock:pickle: / knock:hotsauce:  + YYYY-MM-DD
//   정밀 지표(진짜 앱 요청만, 봇 제외 · 배포일부터 적재):
//     real:<app>:<day>  = 봇 제외 실사용 노크 수(INCR)
//     ver:<app>:<day>   = 앱 버전별 카운트(HASH)
//     uniq:<app>:<day>  = 중복 제거 순 기기 수(HyperLogLog) — IP 해시, 원문 저장 안 함
//     geo:<app>:<day>   = 국가별 카운트(HASH)
// 레포가 public 이므로 비밀값은 환경변수 STATS_KEY 로 보호(설정 시 ?key 일치해야 응답).
//
// 응답 호환성: JSON 최상위 today/last30dTotal/byDay 는 '피자앱 raw' 그대로 유지(기존 모니터링 보존).

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

  // 최근 30일 키 (KST 기준). days[0] = 오늘.
  const baseKst = Date.now() + 9 * 3600 * 1000;
  const days = [];
  for (let i = 0; i < 30; i++) {
    days.push(new Date(baseKst - i * 86400000).toISOString().slice(0, 10));
  }
  const today = days[0];
  const last7 = days.slice(0, 7);

  try {
    // ── 필요한 모든 읽기를 파이프라인 한 번으로 묶는다 ──
    const cmds = [];
    const push = (c) => { cmds.push(c); return cmds.length - 1; };
    const map = {};
    for (const a of APPS) {
      map[a.id] = {
        raw:  push(['MGET', ...days.map((d) => a.prefix + d)]),          // raw 노크 30일
        real: push(['MGET', ...days.map((d) => `real:${a.id}:${d}`)]),   // 봇제외 실사용 30일
        uqT:  push(['PFCOUNT', `uniq:${a.id}:${today}`]),                // 오늘 순 사용자
        uq30: push(['PFCOUNT', ...days.map((d) => `uniq:${a.id}:${d}`)]),// 30일 순 사용자(합집합)
        ver:  last7.map((d) => push(['HGETALL', `ver:${a.id}:${d}`])),   // 버전 분포(최근 7일 합)
        geo:  last7.map((d) => push(['HGETALL', `geo:${a.id}:${d}`])),   // 국가 분포(최근 7일 합)
      };
    }
    const cmb = {
      uqT:  push(['PFCOUNT', ...APPS.map((a) => `uniq:${a.id}:${today}`)]),
      uq30: push(['PFCOUNT', ...APPS.flatMap((a) => days.map((d) => `uniq:${a.id}:${d}`))]),
    };

    const pr = await fetch(`${url}/pipeline`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(cmds),
    });
    const arr = await pr.json();
    const val = (i) => {
      const e = Array.isArray(arr) ? arr[i] : undefined;
      return e && typeof e === 'object' && 'result' in e ? e.result : e;
    };
    const numArr = (x) => (Array.isArray(x) ? x.map((v) => Number(v) || 0) : []);
    // Upstash HGETALL 은 [field,val,field,val…] 평면 배열(또는 객체) → {field:합계}
    const mergeHash = (idxs) => {
      const o = {};
      for (const i of idxs) {
        const x = val(i);
        if (Array.isArray(x)) {
          for (let k = 0; k + 1 < x.length; k += 2) o[x[k]] = (o[x[k]] || 0) + (Number(x[k + 1]) || 0);
        } else if (x && typeof x === 'object') {
          for (const kk in x) o[kk] = (o[kk] || 0) + (Number(x[kk]) || 0);
        }
      }
      return o;
    };

    const stats = {};
    for (const a of APPS) {
      const m = map[a.id];
      const rawS = numArr(val(m.raw));
      const realS = numArr(val(m.real));
      const byDay = {}, realByDay = {};
      days.forEach((d, i) => { byDay[d] = rawS[i] || 0; realByDay[d] = realS[i] || 0; });
      stats[a.id] = {
        today: byDay[today],
        last30dTotal: rawS.reduce((s, n) => s + n, 0),
        byDay,
        realToday: realByDay[today],
        real30dTotal: realS.reduce((s, n) => s + n, 0),
        realByDay,
        uniqToday: Number(val(m.uqT)) || 0,
        uniq30d: Number(val(m.uq30)) || 0,
        versions: mergeHash(m.ver),
        geo: mergeHash(m.geo),
      };
    }

    const combinedByDay = {};
    days.forEach((d) => { combinedByDay[d] = APPS.reduce((s, a) => s + (stats[a.id].byDay[d] || 0), 0); });
    const combined = {
      today: APPS.reduce((s, a) => s + stats[a.id].today, 0),
      last30dTotal: APPS.reduce((s, a) => s + stats[a.id].last30dTotal, 0),
      byDay: combinedByDay,
      realToday: APPS.reduce((s, a) => s + stats[a.id].realToday, 0),
      uniqToday: Number(val(cmb.uqT)) || 0,   // 앱 합쳐 중복 제거
      uniq30d: Number(val(cmb.uq30)) || 0,
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
          // ── 호환 유지: 최상위는 '피자앱 raw' 그대로 ──
          today: stats.pizza.today,
          last30dTotal: stats.pizza.last30dTotal,
          byDay: stats.pizza.byDay,
          // ── 앱별 상세(raw + 정밀 지표) + 합계 ──
          apps: stats,
          combined,
          note: 'raw(today/byDay) 는 봇 포함 기존 노크(과거 데이터 보존). realToday=봇 제외, uniqToday/uniq30d=중복 제거 순 기기수(HyperLogLog), versions/geo=최근 7일 합. 정밀 지표는 배포일부터 적재되어 초기에는 낮게 나올 수 있음. HTML 대시보드는 브라우저로 열거나 ?format=html.',
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
  const iso = new Date(baseKst).toISOString();
  const stamp = iso.slice(0, 10) + ' ' + iso.slice(11, 16) + ' KST';
  const refresh = '/api/stats?format=html' + (provided ? '&key=' + encodeURIComponent(provided) : '');
  const chronoDays = [...days].reverse(); // 과거 → 오늘

  // 국가코드(2자) → 국기 이모지
  const flag = (cc) => (/^[A-Za-z]{2}$/.test(cc)
    ? String.fromCodePoint(...[...cc.toUpperCase()].map((ch) => 0x1f1e6 + ch.charCodeAt(0) - 65))
    : '🏳️');

  // raw 노크 30일 막대그래프(과거 이력 보유). 오늘 막대 강조.
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

  // 버전 분포 칩 (내림차순 상위 5)
  const versionChips = (versions) => {
    const items = Object.entries(versions).sort((a, b) => b[1] - a[1]).slice(0, 5);
    if (!items.length) return '<div class="chips empty">집계 대기 중</div>';
    return `<div class="chips">${items.map(([v, n]) =>
      `<span class="chip"><b>${esc(v)}</b> ${nf(n)}</span>`).join('')}</div>`;
  };

  // 국가 상위 4 (국기 + 수)
  const geoChips = (geo) => {
    const items = Object.entries(geo).sort((a, b) => b[1] - a[1]).slice(0, 4);
    if (!items.length) return '';
    return `<div class="geo">${items.map(([c, n]) =>
      `<span class="gc">${flag(c)} ${nf(n)}</span>`).join('')}</div>`;
  };

  // 앱 카드 (정밀 지표 포함)
  const appCard = (a, s) => `
    <section class="card" style="--accent:${a.color}">
      <header><span class="emoji">${a.emoji}</span><h2>${esc(a.name)}</h2></header>
      <div class="today"><span class="num">${nf(s.uniqToday)}</span><span class="unit">오늘 순 사용자<br><small>(중복 제거)</small></span></div>
      <div class="sub">
        <div><b>${nf(s.uniq30d)}</b><span>30일 순 사용자</span></div>
        <div><b>${nf(s.realToday)}</b><span>오늘 실사용</span></div>
        <div><b>${nf(s.today)}</b><span>오늘 전체<br><small>봇 포함</small></span></div>
      </div>
      <div class="label">버전 분포 <small>(최근 7일)</small></div>
      ${versionChips(s.versions)}
      ${geoChips(s.geo)}
      <div class="label">최근 30일 추이 <small>(전체 노크·과거 포함)</small></div>
      ${chart(s.byDay, a.color)}
    </section>`;

  // 전체 합계 카드
  const totalCard = (s) => `
    <section class="card total" style="--accent:#102138">
      <header><span class="emoji">📊</span><h2>전체 합계 <small>(앱 중복 제거)</small></h2></header>
      <div class="today"><span class="num">${nf(s.uniqToday)}</span><span class="unit">오늘 순 사용자<br><small>(세 앱 합쳐 중복 제거)</small></span></div>
      <div class="sub">
        <div><b>${nf(s.uniq30d)}</b><span>30일 순 사용자</span></div>
        <div><b>${nf(s.realToday)}</b><span>오늘 실사용</span></div>
        <div><b>${nf(s.today)}</b><span>오늘 전체<br><small>봇 포함</small></span></div>
      </div>
      <div class="label">최근 30일 추이 <small>(전체 노크·과거 포함)</small></div>
      ${chart(s.byDay, '#102138')}
    </section>`;

  const appCards = APPS.map((a) => appCard(a, stats[a.id])).join('');

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
  .note{color:#9a8f80;font-size:.8rem;margin:6px 0 10px;line-height:1.5}
  .banner{background:#fff7e8;border:1px solid #f0dfb8;color:#8a6d2a;font-size:.8rem;
    border-radius:12px;padding:9px 13px;margin:0 0 20px;line-height:1.5}
  .grid{display:grid;gap:16px;grid-template-columns:repeat(auto-fit,minmax(270px,1fr))}
  .card{background:var(--surface);border:1px solid var(--line);border-radius:20px;
    padding:20px;box-shadow:0 1px 2px rgba(16,33,56,.04);border-top:4px solid var(--accent)}
  .card.total{grid-column:1/-1;background:linear-gradient(180deg,#fff,#fbf7f1)}
  .card header{display:flex;align-items:center;gap:8px;margin-bottom:14px}
  .card .emoji{font-size:1.3rem}
  .card h2{font-size:1.05rem;margin:0;color:var(--ink);font-weight:700}
  .card h2 small{font-size:.72rem;color:#9a8f80;font-weight:500}
  .today{display:flex;align-items:baseline;gap:10px;margin-bottom:14px}
  .today .num{font-size:2.6rem;font-weight:800;line-height:1;color:var(--accent);letter-spacing:-.03em}
  .today .unit{font-size:.82rem;color:#8a7f70;line-height:1.25}
  .today .unit small{color:#b3a893}
  .sub{display:flex;gap:16px;margin-bottom:16px;flex-wrap:wrap}
  .sub div{display:flex;flex-direction:column}
  .sub b{font-size:1.2rem;color:var(--ink);font-weight:700}
  .sub span{font-size:.72rem;color:#8a7f70;line-height:1.2}
  .sub small{color:#b3a893}
  .label{font-size:.74rem;color:#8a7f70;margin:0 0 6px;font-weight:600}
  .label small{font-weight:400;color:#b3a893}
  .chips{display:flex;flex-wrap:wrap;gap:6px;margin-bottom:14px}
  .chips.empty{color:#b3a893;font-size:.8rem}
  .chip{background:#f4ede2;border:1px solid var(--line);border-radius:999px;
    padding:3px 10px;font-size:.78rem;color:#6b6152}
  .chip b{color:var(--ink);font-weight:700}
  .geo{display:flex;flex-wrap:wrap;gap:10px;margin:-6px 0 14px;font-size:.82rem;color:#6b6152}
  .chart{display:flex;align-items:flex-end;gap:2px;height:52px;padding-top:4px;border-top:1px dashed var(--line)}
  .chart .bar{flex:1;min-height:2px;border-radius:2px 2px 0 0;transition:opacity .15s}
  .chart .bar:hover{opacity:1!important}
  .legend{color:#9a8f80;font-size:.72rem;text-align:right;margin-top:12px}
</style>
</head><body>
<div class="wrap">
  <div class="top">
    <h1>📊 PizzaClip 사용 현황</h1>
    <div class="stamp">기준 ${stamp} · <a href="${esc(refresh)}">새로고침 ↻</a></div>
  </div>
  <p class="note"><b>오늘 순 사용자</b> = 봇 제외하고 중복 없이 센 실제 사용 기기 수(가장 정직한 숫자). <b>오늘 실사용</b> = 봇만 제외한 노크. <b>오늘 전체</b> = 봇 포함 기존 방식. 셋을 나란히 두면 봇이 얼마나 부풀렸는지 바로 보여요.</p>
  <p class="banner">ℹ️ 순 사용자·버전·국가 같은 <b>정밀 지표는 이 기능을 켠 날부터 쌓이기 시작</b>해요. 그래서 초기 며칠은 낮게 보일 수 있고, 아래 <b>30일 추이 막대</b>만 과거 이력(기존 노크)을 그대로 보여줍니다.</p>
  <div class="grid">
    ${totalCard(combined)}
    ${appCards}
  </div>
  <p class="legend">JSON 원본이 필요하면 주소 끝에 <code>&amp;format=json</code> 을 붙이세요.</p>
</div>
</body></html>`;
}
