import { Router } from 'express';
import {
  findCachedMedia,
  getCachedMediaById,
  ingestImageUrl,
  mediaPublicPath,
} from '../utils/mediaCache.js';
import { tidyImageUrl } from '../utils/resolveImageUrl.js';
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
  const target = isAllowedTarget(req.query.url);
  if (!target) {
    return res.status(400).json({ error: 'URL ya picha si sahihi' });
  }

  try {
    // Fast path: already cached under this exact source URL.
    const cached = await findCachedMedia(target);
    if (cached) {
      const full = await getCachedMediaById(cached.id);
      if (full?.bytes) {
        res.setHeader('Content-Type', full.content_type || 'image/jpeg');
        res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
        res.setHeader('Access-Control-Allow-Origin', '*');
        res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
        res.setHeader('X-Content-Type-Options', 'nosniff');
        res.setHeader('X-Asilia-Media', full.id);
        return res.status(200).send(full.bytes);
      }
    }

    const ingested = await ingestImageUrl(target, { includeBuffer: true });
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
  const target = isAllowedTarget(req.query.url);
  if (!target) {
    return res.status(400).json({ error: 'URL ya picha si sahihi' });
  }
  try {
    const ingested = await ingestImageUrl(target);
    if (ingested?.id) {
      return res.json({
        url: mediaPublicPath(ingested.id),
        mediaId: ingested.id,
        cached: true,
      });
    }
    res.json({ url: target, cached: false });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kutatua URL', url: target });
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
