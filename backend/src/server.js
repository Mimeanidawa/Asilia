import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { initDb } from './db.js';
import { initFirebase } from './services/firebase.js';
import authRouter, { ensureDefaultAdmin } from './routes/auth.js';
import lessonsRouter from './routes/lessons.js';
import devicesRouter from './routes/devices.js';
import carouselsRouter from './routes/carousels.js';
import contentRouter from './routes/content.js';
import usersRouter from './routes/users.js';
import chatRouter from './routes/chat.js';
import adminRouter from './routes/admin.js';
import paymentsRouter from './routes/payments.js';
import notificationsRouter from './routes/notifications.js';
import imagesRouter from './routes/images.js';
import mediaRouter from './routes/media.js';

const app = express();
const PORT = process.env.PORT || 3001;

const corsOrigins = process.env.CORS_ORIGINS || '*';
app.use(cors({
  origin: corsOrigins === '*' ? true : corsOrigins.split(',').map((o) => o.trim()),
}));
app.use(express.json({
  limit: '2mb',
  verify: (req, _res, buffer) => {
    req.rawBody = Buffer.from(buffer);
  },
}));

app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'asilia-api',
    db: process.env.DATABASE_URL ? 'configured' : 'missing',
    timestamp: new Date().toISOString(),
  });
});

app.use('/api/auth', authRouter);
app.use('/api/lessons', lessonsRouter);
app.use('/api/devices', devicesRouter);
app.use('/api/carousels', carouselsRouter);
app.use('/api/content', contentRouter);
app.use('/api/users', usersRouter);
app.use('/api/chat', chatRouter);
app.use('/api/admin', adminRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api/notifications', notificationsRouter);
app.use('/api/images', imagesRouter);
app.use('/api/media', mediaRouter);

app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

async function bootstrap() {
  if (!process.env.JWT_SECRET) {
    console.warn('JWT_SECRET is not set — auth will not work until configured');
  }

  if (!process.env.DATABASE_URL) {
    console.warn('DATABASE_URL is not set — link PostgreSQL in Railway');
    return;
  }

  try {
    await initDb();
    await ensureDefaultAdmin();
    initFirebase();
    console.log('Database schema and admin ready');
  } catch (err) {
    console.error('Database bootstrap failed:', err.message);
  }
}

async function start() {
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Asilia API running on port ${PORT}`);
  });

  await bootstrap();
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
