// Vercel Edge Middleware — appcast 노크 카운트 (앱 일일 활성 기기 ≈ 측정)
//
// 설치된 pizzaClip 의 Sparkle 은 하루 1회 `/appcast.xml` 로 업데이트 확인 요청을 보낸다.
// 그 요청 수 ≈ 일일 활성 기기 수. 이 미들웨어는 `/appcast.xml` 요청이 올 때마다
// 카운터(knock:YYYY-MM-DD, KST 기준)를 +1 한 뒤, 요청을 그대로 통과시켜
// 기존 정적 public/appcast.xml 이 평소처럼 서빙되게 한다.
//
// 핵심 안전장치: 카운트는 next() 를 막지 않고 waitUntil 로 흘려보낸다.
//   → 저장소 장애/미설정이어도 자동업데이트 피드는 절대 깨지지 않는다.
// 앱쪽/release.sh 수정 0. URL(`/appcast.xml`)도 그대로라 기존 설치본까지 즉시 집계된다.
import { next } from '@vercel/edge';

export const config = { matcher: '/appcast.xml' };

export default function middleware(_request, context) {
  context.waitUntil(countKnock());
  return next();
}

async function countKnock() {
  const url = process.env.KV_REST_API_URL || process.env.UPSTASH_REDIS_REST_URL;
  const token = process.env.KV_REST_API_TOKEN || process.env.UPSTASH_REDIS_REST_TOKEN;
  if (!url || !token) return; // 저장소 미설정이면 조용히 통과 (집계만 안 됨)

  // 한국 시간(KST = UTC+9) 기준 날짜 키. stats.js 와 반드시 동일 규칙.
  const kst = new Date(Date.now() + 9 * 3600 * 1000);
  const day = kst.toISOString().slice(0, 10); // YYYY-MM-DD

  try {
    await fetch(`${url}/incr/${encodeURIComponent('knock:' + day)}`, {
      headers: { Authorization: `Bearer ${token}` },
    });
  } catch {
    // 카운트 실패는 무시 — 업데이트 피드에 영향 주지 않는다.
  }
}
