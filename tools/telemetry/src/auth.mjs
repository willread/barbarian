import { createRemoteJWKSet, jwtVerify } from 'jose';
const keySets = new Map();
export async function verifyAccessToken(token, issuer, audience, keys) {
  await jwtVerify(token, keys, { issuer, audience, algorithms: ['RS256'], requiredClaims: ['exp', 'iat', 'sub'] });
}
export async function authorized(request, env) {
  if (!env.ACCESS_AUD || !/^[a-z0-9-]+\.cloudflareaccess\.com$/.test(env.ACCESS_TEAM_DOMAIN ?? '')) return false;
  const token = request.headers.get('Cf-Access-Jwt-Assertion');
  if (!token) return false;
  const issuer = `https://${env.ACCESS_TEAM_DOMAIN}`;
  if (!keySets.has(issuer)) keySets.set(issuer, createRemoteJWKSet(new URL(`${issuer}/cdn-cgi/access/certs`)));
  try {
    await verifyAccessToken(token, issuer, env.ACCESS_AUD, keySets.get(issuer));
    return true;
  } catch { return false; }
}
