import { Router } from 'express';
import { getPool } from '../db.js';
import { requireAdmin } from '../middleware/auth.js';

const router = Router();

function rowToCarousel(row) {
  return {
    id: row.id,
    title: row.title,
    subtitle: row.subtitle,
    imageUrl: row.image_url,
    linkSection: row.link_section,
    linkId: row.link_id,
    sortOrder: row.sort_order,
    isPublished: row.is_published,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

router.get('/', async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM carousels WHERE is_published = TRUE
       ORDER BY sort_order ASC, created_at DESC`,
    );
    res.json({ carousels: rows.map(rowToCarousel) });
  } catch (err) {
    console.error('GET /carousels:', err);
    res.status(500).json({ error: 'Imeshindwa kupata carousel' });
  }
});

router.get('/admin/all', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      'SELECT * FROM carousels ORDER BY sort_order ASC, created_at DESC',
    );
    res.json({ carousels: rows.map(rowToCarousel) });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata carousel' });
  }
});

router.post('/admin', requireAdmin, async (req, res) => {
  try {
    const { id, title, subtitle, imageUrl, linkSection, linkId, sortOrder, isPublished } = req.body;
    if (!title?.trim()) return res.status(400).json({ error: 'Kichwa kinahitajika' });

    const carouselId = id || `car-${Date.now()}`;
    const db = getPool();

    await db.query(
      `INSERT INTO carousels
        (id, title, subtitle, image_url, link_section, link_id, sort_order, is_published)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)`,
      [
        carouselId,
        title.trim(),
        subtitle?.trim() || '',
        imageUrl?.trim() || '',
        linkSection || null,
        linkId || null,
        sortOrder ?? 0,
        isPublished !== false,
      ],
    );

    const { rows } = await db.query('SELECT * FROM carousels WHERE id = $1', [carouselId]);
    res.status(201).json({ carousel: rowToCarousel(rows[0]) });
  } catch (err) {
    console.error('POST /carousels/admin:', err);
    res.status(500).json({ error: 'Imeshindwa kuunda carousel' });
  }
});

router.put('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const { title, subtitle, imageUrl, linkSection, linkId, sortOrder, isPublished } = req.body;
    const db = getPool();

    const result = await db.query(
      `UPDATE carousels SET
        title = COALESCE($2, title),
        subtitle = COALESCE($3, subtitle),
        image_url = COALESCE($4, image_url),
        link_section = COALESCE($5, link_section),
        link_id = COALESCE($6, link_id),
        sort_order = COALESCE($7, sort_order),
        is_published = COALESCE($8, is_published),
        updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [req.params.id, title?.trim(), subtitle?.trim(), imageUrl?.trim(), linkSection, linkId, sortOrder, isPublished],
    );

    if (!result.rows.length) return res.status(404).json({ error: 'Carousel haipatikani' });
    res.json({ carousel: rowToCarousel(result.rows[0]) });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kusasisha carousel' });
  }
});

router.delete('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const result = await db.query('DELETE FROM carousels WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Carousel haipatikani' });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kufuta carousel' });
  }
});

export default router;
