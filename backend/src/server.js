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

const app = express();
const PORT = process.env.PORT || 3001;

const corsOrigins = process.env.CORS_ORIGINS || '*';
app.use(cors({
  origin: corsOrigins === '*' ? true : corsOrigins.split(',').map((o) => o.trim()),
}));
app.use(express.json({ limit: '2mb' }));

app.get('/api/health', (_req, res) => {
  res.json({
    status: 'ok',
    service: 'asilia-api',
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

app.use((err, _req, res, _next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

async function start() {
  if (!process.env.JWT_SECRET) {
    console.error('JWT_SECRET environment variable is required');
    process.exit(1);
  }

  await initDb();
  await ensureDefaultAdmin();
  initFirebase();

  app.listen(PORT, () => {
    console.log(`Asilia API running on port ${PORT}`);
  });
}

start().catch((err) => {
  console.error('Failed to start server:', err);
  process.exit(1);
});
