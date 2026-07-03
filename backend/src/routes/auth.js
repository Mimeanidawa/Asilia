import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';

const router = Router();

export async function ensureDefaultAdmin() {
  const db = getPool();
  const email = process.env.ADMIN_EMAIL || 'mimeanidawa@gmail.com';
  const password = process.env.ADMIN_PASSWORD || 'Mwampulule6%';

  await db.query(
    `UPDATE admins SET email = $1 WHERE email = 'admin@asilia.app'`,
    [email],
  );

  const { rows } = await db.query('SELECT COUNT(*)::int AS count FROM admins');
  if (rows[0].count > 0) return;

  const hash = await bcrypt.hash(password, 12);

  await db.query(
    'INSERT INTO admins (id, email, password_hash, name) VALUES ($1, $2, $3, $4)',
    [uuidv4(), email, hash, 'Dr. Mussa Hassan'],
  );

  console.log(`Default admin created: ${email}`);
}

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const db = getPool();
    const { rows } = await db.query(
      'SELECT id, email, password_hash, name FROM admins WHERE email = $1',
      [email.toLowerCase().trim()],
    );

    if (rows.length === 0) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const admin = rows[0];
    const valid = await bcrypt.compare(password, admin.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const token = jwt.sign(
      { sub: admin.id, email: admin.email, name: admin.name },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
    );

    res.json({
      token,
      admin: { id: admin.id, email: admin.email, name: admin.name },
    });
  } catch (err) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Login failed' });
  }
});

router.get('/me', async (req, res) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Unauthorized' });
  }

  try {
    const payload = jwt.verify(header.slice(7), process.env.JWT_SECRET);
    res.json({ admin: { id: payload.sub, email: payload.email, name: payload.name } });
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
});

export default router;
