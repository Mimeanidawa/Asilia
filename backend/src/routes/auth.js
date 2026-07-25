import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';

const router = Router();

async function invalidateAllAdminSessions(db) {
  await db.query('UPDATE admins SET token_version = token_version + 1');
}

export async function ensureDefaultAdmin() {
  const db = getPool();
  const email = process.env.ADMIN_EMAIL || 'mimeanidawa@gmail.com';
  const password = process.env.ADMIN_PASSWORD || 'unatumia6%';

  await db.query(
    `UPDATE admins SET email = $1 WHERE email = 'admin@asilia.app'`,
    [email],
  );

  const { rows } = await db.query(
    'SELECT id, password_hash FROM admins WHERE email = $1',
    [email],
  );

  if (rows.length > 0) {
    const admin = rows[0];
    const samePassword = await bcrypt.compare(password, admin.password_hash);
    if (!samePassword) {
      const hash = await bcrypt.hash(password, 12);
      await db.query('UPDATE admins SET password_hash = $1 WHERE id = $2', [
        hash,
        admin.id,
      ]);
      await invalidateAllAdminSessions(db);
      console.log('Admin password updated; all admin sessions invalidated');
    }
    return;
  }

  const { rows: countRows } = await db.query(
    'SELECT COUNT(*)::int AS count FROM admins',
  );
  if (countRows[0].count > 0) return;

  const hash = await bcrypt.hash(password, 12);

  await db.query(
    'INSERT INTO admins (id, email, password_hash, name) VALUES ($1, $2, $3, $4)',
    [uuidv4(), email, hash, 'Dr. Mussa Hassan'],
  );

  console.log(`Default admin created: ${email}`);
}

function signAdminToken(admin) {
  return jwt.sign(
    {
      sub: admin.id,
      email: admin.email,
      name: admin.name,
      tv: admin.token_version,
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' },
  );
}

export async function assertAdminSession(token) {
  const payload = jwt.verify(token, process.env.JWT_SECRET);
  const db = getPool();
  const { rows } = await db.query(
    'SELECT id, email, name, token_version FROM admins WHERE id = $1',
    [payload.sub],
  );

  if (rows.length === 0 || Number(rows[0].token_version) !== Number(payload.tv)) {
    const err = new Error('Session expired');
    err.status = 401;
    throw err;
  }

  return {
    sub: rows[0].id,
    email: rows[0].email,
    name: rows[0].name,
    tv: rows[0].token_version,
  };
}

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ error: 'Email and password required' });
    }

    const db = getPool();
    const { rows } = await db.query(
      'SELECT id, email, password_hash, name, token_version FROM admins WHERE email = $1',
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

    const token = signAdminToken(admin);

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
    const admin = await assertAdminSession(header.slice(7));
    res.json({
      admin: { id: admin.sub, email: admin.email, name: admin.name },
    });
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
});

export default router;
