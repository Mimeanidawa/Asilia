import jwt from 'jsonwebtoken';

export function requireUser(req, res, next) {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Ingia kwanza ili kuendelea' });
  }

  const token = header.slice(7);
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    if (payload.type !== 'user') {
      return res.status(401).json({ error: 'Token si sahihi' });
    }
    req.user = payload;
    next();
  } catch {
    return res.status(401).json({ error: 'Token imeisha au si sahihi' });
  }
}

export function optionalUser(req, _res, next) {
  const header = req.headers.authorization;
  if (header?.startsWith('Bearer ')) {
    try {
      const payload = jwt.verify(header.slice(7), process.env.JWT_SECRET);
      if (payload.type === 'user') req.user = payload;
    } catch { /* ignore */ }
  }
  next();
}
