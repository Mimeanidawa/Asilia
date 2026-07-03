import { Router } from 'express';
import { getPool } from '../db.js';
import { requireAdmin } from '../middleware/auth.js';
import { optionalUser } from '../middleware/userAuth.js';
import { sendContentNotification } from '../services/firebase.js';

const router = Router();

function rowToPost(row, { includeContent = true } = {}) {
  const post = {
    id: row.id,
    section: row.section,
    category: row.category,
    title: row.title,
    subtitle: row.subtitle,
    excerpt: row.excerpt,
    imageUrl: row.image_url,
    isPremium: row.is_premium,
    price: row.price,
    isPublished: row.is_published,
    sortOrder: row.sort_order,
    readTimeMinutes: row.read_time_minutes,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
  if (includeContent) post.content = row.content;
  return post;
}

// Public: list published posts (optionally filter by section/category)
router.get('/', optionalUser, async (req, res) => {
  try {
    const { section, category, limit } = req.query;
    const db = getPool();
    const params = [];
    let where = 'WHERE is_published = TRUE';

    if (section) {
      params.push(section);
      where += ` AND section = $${params.length}`;
    }
    if (category) {
      params.push(category);
      where += ` AND category = $${params.length}`;
    }

    let sql = `SELECT * FROM content_posts ${where}
               ORDER BY sort_order ASC, created_at DESC`;
    if (limit) {
      params.push(parseInt(limit, 10));
      sql += ` LIMIT $${params.length}`;
    }

    const { rows } = await db.query(sql, params);
    res.json({ posts: rows.map((r) => rowToPost(r, { includeContent: false })) });
  } catch (err) {
    console.error('GET /content:', err);
    res.status(500).json({ error: 'Imeshindwa kupata maudhui' });
  }
});

// Public: recommended (random from darasa_huru dodoso + dodoso posts)
router.get('/recommended', async (_req, res) => {
  try {
    const db = getPool();
    const { rows: lessons } = await db.query(
      `SELECT id, title, excerpt, image_url, 'darasa_huru' AS section,
              'darasa_huru' AS category, read_time_minutes, FALSE AS is_premium, 0 AS price
       FROM lessons WHERE is_published = TRUE ORDER BY RANDOM() LIMIT 3`,
    );
    const { rows: dodoso } = await db.query(
      `SELECT id, section, category, title, excerpt, image_url, read_time_minutes, is_premium, price
       FROM content_posts
       WHERE is_published = TRUE AND section = 'dodoso'
       ORDER BY RANDOM() LIMIT 3`,
    );

    const items = [
      ...lessons.map((r) => ({
        id: r.id,
        section: 'darasa_huru',
        category: 'darasa_huru',
        title: r.title,
        excerpt: r.excerpt,
        imageUrl: r.image_url,
        readTimeMinutes: r.read_time_minutes,
        isPremium: false,
        price: 0,
      })),
      ...dodoso.map((r) => ({
        id: r.id,
        section: r.section,
        category: r.category,
        title: r.title,
        excerpt: r.excerpt,
        imageUrl: r.image_url,
        readTimeMinutes: r.read_time_minutes,
        isPremium: r.is_premium,
        price: r.price,
      })),
    ].sort(() => Math.random() - 0.5).slice(0, 6);

    res.json({ items });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata mapendekezo' });
  }
});

// Public: single post (content gated for premium)
router.get('/:id', optionalUser, async (req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      'SELECT * FROM content_posts WHERE id = $1 AND is_published = TRUE',
      [req.params.id],
    );
    if (!rows.length) return res.status(404).json({ error: 'Maudhui hayapatikani' });

    const post = rowToPost(rows[0]);
    const userId = req.user?.sub;

    if (post.isPremium && userId) {
      const { rows: purchases } = await db.query(
        'SELECT 1 FROM user_purchases WHERE user_id = $1 AND content_id = $2',
        [userId, post.id],
      );
      const { rows: users } = await db.query(
        'SELECT is_premium, premium_until FROM users WHERE id = $1',
        [userId],
      );
      const isPremiumUser = users[0]?.is_premium &&
        (!users[0].premium_until || new Date(users[0].premium_until) > new Date());
      post.hasAccess = purchases.length > 0 || isPremiumUser;
    } else if (post.isPremium) {
      post.hasAccess = false;
      post.content = post.excerpt;
    } else {
      post.hasAccess = true;
    }

    if (!post.hasAccess && post.isPremium) {
      post.content = post.excerpt + '\n\n[Lipia TZS ' + post.price + ' ili kusoma makala kamili]';
    }

    res.json({ post });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata maudhui' });
  }
});

// Admin routes
router.get('/admin/all', requireAdmin, async (req, res) => {
  try {
    const { section, category } = req.query;
    const db = getPool();
    const params = [];
    let where = 'WHERE 1=1';

    if (section) {
      params.push(section);
      where += ` AND section = $${params.length}`;
    }
    if (category) {
      params.push(category);
      where += ` AND category = $${params.length}`;
    }

    const { rows } = await db.query(
      `SELECT * FROM content_posts ${where} ORDER BY sort_order ASC, created_at DESC`,
      params,
    );
    res.json({ posts: rows.map((r) => rowToPost(r)) });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata maudhui' });
  }
});

router.post('/admin', requireAdmin, async (req, res) => {
  try {
    const {
      id, section, category, title, subtitle, excerpt, content,
      imageUrl, isPremium, price, isPublished, sortOrder, readTimeMinutes,
    } = req.body;

    if (!title?.trim() || !section) {
      return res.status(400).json({ error: 'Kichwa na sehemu vinahitajika' });
    }

    const postId = id || `post-${Date.now()}`;
    const db = getPool();

    await db.query(
      `INSERT INTO content_posts
        (id, section, category, title, subtitle, excerpt, content, image_url,
         is_premium, price, is_published, sort_order, read_time_minutes)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
      [
        postId,
        section,
        category || null,
        title.trim(),
        subtitle?.trim() || '',
        excerpt?.trim() || '',
        content?.trim() || '',
        imageUrl?.trim() || '',
        !!isPremium,
        price ?? 2000,
        !!isPublished,
        sortOrder ?? 0,
        readTimeMinutes ?? 5,
      ],
    );

    const { rows } = await db.query('SELECT * FROM content_posts WHERE id = $1', [postId]);
    const post = rowToPost(rows[0]);

    let notification = null;
    if (post.isPublished) {
      try {
        notification = await sendContentNotification(post);
      } catch (_) {}
    }

    res.status(201).json({ post, notification });
  } catch (err) {
    console.error('POST /content/admin:', err);
    res.status(500).json({ error: 'Imeshindwa kuunda maudhui' });
  }
});

router.put('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const {
      section, category, title, subtitle, excerpt, content,
      imageUrl, isPremium, price, isPublished, sortOrder, readTimeMinutes,
    } = req.body;
    const db = getPool();

    const { rows: existing } = await db.query(
      'SELECT is_published FROM content_posts WHERE id = $1',
      [req.params.id],
    );
    if (!existing.length) return res.status(404).json({ error: 'Maudhui hayapatikani' });
    const wasPublished = existing[0].is_published;

    const result = await db.query(
      `UPDATE content_posts SET
        section = COALESCE($2, section),
        category = COALESCE($3, category),
        title = COALESCE($4, title),
        subtitle = COALESCE($5, subtitle),
        excerpt = COALESCE($6, excerpt),
        content = COALESCE($7, content),
        image_url = COALESCE($8, image_url),
        is_premium = COALESCE($9, is_premium),
        price = COALESCE($10, price),
        is_published = COALESCE($11, is_published),
        sort_order = COALESCE($12, sort_order),
        read_time_minutes = COALESCE($13, read_time_minutes),
        updated_at = NOW()
       WHERE id = $1 RETURNING *`,
      [
        req.params.id, section, category, title?.trim(), subtitle?.trim(),
        excerpt?.trim(), content?.trim(), imageUrl?.trim(), isPremium,
        price, isPublished, sortOrder, readTimeMinutes,
      ],
    );

    if (!result.rows.length) return res.status(404).json({ error: 'Maudhui hayapatikani' });

    const post = rowToPost(result.rows[0]);
    let notification = null;
    if (post.isPublished && !wasPublished) {
      try {
        notification = await sendContentNotification(post);
      } catch (_) {}
    }

    res.json({ post, notification });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kusasisha maudhui' });
  }
});

router.patch('/admin/:id/publish', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const { rows: existing } = await db.query(
      'SELECT is_published FROM content_posts WHERE id = $1',
      [req.params.id],
    );
    if (!existing.length) return res.status(404).json({ error: 'Maudhui hayapatikani' });

    const newPublished = !existing[0].is_published;
    await db.query(
      'UPDATE content_posts SET is_published = $2, updated_at = NOW() WHERE id = $1',
      [req.params.id, newPublished],
    );

    const { rows } = await db.query('SELECT * FROM content_posts WHERE id = $1', [req.params.id]);
    const post = rowToPost(rows[0]);

    let notification = null;
    if (newPublished) {
      try {
        notification = await sendContentNotification(post);
      } catch (_) {}
    }

    res.json({ post, notification });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kubadilisha hali' });
  }
});

router.delete('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const result = await db.query('DELETE FROM content_posts WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Maudhui hayapatikani' });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kufuta maudhui' });
  }
});

export default router;
