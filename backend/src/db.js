import pg from 'pg';

const { Pool } = pg;

let pool = null;

function useSsl(connectionString) {
  if (!connectionString) return false;
  const local =
    connectionString.includes('localhost') ||
    connectionString.includes('127.0.0.1');
  return !local;
}

export function getPool() {
  if (!pool) {
    const connectionString = process.env.DATABASE_URL;
    if (!connectionString) {
      throw new Error('DATABASE_URL is not set');
    }
    pool = new Pool({
      connectionString,
      ssl: useSsl(connectionString) ? { rejectUnauthorized: false } : false,
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
      user_id UUID REFERENCES users(id) ON DELETE SET NULL,
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
      status TEXT NOT NULL DEFAULT 'active',
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

    CREATE TABLE IF NOT EXISTS payment_orders (
      id UUID PRIMARY KEY,
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type TEXT NOT NULL,
      content_id TEXT,
      amount INTEGER NOT NULL,
      currency TEXT NOT NULL DEFAULT 'TZS',
      phone TEXT NOT NULL,
      sonic_order_id TEXT,
      status TEXT NOT NULL DEFAULT 'pending',
      title TEXT NOT NULL DEFAULT '',
      reference TEXT,
      transid TEXT,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE INDEX IF NOT EXISTS idx_payment_orders_user
      ON payment_orders (user_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_payment_orders_sonic
      ON payment_orders (sonic_order_id);
  `);

  // Provider-neutral payment identifiers (retain SonicPesa columns for old orders)
  await db.query(`
    ALTER TABLE payment_orders ADD COLUMN IF NOT EXISTS provider TEXT NOT NULL DEFAULT 'sonicpesa';
    ALTER TABLE payment_orders ADD COLUMN IF NOT EXISTS provider_order_id TEXT;
    ALTER TABLE payment_orders ADD COLUMN IF NOT EXISTS provider_transaction_id TEXT;
    ALTER TABLE payment_orders ADD COLUMN IF NOT EXISTS channel TEXT;
  `);
  await db.query(`
    UPDATE payment_orders
    SET provider_order_id = sonic_order_id
    WHERE provider_order_id IS NULL AND sonic_order_id IS NOT NULL
  `);
  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_payment_orders_provider_order
      ON payment_orders (provider, provider_order_id)
  `);
  await db.query(`
    DELETE FROM user_purchases a
    USING user_purchases b
    WHERE a.user_id = b.user_id
      AND a.content_id = b.content_id
      AND (a.created_at, a.id) > (b.created_at, b.id)
  `);
  await db.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_user_purchases_user_content
      ON user_purchases (user_id, content_id)
  `);

  // Aurax Pay minimum collection amount is TZS 500
  await db.query(`
    UPDATE content_posts SET price = 500 WHERE is_premium = TRUE AND price < 500
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

  await db.query(`
    ALTER TABLE users ADD COLUMN IF NOT EXISTS status TEXT NOT NULL DEFAULT 'active'
  `);

  await db.query(`
    ALTER TABLE device_tokens ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES users(id) ON DELETE SET NULL
  `);

  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_device_tokens_user ON device_tokens (user_id)
  `);

  // Guest chat: allow conversations without a registered user
  await db.query(`
    ALTER TABLE chat_conversations ALTER COLUMN user_id DROP NOT NULL
  `);
  await db.query(`
    ALTER TABLE chat_conversations ADD COLUMN IF NOT EXISTS guest_session_id TEXT
  `);
  await db.query(`
    ALTER TABLE chat_conversations ADD COLUMN IF NOT EXISTS guest_message_count INTEGER NOT NULL DEFAULT 0
  `);
  await db.query(`
    CREATE UNIQUE INDEX IF NOT EXISTS idx_chat_conv_guest_session
      ON chat_conversations (guest_session_id)
      WHERE guest_session_id IS NOT NULL
  `);

  console.log('Database schema ready');
}
