import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';

const router = Router();

router.post('/register', async (req, res) => {
  try {
    const { token, platform } = req.body;
    if (!token?.trim()) {
      return res.status(400).json({ error: 'FCM token required' });
    }

    const db = getPool();
    await db.query(
      `INSERT INTO device_tokens (id, token, platform, updated_at)
       VALUES ($1, $2, $3, NOW())
       ON CONFLICT (token) DO UPDATE SET platform = $3, updated_at = NOW()`,
      [uuidv4(), token.trim(), platform || 'unknown'],
    );

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

export default router;
