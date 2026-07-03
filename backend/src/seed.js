import 'dotenv/config';
import { initDb, getPool } from './db.js';

async function seed() {
  await initDb();
  const db = getPool();

  // Remove any previously seeded demo content so admin starts fresh.
  await db.query('DELETE FROM content_posts');
  await db.query('DELETE FROM carousels');
  await db.query('DELETE FROM lessons');

  console.log('Database ready — demo content cleared. Use admin to add carousels, posts, and lessons.');
  process.exit(0);
}

seed().catch((err) => {
  console.error(err);
  process.exit(1);
});
