/**
 * Public HTTPS origin for media / FCM image URLs.
 * Railway terminates TLS at the proxy, so req.protocol is http unless trust proxy is on.
 */
export function publicApiBase(req) {
  const envBase = String(
    process.env.PUBLIC_API_URL || process.env.API_BASE_URL || '',
  ).replace(/\/$/, '');

  const forwardedProto = String(req?.get?.('x-forwarded-proto') || '')
    .split(',')[0]
    .trim();
  const proto = forwardedProto || req?.protocol || '';
  const forwardedHost = String(req?.get?.('x-forwarded-host') || '')
    .split(',')[0]
    .trim();
  const host = forwardedHost || req?.get?.('host') || '';
  const isLocal = /localhost|127\.0\.0\.1/i.test(host);

  if (host) {
    const scheme = isLocal ? (proto || 'http') : 'https';
    return `${scheme}://${host}`;
  }

  if (envBase) return envBase;

  const railway = process.env.RAILWAY_PUBLIC_DOMAIN;
  if (railway) return `https://${railway.replace(/^https?:\/\//, '')}`;

  return 'https://asilia-production.up.railway.app';
}

export function absoluteApiUrl(path, req) {
  const base = publicApiBase(req);
  if (!path) return base;
  if (/^https?:\/\//i.test(path)) return path;
  const normalized = path.startsWith('/') ? path : `/${path}`;
  return `${base}${normalized}`;
}
