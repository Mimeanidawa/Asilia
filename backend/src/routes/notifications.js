import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';
import { requireAdmin } from '../middleware/auth.js';

const router = Router();

function rowToNotification(row) {
  return {
    id: row.id,
    title: row.title,
    body: row.body,
    target: row.target || 'all',
    status: row.status || 'sent',
    sentCount: row.sent_count ?? 0,
    source: row.source || 'broadcast',
    createdAt: row.created_at,
  };
}

/** Persist a sent push for admin history. Safe to call from other routes. */
export async function recordNotificationHistory({
  title,
  body,
  target = 'all',
  status = 'sent',
  sentCount = 0,
  source = 'broadcast',
}) {
  if (!title?.trim() || !body?.trim()) return null;
  const db = getPool();
  const id = uuidv4();
  const { rows } = await db.query(
    `INSERT INTO notification_history
      (id, title, body, target, status, sent_count, source)
     VALUES ($1, $2, $3, $4, $5, $6, $7)
     RETURNING *`,
    [
      id,
      title.trim(),
      body.trim(),
      target || 'all',
      status || 'sent',
      Number.isFinite(sentCount) ? sentCount : 0,
      source || 'broadcast',
    ],
  );
  return rowToNotification(rows[0]);
}

router.get('/admin', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM notification_history
       ORDER BY created_at DESC
       LIMIT 200`,
    );
    res.json({ notifications: rows.map(rowToNotification) });
  } catch (err) {
    console.error('GET /notifications/admin:', err);
    res.status(500).json({ error: 'Failed to fetch notifications' });
  }
});

router.delete('/admin/:id', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const result = await db.query(
      'DELETE FROM notification_history WHERE id = $1',
      [req.params.id],
    );
    if (result.rowCount === 0) {
      return res.status(404).json({ error: 'Notification not found' });
    }
    res.json({ ok: true });
  } catch (err) {
    console.error('DELETE /notifications/admin/:id:', err);
    res.status(500).json({ error: 'Failed to delete notification' });
  }
});

router.delete('/admin', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    await db.query('DELETE FROM notification_history');
    res.json({ ok: true });
  } catch (err) {
    console.error('DELETE /notifications/admin:', err);
    res.status(500).json({ error: 'Failed to clear notifications' });
  }
});

export default router;
