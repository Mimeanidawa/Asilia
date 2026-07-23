import { Router } from 'express';
import { resolveImageUrl, tidyImageUrl } from '../utils/resolveImageUrl.js';

const router = Router();

const FETCH_TIMEOUT_MS = 12000;
const MAX_BYTES = 15 * 1024 * 1024;

const BLOCKED_HOSTS = new Set([
  'localhost',
  '127.0.0.1',
  '0.0.0.0',
  '::1',
  'metadata.google.internal',
  'metadata.google',
]);

function isPrivateHostname(hostname) {
  const host = String(hostname || '').toLowerCase().replace(/^\[|\]$/g, '');
  if (BLOCKED_HOSTS.has(host)) return true;
  if (host.endsWith('.local') || host.endsWith('.internal')) return true;
  if (/^10\.\d{1,3}\.\d{1,3}\.\d{1,3}$/.test(host)) return true;
  if (/^192\.168\.\d{1,3}\.\d{1,3}$/.test(host)) return true;
  if (/^172\.(1[6-9]|2\d|3[0-1])\.\d{1,3}\.\d{1,3}$/.test(host)) return true;
  if (/^169\.254\.\d{1,3}\.\d{1,3}$/.test(host)) return true;
  if (/^100\.(6[4-9]|[7-9]\d|1[0-2]\d)\.\d{1,3}\.\d{1,3}$/.test(host)) return true;
  return false;
}

function isAllowedTarget(raw) {
  const url = tidyImageUrl(raw);
  if (!url) return null;
  let parsed;
  try {
    parsed = new URL(url);
  } catch {
    return null;
  }
  if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return null;
  if (isPrivateHostname(parsed.hostname)) return null;
  return parsed.toString();
}

/**
 * Public image proxy: resolves share pages and streams binary image bytes.
 * GET /api/images/proxy?url=https://...
 */
router.get('/proxy', async (req, res) => {
  const target = isAllowedTarget(req.query.url);
  if (!target) {
    return res.status(400).json({ error: 'URL ya picha si sahihi' });
  }

  try {
    const resolved = await resolveImageUrl(target);
    const fetchUrl = isAllowedTarget(resolved) || target;

    const upstream = await fetch(fetchUrl, {
      redirect: 'follow',
      headers: {
        'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        Accept: 'image/avif,image/webp,image/apng,image/*,*/*;q=0.8',
        'Accept-Language': 'en-US,en;q=0.9',
        Referer: new URL(fetchUrl).origin + '/',
      },
      signal: AbortSignal.timeout(FETCH_TIMEOUT_MS),
    });

    if (!upstream.ok) {
      return res.status(upstream.status === 404 ? 404 : 502).json({
        error: 'Imeshindwa kupata picha',
        status: upstream.status,
      });
    }

    const contentType = (upstream.headers.get('content-type') || '').toLowerCase();
    // Some CDNs return HTML error pages; reject those.
    if (contentType.includes('text/html') || contentType.includes('application/json')) {
      return res.status(502).json({ error: 'URL hairejeshi picha' });
    }

    const lengthHeader = upstream.headers.get('content-length');
    if (lengthHeader && Number(lengthHeader) > MAX_BYTES) {
      return res.status(413).json({ error: 'Picha ni kubwa mno' });
    }

    const buffer = Buffer.from(await upstream.arrayBuffer());
    if (buffer.length > MAX_BYTES) {
      return res.status(413).json({ error: 'Picha ni kubwa mno' });
    }

    const type =
      contentType.startsWith('image/')
        ? contentType.split(';')[0]
        : 'image/jpeg';

    res.setHeader('Content-Type', type);
    res.setHeader('Cache-Control', 'public, max-age=86400, stale-while-revalidate=604800');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    return res.status(200).send(buffer);
  } catch (err) {
    console.warn('image proxy failed:', target, err.message);
    return res.status(502).json({ error: 'Imeshindwa kupakia picha' });
  }
});

/**
 * Resolve a share/page URL to a direct CDN image URL (JSON).
 * GET /api/images/resolve?url=https://ibb.co/...
 */
router.get('/resolve', async (req, res) => {
  const target = isAllowedTarget(req.query.url);
  if (!target) {
    return res.status(400).json({ error: 'URL ya picha si sahihi' });
  }
  try {
    const resolved = await resolveImageUrl(target);
    res.json({ url: resolved || target });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kutatua URL', url: target });
  }
});

export default router;
