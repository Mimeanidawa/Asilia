import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';
import { requireUser } from '../middleware/userAuth.js';
import { requireAdmin } from '../middleware/auth.js';
import { normalizePhone, phoneLookupVariants, userStatus } from '../utils/phone.js';

const router = Router();

function rowToUser(row) {
  return {
    id: String(row.id),
    fullName: row.full_name,
    phone: row.phone,
    email: row.email,
    authProvider: row.auth_provider,
    isPremium: row.is_premium,
    premiumUntil: row.premium_until instanceof Date ? row.premium_until.toISOString() : row.premium_until,
    messageCount: Number(row.message_count || 0),
    status: row.status || 'active',
    createdAt: row.created_at instanceof Date ? row.created_at.toISOString() : row.created_at,
    updatedAt: row.updated_at instanceof Date ? row.updated_at.toISOString() : row.updated_at,
  };
}

function rowToAdminUser(row) {
  const ids = row.purchased_content_ids || [];
  return {
    ...rowToUser(row),
    purchaseCount: Number(row.purchase_count || 0),
    totalSpent: Number(row.total_spent || 0),
    purchasedContentIds: ids.filter((id) => id != null).map(String),
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
      const variants = phoneLookupVariants(phone);
      const { rows: existingPhone } = await db.query(
        'SELECT id FROM users WHERE phone = ANY($1::text[]) LIMIT 1',
        [variants],
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
        phone?.trim() ? (normalizePhone(phone) || phone.trim()) : null,
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
      const variants = phoneLookupVariants(phone);
      ({ rows } = await db.query(
        'SELECT * FROM users WHERE phone = ANY($1::text[]) LIMIT 1',
        [variants],
      ));
    } else {
      return res.status(400).json({ error: 'Barua pepe au simu inahitajika' });
    }

    if (!rows.length) {
      return res.status(401).json({ error: 'Akaunti haipatikani' });
    }

    const user = rows[0];
    const status = userStatus(user);
    if (status === 'banned') {
      return res.status(403).json({ error: 'Akaunti imefungiwa' });
    }
    if (status === 'suspended') {
      return res.status(403).json({ error: 'Akaunti imesimamishwa' });
    }
    if (user.password_hash) {
      const valid = await bcrypt.compare(password || '', user.password_hash);
      if (!valid) return res.status(401).json({ error: 'Nenosiri si sahihi' });
    }

    await db.query('UPDATE users SET updated_at = NOW() WHERE id = $1', [user.id]);
    user.updated_at = new Date();

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

    const user = rows[0];
    const status = userStatus(user);
    if (status === 'banned') {
      return res.status(403).json({ error: 'Akaunti imefungiwa', status: 'banned' });
    }
    if (status === 'suspended') {
      return res.status(403).json({ error: 'Akaunti imesimamishwa', status: 'suspended' });
    }

    const { rows: purchases } = await db.query(
      'SELECT content_id FROM user_purchases WHERE user_id = $1',
      [req.user.sub],
    );

    res.json({
      user: rowToUser(user),
      purchasedContentIds: purchases.map((p) => p.content_id),
    });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata taarifa' });
  }
});

router.post('/purchase', requireUser, async (req, res) => {
  res.status(410).json({
    error: 'Tumia malipo ya SonicPesa. Fungua makala na bonyeza Lipia.',
    code: 'use_sonicpesa',
  });
});

router.get('/admin/all', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(`
      SELECT u.*,
        (SELECT COUNT(*)::int FROM user_purchases WHERE user_id = u.id) AS purchase_count,
        (SELECT COALESCE(SUM(amount), 0)::int FROM user_purchases WHERE user_id = u.id) AS total_spent,
        (SELECT COALESCE(array_agg(content_id), '{}') FROM user_purchases WHERE user_id = u.id) AS purchased_content_ids
      FROM users u
      ORDER BY u.created_at DESC
    `);
    res.json({ users: rows.map(rowToAdminUser) });
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
    const { rows } = await db.query(`
      SELECT u.*,
        (SELECT COUNT(*)::int FROM user_purchases WHERE user_id = u.id) AS purchase_count,
        (SELECT COALESCE(SUM(amount), 0)::int FROM user_purchases WHERE user_id = u.id) AS total_spent,
        (SELECT COALESCE(array_agg(content_id), '{}') FROM user_purchases WHERE user_id = u.id) AS purchased_content_ids
      FROM users u WHERE u.id = $1
    `, [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Mtumiaji haipatikani' });
    res.json({ user: rowToAdminUser(rows[0]) });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kusasisha' });
  }
});

router.patch('/admin/:id/status', requireAdmin, async (req, res) => {
  try {
    const { status } = req.body;
    const allowed = ['active', 'suspended', 'banned'];
    if (!allowed.includes(status)) {
      return res.status(400).json({ error: 'Hali si sahihi' });
    }
    const db = getPool();
    await db.query(
      'UPDATE users SET status = $2, updated_at = NOW() WHERE id = $1',
      [req.params.id, String(status).trim().toLowerCase()],
    );
    const { rows } = await db.query(`
      SELECT u.*,
        (SELECT COUNT(*)::int FROM user_purchases WHERE user_id = u.id) AS purchase_count,
        (SELECT COALESCE(SUM(amount), 0)::int FROM user_purchases WHERE user_id = u.id) AS total_spent,
        (SELECT COALESCE(array_agg(content_id), '{}') FROM user_purchases WHERE user_id = u.id) AS purchased_content_ids
      FROM users u WHERE u.id = $1
    `, [req.params.id]);
    if (!rows.length) return res.status(404).json({ error: 'Mtumiaji haipatikani' });
    res.json({ user: rowToAdminUser(rows[0]) });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kusasisha' });
  }
});

export default router;
