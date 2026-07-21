import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';
import { optionalUser } from '../middleware/userAuth.js';
import { requireAdmin } from '../middleware/auth.js';
import { sendBroadcastNotification } from '../services/firebase.js';
import { recordNotificationHistory } from './notifications.js';

const router = Router();

router.post('/register', optionalUser, async (req, res) => {
  try {
    const { token, platform } = req.body;
    if (!token?.trim()) {
      return res.status(400).json({ error: 'FCM token required' });
    }

    const userId = req.user?.sub ?? null;
    const db = getPool();

    if (userId) {
      await db.query(
        `INSERT INTO device_tokens (id, token, platform, user_id, updated_at)
         VALUES ($1, $2, $3, $4, NOW())
         ON CONFLICT (token) DO UPDATE SET
           platform = EXCLUDED.platform,
           user_id = EXCLUDED.user_id,
           updated_at = NOW()`,
        [uuidv4(), token.trim(), platform || 'unknown', userId],
      );
    } else {
      await db.query(
        `INSERT INTO device_tokens (id, token, platform, updated_at)
         VALUES ($1, $2, $3, NOW())
         ON CONFLICT (token) DO UPDATE SET
           platform = EXCLUDED.platform,
           updated_at = NOW()`,
        [uuidv4(), token.trim(), platform || 'unknown'],
      );
    }

    res.json({ ok: true });
  } catch (err) {
    console.error('Device register:', err);
    res.status(500).json({ error: 'Failed to register device' });
  }
});

router.get('/count', async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query('SELECT COUNT(*)::int AS count FROM device_tokens');
    res.json({ count: rows[0].count });
  } catch (err) {
    res.status(500).json({ error: 'Failed to count devices' });
  }
});

router.post('/broadcast', requireAdmin, async (req, res) => {
  try {
    const { title, body, target } = req.body;
    if (!title?.trim() || !body?.trim()) {
      return res.status(400).json({ error: 'Title and body required' });
    }

    const audience = target || 'all';
    const result = await sendBroadcastNotification({
      title: title.trim(),
      body: body.trim(),
      target: audience,
    });

    const sent = !!result?.sent;
    const sentCount =
      typeof result?.successCount === 'number'
        ? result.successCount
        : sent
          ? 1
          : 0;

    let history = null;
    try {
      history = await recordNotificationHistory({
        title: title.trim(),
        body: body.trim(),
        target: audience,
        status: sent ? 'sent' : 'failed',
        sentCount,
        source: 'broadcast',
      });
    } catch (historyErr) {
      console.error('Failed to save notification history:', historyErr);
    }

    res.json({
      ok: true,
      notification: {
        ...result,
        id: history?.id,
        title: title.trim(),
        body: body.trim(),
        target: audience,
        status: history?.status ?? (sent ? 'sent' : 'failed'),
        sentCount: history?.sentCount ?? sentCount,
        createdAt: history?.createdAt,
      },
    });
  } catch (err) {
    console.error('Broadcast notification:', err);
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

export default router;
