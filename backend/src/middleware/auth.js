import { assertAdminSession } from '../routes/auth.js';

export async function requireAdmin(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing authorization token' });
  }

  try {
    req.admin = await assertAdminSession(header.slice(7));
    next();
  } catch {
    return res.status(401).json({ error: 'Invalid or expired token' });
  }
}
