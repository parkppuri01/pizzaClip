// GET /api/stats?key=<STATS_KEY> → 최근 30일 appcast 노크 수(≈ 일일 활성 기기) JSON
//
// 미들웨어(middleware.js)가 쌓은 앱별 노크 카운터를 읽어 돌려준다.
//   - 피자앱 : knock:YYYY-MM-DD        (KST)
//   - 피클앱 : knock:pickle:YYYY-MM-DD (KST)
// 레포가 public 이므로 비밀값은 절대 코드에 두지 않고 환경변수 STATS_KEY 로 보호한다.
//   - STATS_KEY 가 설정돼 있으면 ?key 가 일치해야만 응답.
//   - 미설정이면(초기) 누구나 조회 가능 → 가능하면 STATS_KEY 를 꼭 설정할 것.
//
// 응답 호환성: 최상위 today/last30dTotal/byDay 는 '피자앱' 수치 그대로 유지(기존 모니터링 보존).
// 앱별 상세는 apps.{pizza,pickle} 에, 두 앱 합계는 combined 에 추가로 담는다.
export default async function handler(req, res) {
  const url = process.env.KV_REST_API_URL || process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.KV_REST_API_TOKEN || process.env.UPSTASH_REDIS_REST_TOKEN;
  const secret = process.env.STATS_KEY;

  const provided =
    (req.query && req.query.key) ||
    new URL(req.url, 'http://x').searchParams.get('key');

  res.setHeader('content-type', 'application/json; charset=utf-8');
  res.setHeader('cache-control', 'no-store');

  if (secret && provided !== secret) {
    res.statusCode = 401;
    res.end(JSON.stringify({ error: 'unauthorized' }));
    return;
  }
  if (!url || !token) {
    res.statusCode = 500;
    res.end(JSON.stringify({ error: 'storage not configured (KV env vars missing)' }));
    return;
  }

  // 최근 30일 키 (KST 기준 — 미들웨어와 동일 규칙)
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
    // 피자·피클 두 앱을 병렬로 읽는다.
    const [pizza, pickle] = await Promise.all([
      readApp('knock:'),
      readApp('knock:pickle:'),
    ]);

    // 두 앱 합계(일별·오늘·30일).
    const combinedByDay = {};
    days.forEach((d) => {
      combinedByDay[d] = (pizza.byDay[d] || 0) + (pickle.byDay[d] || 0);
    });
    const combined = {
      today: pizza.today + pickle.today,
      last30dTotal: pizza.last30dTotal + pickle.last30dTotal,
      byDay: combinedByDay,
    };

    res.statusCode = 200;
    res.end(
      JSON.stringify(
        {
          // ── 호환 유지: 최상위는 '피자앱' 수치 그대로 ──
          today: pizza.today,             // 오늘(KST) 피자앱 노크 수 ≈ 오늘 활성 기기
          last30dTotal: pizza.last30dTotal, // 피자앱 최근 30일 합계
          byDay: pizza.byDay,             // 피자앱 일별 상세 (최신→과거)
          // ── 신규: 앱별 상세 + 합계 ──
          apps: { pizza, pickle },        // pizza/pickle 각각 {today,last30dTotal,byDay}
          combined,                       // 두 앱 합산 {today,last30dTotal,byDay}
          note: 'knock ≈ 1 device/day (Sparkle checks once per day). 대략치. 최상위 today/byDay 는 pizza 기준(호환), 전체는 apps/combined 참고.',
        },
        null,
        2
      )
    );
  } catch (e) {
    res.statusCode = 502;
    res.end(JSON.stringify({ error: 'read failed', detail: String(e) }));
  }
}
