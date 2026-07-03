import { Router } from 'express';
import { getPool } from '../db.js';
import { requireAdmin } from '../middleware/auth.js';
import { sendLessonNotification } from '../services/firebase.js';

const router = Router();

function rowToLesson(row) {
  return {
    id: row.id,
    title: row.title,
    excerpt: row.excerpt,
    content: row.content,
    imageUrl: row.image_url,
    publishedAt: row.published_at,
    authorName: row.author_name,
    readTimeMinutes: row.read_time_minutes,
    topicTag: row.topic_tag,
    isPublished: row.is_published,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// ── Public routes ──────────────────────────────────────────────

router.get('/', async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM lessons WHERE is_published = TRUE
       ORDER BY published_at DESC`,
    );
    res.json({ lessons: rows.map(rowToLesson) });
  } catch (err) {
    console.error('GET /lessons:', err);
    res.status(500).json({ error: 'Failed to fetch lessons' });
  }
});

router.get('/today', async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM lessons
       WHERE is_published = TRUE AND published_at = CURRENT_DATE
       ORDER BY updated_at DESC LIMIT 1`,
    );

    if (rows.length > 0) {
      return res.json({ lesson: rowToLesson(rows[0]) });
    }

    const { rows: latest } = await db.query(
      `SELECT * FROM lessons WHERE is_published = TRUE
       ORDER BY published_at DESC LIMIT 1`,
    );

    res.json({ lesson: latest.length ? rowToLesson(latest[0]) : null });
  } catch (err) {
    console.error('GET /lessons/today:', err);
    res.status(500).json({ error: 'Failed to fetch today lesson' });
  }
});

// ── Admin routes ───────────────────────────────────────────────

router.get('/admin/all', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      'SELECT * FROM lessons ORDER BY published_at DESC',
    );
    res.json({ lessons: rows.map(rowToLesson) });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch lessons' });
  }
});

router.post('/admin', requireAdmin, async (req, res) => {
  try {
    const {
      id,
      title,
      excerpt,
      content,
      imageUrl,
      publishedAt,
      authorName,
      readTimeMinutes,
      topicTag,
      isPublished,
    } = req.body;

    if (!title?.trim()) {
      return res.status(400).json({ error: 'Title is required' });
    }

    const lessonId = id || `dh-${Date.now()}`;
    const db = getPool();

    await db.query(
      `INSERT INTO lessons
        (id, title, excerpt, content, image_url, published_at,
         author_name, read_time_minutes, topic_tag, is_published)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10)`,
      [
        lessonId,
        title.trim(),
        excerpt?.trim() || '',
        content?.trim() || '',
        imageUrl?.trim() || '',
        publishedAt || new Date().toISOString().slice(0, 10),
        authorName?.trim() || 'Mwalimu Mussa Hassan',
        readTimeMinutes || 4,
        topicTag || null,
        !!isPublished,
      ],
    );

    const { rows } = await db.query('SELECT * FROM lessons WHERE id = $1', [lessonId]);
    const lesson = rowToLesson(rows[0]);

    let notification = null;
    if (lesson.isPublished) {
      notification = await sendLessonNotification(lesson);
    }

    res.status(201).json({ lesson, notification });
  } catch (err) {
    console.error('POST /admin lessons:', err);
    res.status(500).json({ error: 'Failed to create lesson' });
  }
});

router.put('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const {
      title,
      excerpt,
      content,
      imageUrl,
      publishedAt,
      authorName,
      readTimeMinutes,
      topicTag,
      isPublished,
    } = req.body;

    const db = getPool();
    const { rows: existing } = await db.query(
      'SELECT is_published FROM lessons WHERE id = $1',
      [req.params.id],
    );
    if (!existing.length) return res.status(404).json({ error: 'Lesson not found' });

    const wasPublished = existing[0].is_published;

    await db.query(
      `UPDATE lessons SET
        title = COALESCE($2, title),
        excerpt = COALESCE($3, excerpt),
        content = COALESCE($4, content),
        image_url = COALESCE($5, image_url),
        published_at = COALESCE($6, published_at),
        author_name = COALESCE($7, author_name),
        read_time_minutes = COALESCE($8, read_time_minutes),
        topic_tag = COALESCE($9, topic_tag),
        is_published = COALESCE($10, is_published),
        updated_at = NOW()
       WHERE id = $1`,
      [
        req.params.id,
        title?.trim(),
        excerpt?.trim(),
        content?.trim(),
        imageUrl?.trim(),
        publishedAt,
        authorName?.trim(),
        readTimeMinutes,
        topicTag,
        isPublished,
      ],
    );

    const { rows } = await db.query('SELECT * FROM lessons WHERE id = $1', [req.params.id]);
    const lesson = rowToLesson(rows[0]);

    let notification = null;
    if (lesson.isPublished && !wasPublished) {
      notification = await sendLessonNotification(lesson);
    }

    res.json({ lesson, notification });
  } catch (err) {
    console.error('PUT /admin lessons:', err);
    res.status(500).json({ error: 'Failed to update lesson' });
  }
});

router.patch('/admin/:id/publish', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const { rows: existing } = await db.query(
      'SELECT * FROM lessons WHERE id = $1',
      [req.params.id],
    );
    if (!existing.length) return res.status(404).json({ error: 'Lesson not found' });

    const newPublished = !existing[0].is_published;

    await db.query(
      'UPDATE lessons SET is_published = $2, updated_at = NOW() WHERE id = $1',
      [req.params.id, newPublished],
    );

    const { rows } = await db.query('SELECT * FROM lessons WHERE id = $1', [req.params.id]);
    const lesson = rowToLesson(rows[0]);

    let notification = null;
    if (newPublished) {
      notification = await sendLessonNotification(lesson);
    }

    res.json({ lesson, notification });
  } catch (err) {
    res.status(500).json({ error: 'Failed to toggle publish' });
  }
});

router.delete('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const result = await db.query('DELETE FROM lessons WHERE id = $1', [req.params.id]);
    if (result.rowCount === 0) return res.status(404).json({ error: 'Lesson not found' });
    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Failed to delete lesson' });
  }
});

router.get('/:id', async (req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      'SELECT * FROM lessons WHERE id = $1 AND is_published = TRUE',
      [req.params.id],
    );
    if (!rows.length) return res.status(404).json({ error: 'Lesson not found' });
    res.json({ lesson: rowToLesson(rows[0]) });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch lesson' });
  }
});

export default router;
