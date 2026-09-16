# Cairn gameplay statistics

An independent Cloudflare Worker + D1 service. The game is **not yet instrumented** and collection ships disabled. Nothing in this folder publishes automatically or changes the game build.

## Local development

From this folder:

```powershell
npm ci
npm run db:local
npm test
npm run dev
```

The local endpoint is http://127.0.0.1:8787/v1/attempt. `/admin` intentionally denies access without a valid Cloudflare Access JWT, including locally; there is no development authentication bypass. To exercise collection locally, put `COLLECTION_ENABLED="true"` in an ignored `.dev.vars` file. Tests use temporary in-memory SQLite, never production data.

## Deployment and dashboard authentication

1. Run `npx wrangler login`, then `npx wrangler d1 create cairn-telemetry`. Replace the placeholder `database_id` in `wrangler.jsonc` with the returned ID.
2. Configure a Worker custom domain you own in Wrangler (for example a `routes` entry with `pattern: "stats.your-domain.example"` and `custom_domain: true`). Keep `workers_dev` and preview URLs disabled.
3. In Cloudflare Zero Trust, create an Access self-hosted application protecting **both** `/admin` and `/admin/*` on that domain. Allow only your email/account, using email one-time PIN or your identity provider. Do not protect `/v1/attempt`, which the game must reach without a user account.
4. Set `ACCESS_TEAM_DOMAIN` to your `<team>.cloudflareaccess.com` hostname and `ACCESS_AUD` to the application's audience tag. These are configuration identifiers, not login secrets. The Worker verifies signature, issuer, audience and expiration; merely supplying an email header is insufficient.
5. Set `ALLOWED_ORIGINS` to exact comma-separated browser-game origins if needed. Native clients send no Origin. CORS is not authentication or abuse protection.
6. Run `npm run db:remote`, `npm run check`, then `npm run deploy` when ready to publish. Open `https://<your-domain>/admin` and verify Access authentication and JSON export. Verify direct unauthenticated requests to both admin routes are denied.
7. Before enabling collection, review the actual metric schema, applicable consent/default policy, Cloudflare data processing terms, security logs and retention. Set `COLLECTION_ENABLED` to `true` only when the client preferences and disclosure are implemented.

Use a Cloudflare WAF rate-limit rule on `POST /v1/attempt` before public release and budget alerts. IP-based edge rate limiting processes IPs; account for that separately from analytics. An anonymous public collector cannot prove submissions came from genuine players. Do not embed an API secret in the game: it would be extractable. Deliberate spoofing and duplicate reports remain possible.

## Client contract

Send **one** JSON summary when a level/screen attempt completes, ends in death, or is abandoned. `level` means the game's area/screen 1–4 within episode 1–3, not a wave. Difficulty uses the existing internal `normal` value for medium. Count moves actually initiated, not held-button frames. Track active gameplay time excluding menus, pauses and cutscenes. Score should be the score earned during that attempt, not cumulative episode score.

```json
{
  "schema": 1,
  "episode": 1,
  "level": 2,
  "difficulty": "normal",
  "outcome": "completed",
  "duration": "3_5m",
  "score": "5000_9999",
  "moves": { "normal": 42, "charge": 2, "spin": 1, "slam": 3, "throw": 0 },
  "features": { "controls": true, "intro_watched": false, "intro_skipped": false, "music_player": false, "weapon_menu": false }
}
```

`POST /v1/attempt`, `Content-Type: application/json`, maximum 4096 bytes. Unknown properties are rejected at every level. No free text is accepted. Move counts are integers from 0 through 10000; feature values are booleans. Omitted move/feature entries count as zero/false; all other fields are required.

- Outcomes: `completed`, `died`, `quit`.
- Duration buckets (seconds): `[0,60)` → `under_1m`, `[60,180)` → `1_3m`, `[180,300)` → `3_5m`, `[300,600)` → `5_10m`, `[600,1200)` → `10_20m`, `[1200,∞)` → `20m_plus`.
- Score buckets: `0_999`, `1000_4999`, `5000_9999`, `10000_24999`, `25000_49999`, `50000_plus`.
- Features count attempts during which the feature was used. Menu-only engagement is not currently collected. Clear feature flags after submission; do not count the same intro across every level.

Use an asynchronous request with a short timeout. Do not block gameplay or retry automatically: the service has no identifying deduplication key. On opt-out, discard local counters and queued submissions immediately, cancel pending requests where possible, and stop collecting. Already submitted aggregates cannot be attributed to a player or selectively deleted. Preserve the user's choice. Do not send historical activity from before consent/eligible collection was enabled. Do not put user data in URLs, headers or user-agent strings.

Regional policy is intentionally not built into this service. The client must enforce the reviewed policy before collecting or sending anything. An accepted request is not evidence of consent. No country or IP is stored in D1.

## Storage and privacy boundaries

The Worker breaks each request into separate counters keyed only by UTC receipt day, episode, level, difficulty and metric. A single atomic D1 batch increments them. It never saves request bodies, player/install/session IDs, IP addresses, exact timestamps or per-attempt records. Duration and score become independent histograms, so individual score/time/move combinations cannot be reconstructed from stored submissions. Small aggregate cells may still disclose uncommon activity; avoid publishing them externally without suppression.

Scheduled cleanup retains 90 UTC days. D1 backups/Time Travel may retain deleted values according to platform settings. Worker observability is disabled and code does not log requests. **Cloudflare still processes network metadata**, and account-level logging, WAF/security records, Access login logs and provider retention must be reviewed separately. Do not promise that no personal data is processed anywhere. Access identities belong to dashboard administrators, not players.

The dashboard shows received attempt totals, completion rates and per-level metric totals over 7, 30 or 90 days, plus authenticated JSON export. It cannot measure unique/returning players, exact average times/scores or player histories. Missing submissions (crashes/offline/opt-outs) and spoofed submissions affect the results.

References: [D1 batches](https://developers.cloudflare.com/d1/worker-api/d1-database/), [Access JWT validation](https://developers.cloudflare.com/cloudflare-one/access-controls/applications/http-apps/authorization-cookie/validating-json/).
