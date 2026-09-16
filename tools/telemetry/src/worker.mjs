import { aggregate, UPSERT } from './metrics.mjs';
import { authorized } from './auth.mjs';
import { dashboard } from './dashboard.mjs';
const headers = {
  'Cache-Control': 'no-store',
  'X-Content-Type-Options': 'nosniff',
  'Referrer-Policy': 'no-referrer',
  'Content-Security-Policy': "default-src 'none'; style-src 'unsafe-inline'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'"
};
function response(body, status = 200, extra = {}) { return new Response(body, { status, headers: { ...headers, ...extra } }); }
async function bodyJSON(request) {
  if (!request.body) throw Error('Missing body');
  const reader = request.body.getReader();
  let length = 0;
  const chunks = [];
  for (;;) {
    const { done, value } = await reader.read();
    if (done) break;
    length += value.byteLength;
    if (length > 4096) { await reader.cancel(); throw Error('Too large'); }
    chunks.push(value);
  }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  return JSON.parse(new TextDecoder('utf-8', { fatal: true }).decode(bytes));
}
export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === '/v1/attempt') {
      const origin = request.headers.get('Origin');
      const allowed = (env.ALLOWED_ORIGINS || '').split(',').map(s => s.trim()).filter(Boolean);
      if (origin && !allowed.includes(origin)) return response('Origin denied', 403);
      const cors = origin ? { 'Access-Control-Allow-Origin': origin, 'Vary': 'Origin' } : {};
      if (request.method === 'OPTIONS') return response(null, 204, { ...cors, 'Access-Control-Allow-Methods': 'POST', 'Access-Control-Allow-Headers': 'Content-Type' });
      if (request.method !== 'POST') return response('Method not allowed', 405, { ...cors, Allow: 'POST' });
      if (env.COLLECTION_ENABLED !== 'true') return response(null, 204, cors);
      // Network metadata is used transiently for abuse prevention, never analytics.
      // These approximate limits apply per Cloudflare location, not globally.
      try {
        const source = request.headers.get('CF-Connecting-IP');
        if (!source || !env.INGEST_LIMITER || !env.INGEST_TOTAL_LIMITER) return response('Temporarily unavailable', 503, cors);
        const perSource = await env.INGEST_LIMITER.limit({ key: source });
        if (!perSource.success) return response('Rate limited', 429, { ...cors, 'Retry-After': '60' });
        const total = await env.INGEST_TOTAL_LIMITER.limit({ key: 'cairn-attempts' });
        if (!total.success) return response('Rate limited', 429, { ...cors, 'Retry-After': '60' });
      } catch { return response('Temporarily unavailable', 503, cors); }
      if (url.search || request.headers.get('Content-Type')?.split(';')[0].trim() !== 'application/json') return response('Invalid request', 400, cors);
      let payload, metrics;
      try { payload = await bodyJSON(request); metrics = aggregate(payload); }
      catch { return response('Invalid summary', 400, cors); }
      try {
        const day = new Date().toISOString().slice(0, 10);
        await env.DB.batch(metrics.map(([metric, value]) => env.DB.prepare(UPSERT).bind(day, payload.episode, payload.level, payload.difficulty, metric, value)));
        return response(null, 204, cors);
      } catch { return response('Temporarily unavailable', 503, cors); }
    }
    if (url.pathname === '/admin' || url.pathname === '/admin/' || url.pathname === '/admin/data') {
      if (!await authorized(request, env)) return response('Sign in through the configured Cloudflare Access application.', 403);
      if (request.method !== 'GET') return response('Method not allowed', 405, { Allow: 'GET' });
      const days = Number(url.searchParams.get('days') || 30);
      if (![7, 30, 90].includes(days)) return response('Invalid date range', 400);
      try {
        const start = new Date(Date.now() - (days - 1) * 86400000).toISOString().slice(0, 10);
        const { results } = await env.DB.prepare('SELECT episode, level, difficulty, metric, SUM(value) AS value FROM totals WHERE day >= ? GROUP BY episode, level, difficulty, metric ORDER BY episode, level, difficulty, metric').bind(start).all();
        return url.pathname === '/admin/data'
          ? response(JSON.stringify(results), 200, { 'Content-Type': 'application/json', 'Content-Disposition': 'attachment; filename="cairn-statistics.json"' })
          : response(dashboard(results, days), 200, { 'Content-Type': 'text/html; charset=utf-8' });
      } catch { return response('Statistics temporarily unavailable', 503); }
    }
    return response('Not found', 404);
  },
  async scheduled(event, env) {
    const cutoff = new Date(event.scheduledTime - 89 * 86400000).toISOString().slice(0, 10);
    await env.DB.prepare('DELETE FROM totals WHERE day < ?').bind(cutoff).run();
  }
};
