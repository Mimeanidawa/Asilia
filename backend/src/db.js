import pg from 'pg';

const { Pool } = pg;

let pool = null;

export function getPool() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is not set');
    }
    pool = new Pool({
      connectionString,
      ssl: process.env.NODE_ENV === 'production'
        ? { rejectUnauthorized: false }
        : false,
    });
  }
  return pool;
}

export async function initDb() {
  const db = getPool();

  await db.query(`
    CREATE TABLE IF NOT EXISTS admins (
      id UUID PRIMARY KEY,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      name TEXT NOT NULL DEFAULT 'Admin',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS lessons (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      excerpt TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      image_url TEXT NOT NULL DEFAULT '',
      published_at DATE NOT NULL,
      author_name TEXT NOT NULL DEFAULT 'Mwalimu Mussa Hassan',
      read_time_minutes INTEGER NOT NULL DEFAULT 4,
      topic_tag TEXT,
      is_published BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS device_tokens (
      id UUID PRIMARY KEY,
      token TEXT UNIQUE NOT NULL,
      platform TEXT NOT NULL DEFAULT 'unknown',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS carousels (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      subtitle TEXT NOT NULL DEFAULT '',
      image_url TEXT NOT NULL DEFAULT '',
      link_section TEXT,
      link_id TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      is_published BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS content_posts (
      id TEXT PRIMARY KEY,
      section TEXT NOT NULL,
      category TEXT,
      title TEXT NOT NULL,
      subtitle TEXT NOT NULL DEFAULT '',
      excerpt TEXT NOT NULL DEFAULT '',
      content TEXT NOT NULL DEFAULT '',
      image_url TEXT NOT NULL DEFAULT '',
      is_premium BOOLEAN NOT NULL DEFAULT FALSE,
      price INTEGER NOT NULL DEFAULT 2000,
      is_published BOOLEAN NOT NULL DEFAULT FALSE,
      sort_order INTEGER NOT NULL DEFAULT 0,
      read_time_minutes INTEGER NOT NULL DEFAULT 5,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS users (
      id UUID PRIMARY KEY,
      full_name TEXT NOT NULL,
      phone TEXT,
      email TEXT UNIQUE,
      password_hash TEXT,
      auth_provider TEXT NOT NULL DEFAULT 'phone',
      is_premium BOOLEAN NOT NULL DEFAULT FALSE,
      premium_until TIMESTAMPTZ,
      message_count INTEGER NOT NULL DEFAULT 0,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS user_purchases (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      content_id TEXT NOT NULL,
      amount INTEGER NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS chat_conversations (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      status TEXT NOT NULL DEFAULT 'open',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS chat_messages (
      id UUID PRIMARY KEY,
      conversation_id UUID NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
      sender_type TEXT NOT NULL,
      content TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL,
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE INDEX IF NOT EXISTS idx_lessons_published
      ON lessons (is_published, published_at DESC);
    CREATE INDEX IF NOT EXISTS idx_content_section
      ON content_posts (section, category, is_published);
    CREATE INDEX IF NOT EXISTS idx_carousels_published
      ON carousels (is_published, sort_order);
    CREATE INDEX IF NOT EXISTS idx_chat_conv_user
      ON chat_conversations (user_id);
    CREATE INDEX IF NOT EXISTS idx_chat_msg_conv
      ON chat_messages (conversation_id, created_at);
  `);

  // Default Mwalimu (learning assistant) settings
  await db.query(`
    INSERT INTO app_settings (key, value) VALUES
      ('mwalimu_name', 'Mwalimu Mussa Hassan'),
      ('mwalimu_image', 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=200'),
      ('mwalimu_welcome', 'Karibu! Mimi ni Mwalimu wako wa elimu ya dawa za asili. Uliza kuhusu mimea, mizizi, miti na matunda — kwa elimu tu, si ushauri wa kimatibabu.'),
      ('free_message_limit', '5'),
      ('premium_price', '15000')
    ON CONFLICT (key) DO NOTHING
  `);

  console.log('Database schema ready');
}
