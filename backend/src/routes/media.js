import { Router } from 'express';
import { getCachedMediaById } from '../utils/mediaCache.js';

const router = Router();

/**
 * Serve a cached media asset.
 * GET /api/media/:id
 */
router.get('/:id', async (req, res) => {
  try {
    const row = await getCachedMediaById(req.params.id);
    if (!row?.bytes) {
      return res.status(404).json({ error: 'Picha haipatikani' });
    }
    res.setHeader('Content-Type', row.content_type || 'image/jpeg');
    res.setHeader('Cache-Control', 'public, max-age=604800, immutable');
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Content-Length', row.byte_size || row.bytes.length);
    return res.status(200).send(row.bytes);
  } catch (err) {
    console.error('GET /media/:id', err);
    return res.status(500).json({ error: 'Imeshindwa kupata picha' });
  }
});

export default router;
