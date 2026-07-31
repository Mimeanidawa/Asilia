import { Router } from 'express';
import {
  findCachedMedia,
  getCachedMediaById,
  ingestImageUrl,
  mediaPublicPath,
} from '../utils/mediaCache.js';
import { resolveImageUrl, normalizeImageUrl, tidyImageUrl } from '../utils/resolveImageUrl.js';
import { requireAdmin } from '../middleware/auth.js';

const router = Router();

function isAllowedTarget(raw) {
  const url = tidyImageUrl(raw);
  if (!url) return null;
  try {
    const parsed = new URL(url);
    if (parsed.protocol !== 'http:' && parsed.protocol !== 'https:') return null;
    const host = parsed.hostname.toLowerCase();
    if (
      host === 'localhost' ||
      host === '127.0.0.1' ||
      host.endsWith('.local') ||
      host.endsWith('.internal')
    ) {
      return null;
    }
    return parsed.toString();
  } catch {
    return null;
  }
}

/**
 * Stream a remote image through our API (with server-side cache).
 * GET /api/images/proxy?url=...
 */
router.get('/proxy', async (req, res) => {
  const rawTarget = isAllowedTarget(req.query.url);
  if (!rawTarget) {
    return res.status(400).json({ error: 'URL ya picha si sahihi' });
  }

  const target = normalizeImageUrl(rawTarget);

  async function streamCached(sourceUrl) {
    const cached = await findCachedMedia(sourceUrl);
    if (!cached) return false;
    const full = await getCachedMediaById(cached.id);
    if (!full?.bytes) return false;
    res.setHeader('Content-Type', full.content_type || 'image/jpeg');
    res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Asilia-Media', full.id);
    res.status(200).send(full.bytes);
    return true;
  }

  try {
    for (const candidate of [target, rawTarget]) {
      if (await streamCached(candidate)) return undefined;
    }

    let ingested = await ingestImageUrl(target, { includeBuffer: true });
    if (!ingested?.buffer) {
      const resolved = await resolveImageUrl(target);
      if (resolved && resolved !== target) {
        ingested = await ingestImageUrl(resolved, { includeBuffer: true });
      }
    }

    if (!ingested?.buffer) {
      return res.status(502).json({ error: 'Imeshindwa kupakia picha' });
    }

    res.setHeader('Content-Type', ingested.contentType || 'image/jpeg');
    res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('X-Asilia-Media', ingested.id);
    return res.status(200).send(ingested.buffer);
  } catch (err) {
    console.warn('image proxy failed:', target, err.message);
    if (!res.headersSent) {
      return res.status(502).json({ error: 'Imeshindwa kupakia picha' });
    }
    return undefined;
  }
});

router.get('/resolve', async (req, res) => {
  const rawTarget = isAllowedTarget(req.query.url);
  if (!rawTarget) {
    return res.status(400).json({ error: 'URL ya picha si sahihi' });
  }

  const apiBase = `${req.protocol}://${req.get('host')}`;
  const target = normalizeImageUrl(rawTarget);

  try {
    for (const candidate of [target, rawTarget]) {
      const cached = await findCachedMedia(candidate);
      if (cached?.id) {
        return res.json({
          url: `${apiBase}${mediaPublicPath(cached.id)}`,
          mediaId: cached.id,
          cached: true,
        });
      }
    }

    let ingested = await ingestImageUrl(target);
    if (!ingested?.id) {
      const resolved = await resolveImageUrl(target);
      if (resolved && resolved !== target) {
        ingested = await ingestImageUrl(resolved);
      }
    }

    if (ingested?.id) {
      return res.json({
        url: `${apiBase}${mediaPublicPath(ingested.id)}`,
        mediaId: ingested.id,
        cached: true,
      });
    }

    return res.json({
      url: `${apiBase}/api/images/proxy?url=${encodeURIComponent(target)}`,
      cached: false,
    });
  } catch (err) {
    console.warn('image resolve failed:', target, err.message);
    return res.status(500).json({ error: 'Imeshindwa kutatua URL', url: target });
  }
});

/** Admin: force-ingest one or many image URLs into media cache. */
router.post('/ingest', requireAdmin, async (req, res) => {
  const urls = Array.isArray(req.body?.urls)
    ? req.body.urls
    : req.body?.url
      ? [req.body.url]
      : [];
  const results = [];
  for (const raw of urls.slice(0, 40)) {
    try {
      const ingested = await ingestImageUrl(String(raw));
      results.push({
        sourceUrl: raw,
        ok: !!ingested,
        mediaId: ingested?.id || null,
        path: ingested ? mediaPublicPath(ingested.id) : null,
      });
    } catch (err) {
      results.push({ sourceUrl: raw, ok: false, error: err.message });
    }
  }
  res.json({ results });
});

export default router;
