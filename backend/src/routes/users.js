import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';
import { requireUser } from '../middleware/userAuth.js';
import { requireAdmin } from '../middleware/auth.js';

const router = Router();

function rowToUser(row) {
  return {
    id: row.id,
    fullName: row.full_name,
    phone: row.phone,
    email: row.email,
    authProvider: row.auth_provider,
    isPremium: row.is_premium,
    premiumUntil: row.premium_until,
    messageCount: row.message_count,
    createdAt: row.created_at,
  };
}

function signUserToken(user) {
  return jwt.sign(
    { sub: user.id, type: 'user', name: user.full_name },
    process.env.JWT_SECRET,
    { expiresIn: '30d' },
  );
}

router.post('/signup', async (req, res) => {
  try {
    const { fullName, phone, email, password, authProvider } = req.body;

    if (!fullName?.trim()) {
      return res.status(400).json({ error: 'Jina kamili linahitajika' });
    }

    const provider = authProvider || (email ? 'gmail' : 'phone');

    if (provider === 'phone' && !phone?.trim()) {
      return res.status(400).json({ error: 'Nambari ya simu inahitajika' });
    }
    if (provider === 'gmail' && !email?.trim()) {
      return res.status(400).json({ error: 'Barua pepe ya Gmail inahitajika' });
    }
    if (provider === 'gmail' && !password?.trim()) {
      return res.status(400).json({ error: 'Nenosiri linahitajika' });
    }

    const db = getPool();
    const userId = uuidv4();

    if (email) {
      const { rows: existing } = await db.query(
        'SELECT id FROM users WHERE email = $1',
        [email.trim().toLowerCase()],
      );
      if (existing.length) {
        return res.status(409).json({ error: 'Barua pepe tayari imesajiliwa' });
      }
    }

    if (phone) {
      const { rows: existingPhone } = await db.query(
        'SELECT id FROM users WHERE phone = $1',
        [phone.trim()],
      );
      if (existingPhone.length) {
        return res.status(409).json({ error: 'Nambari ya simu tayari imesajiliwa' });
      }
    }

    const passwordHash = password
      ? await bcrypt.hash(password, 10)
      : null;

    await db.query(
      `INSERT INTO users (id, full_name, phone, email, password_hash, auth_provider)
       VALUES ($1,$2,$3,$4,$5,$6)`,
      [
        userId,
        fullName.trim(),
        phone?.trim() || null,
        email?.trim().toLowerCase() || null,
        passwordHash,
        provider,
      ],
    );

    const { rows } = await db.query('SELECT * FROM users WHERE id = $1', [userId]);
    const user = rowToUser(rows[0]);
    const token = signUserToken(rows[0]);

    res.status(201).json({ user, token });
  } catch (err) {
    console.error('POST /users/signup:', err);
    res.status(500).json({ error: 'Imeshindwa kusajili' });
  }
});

router.post('/login', async (req, res) => {
  try {
    const { email, phone, password } = req.body;
    const db = getPool();

    let rows;
    if (email) {
      ({ rows } = await db.query(
        'SELECT * FROM users WHERE email = $1',
        [email.trim().toLowerCase()],
      ));
    } else if (phone) {
      ({ rows } = await db.query(
        'SELECT * FROM users WHERE phone = $1',
        [phone.trim()],
      ));
    } else {
      return res.status(400).json({ error: 'Barua pepe au simu inahitajika' });
    }

    if (!rows.length) {
      return res.status(401).json({ error: 'Akaunti haipatikani' });
    }

    const user = rows[0];
    if (user.password_hash) {
      const valid = await bcrypt.compare(password || '', user.password_hash);
      if (!valid) return res.status(401).json({ error: 'Nenosiri si sahihi' });
    }

    const token = signUserToken(user);
    res.json({ user: rowToUser(user), token });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kuingia' });
  }
});

router.get('/me', requireUser, async (req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query('SELECT * FROM users WHERE id = $1', [req.user.sub]);
    if (!rows.length) return res.status(404).json({ error: 'Mtumiaji haipatikani' });

    const { rows: purchases } = await db.query(
      'SELECT content_id FROM user_purchases WHERE user_id = $1',
      [req.user.sub],
    );

    res.json({
      user: rowToUser(rows[0]),
      purchasedContentIds: purchases.map((p) => p.content_id),
    });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata taarifa' });
  }
});

router.post('/purchase', requireUser, async (req, res) => {
  try {
    const { contentId, type } = req.body;
    const db = getPool();
    const userId = req.user.sub;

    if (type === 'premium') {
      const { rows: settings } = await db.query(
        "SELECT value FROM app_settings WHERE key = 'premium_price'",
      );
      const price = parseInt(settings[0]?.value || '15000', 10);

      await db.query(
        `UPDATE users SET is_premium = TRUE,
         premium_until = NOW() + INTERVAL '30 days', updated_at = NOW()
         WHERE id = $1`,
        [userId],
      );

      return res.json({ ok: true, type: 'premium', amount: price });
    }

    if (!contentId) {
      return res.status(400).json({ error: 'Maudhui yanahitajika' });
    }

    const { rows: posts } = await db.query(
      'SELECT price, is_premium FROM content_posts WHERE id = $1',
      [contentId],
    );
    if (!posts.length) return res.status(404).json({ error: 'Maudhui hayapatikani' });

    const amount = posts[0].price || 2000;

    const { rows: existing } = await db.query(
      'SELECT id FROM user_purchases WHERE user_id = $1 AND content_id = $2',
      [userId, contentId],
    );
    if (existing.length) {
      return res.json({ ok: true, alreadyPurchased: true });
    }

    await db.query(
      'INSERT INTO user_purchases (id, user_id, content_id, amount) VALUES ($1,$2,$3,$4)',
      [uuidv4(), userId, contentId, amount],
    );

    res.json({ ok: true, contentId, amount });
  } catch (err) {
    console.error('POST /users/purchase:', err);
    res.status(500).json({ error: 'Imeshindwa kulipa' });
  }
});

router.get('/admin/all', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      'SELECT * FROM users ORDER BY created_at DESC',
    );
    res.json({ users: rows.map(rowToUser) });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata watumiaji' });
  }
});

router.patch('/admin/:id/premium', requireAdmin, async (req, res) => {
  try {
    const { isPremium } = req.body;
    const db = getPool();
    await db.query(
      `UPDATE users SET is_premium = $2,
       premium_until = CASE WHEN $2 THEN NOW() + INTERVAL '30 days' ELSE NULL END,
       updated_at = NOW() WHERE id = $1`,
      [req.params.id, !!isPremium],
    );
    const { rows } = await db.query('SELECT * FROM users WHERE id = $1', [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Mtumiaji haipatikani' });
    res.json({ user: rowToUser(rows[0]) });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kusasisha' });
  }
});

export default router;
