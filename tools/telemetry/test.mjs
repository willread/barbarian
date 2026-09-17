import test from 'node:test';
import assert from 'node:assert/strict';
import { DatabaseSync } from 'node:sqlite';
import { readFileSync } from 'node:fs';
import worker from './src/worker.mjs';
import { aggregate } from './src/metrics.mjs';
import { dashboard } from './src/dashboard.mjs';
import { dateRange, dailyRows } from './src/reporting.mjs';
import { verifyAccessToken } from './src/auth.mjs';
import { generateKeyPair, SignJWT } from 'jose';
const sample = () => ({ schema: 1, episode: 1, level: 2, difficulty: 'normal', outcome: 'completed', duration: '3_5m', score: '5000_9999', moves: { normal: 42, slam: 3 }, features: { controls: true } });
function database() {
  const db = new DatabaseSync(':memory:');
  db.exec(readFileSync(new URL('./migrations/0001_aggregates.sql', import.meta.url), 'utf8'));
  const binding = {
    prepare(sql) { return { bind(...args) { return { run: () => db.prepare(sql).run(...args), all: () => ({ results: db.prepare(sql).all(...args) }) }; } }; },
    async batch(statements) {
      db.exec('BEGIN');
      try { const result = statements.map(s => s.run()); db.exec('COMMIT'); return result; }
      catch (error) { db.exec('ROLLBACK'); throw error; }
    }
  };
  return { db, binding };
}
const limits = () => ({ INGEST_LIMITER: { limit: async () => ({ success: true }) }, INGEST_TOTAL_LIMITER: { limit: async () => ({ success: true }) } });
function request(payload, extra = {}) { return new Request('https://stats.example/v1/attempt', { method: 'POST', headers: { 'Content-Type': 'application/json', 'CF-Connecting-IP': '192.0.2.1', ...extra }, body: JSON.stringify(payload) }); }
test('rejects identifiers, arbitrary dimensions, invalid and oversized counters', () => {
  for (const change of [{ player_id: '123' }, { timestamp: 123 }, { episode: 4 }, { score: 4500 }, { moves: { normal: -1 } }, { moves: { normal: 10001 } }, { moves: { normal: 0.5 } }, { moves: { custom: 1 } }, { features: { controls: 'yes' } }]) {
    assert.throws(() => aggregate({ ...sample(), ...change }));
  }
});
test('valid submissions merge into independent totals without raw attempt rows', async () => {
  const { db, binding } = database();
  const env = { DB: binding, COLLECTION_ENABLED: 'true', ...limits() };
  assert.equal((await worker.fetch(request(sample()), env)).status, 204);
  assert.equal((await worker.fetch(request({ ...sample(), outcome: 'died' }), env)).status, 204);
  const rows = db.prepare('SELECT * FROM totals').all();
  assert.equal(rows.find(r => r.metric === 'attempts').value, 2);
  assert.equal(rows.find(r => r.metric === 'move:normal').value, 84);
  assert.equal(rows.find(r => r.metric === 'outcome:died').value, 1);
  assert.deepEqual(Object.keys(rows[0]), ['day', 'episode', 'level', 'difficulty', 'metric', 'value']);
  db.close();
});
test('disabled collection performs no database work', async () => {
  assert.equal((await worker.fetch(request(sample()), {})).status, 204);
});
test('rejects malformed, oversized and unapproved browser requests before writing', async () => {
  const env = { COLLECTION_ENABLED: 'true', ...limits() };
  assert.equal((await worker.fetch(request({ ...sample(), identifier: 'no' }), env)).status, 400);
  assert.equal((await worker.fetch(request({ extra: 'x'.repeat(5000) }), env)).status, 400);
  assert.equal((await worker.fetch(request(sample(), { Origin: 'https://unapproved.example' }), env)).status, 403);
});
test('database failure returns retryable service error without leaking details', async () => {
  const result = await worker.fetch(request(sample()), { COLLECTION_ENABLED: 'true', ...limits(), DB: { batch() { throw Error('private'); }, prepare() { return { bind() {} }; } } });
  assert.equal(result.status, 503);
  assert.equal(await result.text(), 'Temporarily unavailable');
});
test('dashboard and data fail closed without configuration or with forged headers', async () => {
  for (const path of ['/admin', '/admin/', '/admin/data']) {
    const req = new Request(`https://stats.example${path}`, { headers: { 'Cf-Access-Authenticated-User-Email': 'owner@example.com', 'Cf-Access-Jwt-Assertion': 'fake' } });
    assert.equal((await worker.fetch(req, {})).status, 403);
    assert.equal((await worker.fetch(req, { ACCESS_TEAM_DOMAIN: 'cairn.cloudflareaccess.com', ACCESS_AUD: 'example' })).status, 403);
  }
});
test('old aggregates survive stale scheduled events', async () => {
  const { db, binding } = database();
  db.exec("INSERT INTO totals VALUES ('2025-01-01',1,1,'normal','attempts',1), ('2026-09-16',1,1,'normal','attempts',2)");
  await worker.scheduled({ scheduledTime: Date.parse('2026-09-16T04:00:00Z') }, { DB: binding });
  assert.equal(db.prepare('SELECT SUM(value) AS total FROM totals').get().total, 3);
  assert.deepEqual(JSON.parse(readFileSync(new URL('./wrangler.jsonc', import.meta.url),'utf8')).triggers.crons, []);
  db.close();
});
test('dashboard escapes content and handles empty data', () => {
  const range=dateRange(new URLSearchParams('days=30'));
  assert.match(dashboard([], range), /No statistics received/);
  assert.ok(!dashboard([{ day:'2026-09-16', episode: 1, level: 1, difficulty: 'normal', metric: '<script>bad()</script>', value: 1 }], range).includes('<script>'));
});

test('daily reports preserve dates and support exact dates and all-time history', async () => {
  const { db, binding } = database();
  db.exec("INSERT INTO totals VALUES ('2025-01-01',1,1,'normal','attempts',1), ('2026-09-15',1,1,'normal','attempts',2), ('2026-09-16',1,1,'normal','attempts',3)");
  const all=await dailyRows(binding,dateRange(new URLSearchParams('days=all')));
  assert.deepEqual(all.map(r=>[r.day,r.value]),[['2026-09-16',3],['2026-09-15',2],['2025-01-01',1]]);
  const exact=dateRange(new URLSearchParams('day=2026-09-15'));
  assert.equal((await dailyRows(binding,exact))[0].value,2);
  const recent=dateRange(new URLSearchParams('days=1'),Date.parse('2026-09-16T23:59:00Z'));
  assert.equal((await dailyRows(binding,recent)).length,1);
  for(const input of ['day=2026-02-30','day=bad','days=100','days=-1'])assert.throws(()=>dateRange(new URLSearchParams(input)));
  assert.match(dashboard(all,dateRange(new URLSearchParams('days=all'))),/2025-01-01/);
  db.close();
});
test('Access signature, audience, issuer and expiration are enforced', async () => {
  const { privateKey, publicKey } = await generateKeyPair('RS256');
  const issuer = 'https://cairn.cloudflareaccess.com';
  const sign = (iss, aud, expires) => new SignJWT({}).setProtectedHeader({ alg: 'RS256' }).setSubject('admin').setIssuedAt().setIssuer(iss).setAudience(aud).setExpirationTime(expires).sign(privateKey);
  await verifyAccessToken(await sign(issuer, 'dashboard', '5m'), issuer, 'dashboard', publicKey);
  for (const token of [await sign(issuer, 'wrong-app', '5m'), await sign('https://other.cloudflareaccess.com', 'dashboard', '5m'), await sign(issuer, 'dashboard', 1)]) {
    await assert.rejects(verifyAccessToken(token, issuer, 'dashboard', publicKey));
  }
  const unrelated = await generateKeyPair('RS256');
  await assert.rejects(verifyAccessToken(await sign(issuer, 'dashboard', '5m'), issuer, 'dashboard', unrelated.publicKey));
});
test('ingestion fails closed when limits are missing, exceeded or unavailable', async () => {
  assert.equal((await worker.fetch(request(sample()), { COLLECTION_ENABLED: 'true' })).status, 503);
  for (const name of ['INGEST_LIMITER', 'INGEST_TOTAL_LIMITER']) {
    const env = { COLLECTION_ENABLED: 'true', ...limits(), [name]: { limit: async () => ({ success: false }) } };
    const rejected = await worker.fetch(request(sample()), env);
    assert.equal(rejected.status, 429);
    assert.equal(rejected.headers.get('Retry-After'), '60');
    env[name].limit = async () => { throw Error('unavailable'); };
    assert.equal((await worker.fetch(request(sample()), env)).status, 503);
  }
});
test('regional defaults use edge country only and never cache decisions', async () => {
  for (const country of ['GB', 'US', 'AU', 'CA', 'DE', undefined]) {
    const req = new Request('https://stats.example/v1/policy', { headers: { 'X-Country': 'US' } });
    if (country) req.cf = { country };
    const result = await worker.fetch(req, {});
    assert.equal((await result.json()).default_enabled, ['GB', 'US', 'AU', 'CA'].includes(country));
    assert.equal(result.headers.get('Cache-Control'), 'no-store');
  }
});
test('outcome relationships remain aggregate counters, including unused moves', () => {
  const metrics = new Map(aggregate(sample()));
  assert.equal(metrics.get('outcome:completed:move:normal:21_plus'), 1);
  assert.equal(metrics.get('outcome:completed:move:charge:none'), 1);
  assert.equal(metrics.get('outcome:completed:duration:3_5m'), 1);
});
