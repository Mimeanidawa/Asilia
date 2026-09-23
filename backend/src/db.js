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
      max: 10,
      idleTimeoutMillis: 30000,
      connectionTimeoutMillis: 10000,
    });
    pool.on('error', (err) => {
      console.error('Unexpected PG pool error:', err.message);
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

    CREATE TABLE IF NOT EXISTS admin_device_tokens (
      id UUID PRIMARY KEY,
      token TEXT UNIQUE NOT NULL,
      platform TEXT NOT NULL DEFAULT 'unknown',
      admin_id UUID REFERENCES admins(id) ON DELETE SET NULL,
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
  await db.query(`
    UPDATE app_settings
    SET value = '15000', updated_at = NOW()
    WHERE key = 'premium_price'
      AND (
        value IS NULL
        OR value !~ '^[0-9]+$'
        OR value::bigint < 500
      )
  `);

  // Default Mwalimu (learning assistant) settings
  await db.query(`
    INSERT INTO app_settings (key, value) VALUES
      ('mwalimu_name', 'Mwalimu Mussa Hassan'),
      ('mwalimu_image', 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?auto=format&fit=crop&q=80&w=200'),
      ('mwalimu_welcome', 'Karibu! Mimi ni Mwalimu wako wa elimu ya dawa za asili. Uliza kuhusu mimea, mizizi, miti na matunda — kwa elimu tu, si ushauri wa kimatibabu.'),
      ('free_message_limit', '5'),
      ('premium_price', '15000'),
      ('ads_promo_modal_enabled', 'true'),
      ('screen_message_enabled', 'false'),
      ('screen_message_id', ''),
      ('screen_message_title', ''),
      ('screen_message_body', ''),
      ('screen_message_style', 'info'),
      ('screen_message_dismissible', 'true'),
      ('force_update_enabled', 'false'),
      ('min_app_version', ''),
      ('min_app_build', '0'),
      ('update_title', 'Update Required'),
      ('update_message', 'A new version of Dawa Asili is available. Update now to continue.'),
      ('store_url', 'https://play.google.com/store/apps/details?id=com.asilia'),
      ('about_app_name', 'Dawa Asili'),
      ('about_app_version', '1.1.6'),
      ('about_app_description', 'Elimu ya dawa za asili kutoka mizizi, miti na matunda kwa Kiswahili fasaha. Tunakuletea maarifa asilia ya afya na tiba salama za kiasili.'),
      ('about_contact_phone', '+255 700 000 000'),
      ('about_contact_email', 'info@dawaasili.com'),
      ('about_website', 'https://dawaasili.co.tz'),
      ('about_disclaimer', 'Elimu na taarifa zote zilizomo humu ni kwa ajili ya kujifunza na kuelimisha tu.'),
      ('about_show_licenses', 'false')
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

  await db.query(`
    ALTER TABLE chat_messages
      ADD COLUMN IF NOT EXISTS is_read_by_admin BOOLEAN NOT NULL DEFAULT FALSE
  `);
  // Existing history should not flood the admin inbox as "unread".
  await db.query(`
    UPDATE chat_messages
    SET is_read_by_admin = TRUE
    WHERE is_read_by_admin = FALSE
      AND created_at < NOW() - INTERVAL '1 minute'
  `);
  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_chat_msg_admin_unread
      ON chat_messages (conversation_id, is_read_by_admin)
      WHERE sender_type = 'user' AND is_read_by_admin = FALSE
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS notification_history (
      id UUID PRIMARY KEY,
      title TEXT NOT NULL,
      body TEXT NOT NULL,
      target TEXT NOT NULL DEFAULT 'all',
      status TEXT NOT NULL DEFAULT 'sent',
      sent_count INTEGER NOT NULL DEFAULT 0,
      source TEXT NOT NULL DEFAULT 'broadcast',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_notification_history_created
      ON notification_history (created_at DESC)
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS media_assets (
      id UUID PRIMARY KEY,
      source_url TEXT NOT NULL UNIQUE,
      content_type TEXT NOT NULL,
      bytes BYTEA NOT NULL,
      byte_size INTEGER NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    )
  `);
  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_media_assets_updated
      ON media_assets (updated_at DESC)
  `);

  await db.query(`
    ALTER TABLE admins
      ADD COLUMN IF NOT EXISTS token_version INTEGER NOT NULL DEFAULT 0
  `);

  await db.query(`
    CREATE TABLE IF NOT EXISTS products (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      subtitle TEXT NOT NULL DEFAULT '',
      description TEXT NOT NULL DEFAULT '',
      price INTEGER NOT NULL DEFAULT 25000,
      original_price INTEGER NOT NULL DEFAULT 50000,
      discount_percent INTEGER NOT NULL DEFAULT 50,
      image_url TEXT NOT NULL DEFAULT '',
      badge_text TEXT NOT NULL DEFAULT 'PUNGUZO LA 50% 🔥',
      stock_quantity INTEGER NOT NULL DEFAULT 50,
      category TEXT NOT NULL DEFAULT 'general',
      benefits JSONB NOT NULL DEFAULT '[]'::jsonb,
      how_to_use TEXT NOT NULL DEFAULT '',
      is_published BOOLEAN NOT NULL DEFAULT TRUE,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS product_orders (
      id TEXT PRIMARY KEY,
      receipt_number TEXT UNIQUE NOT NULL,
      user_id UUID REFERENCES users(id) ON DELETE SET NULL,
      product_id TEXT NOT NULL,
      product_title TEXT NOT NULL,
      product_image_url TEXT NOT NULL DEFAULT '',
      unit_price INTEGER NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      total_amount INTEGER NOT NULL,
      customer_name TEXT NOT NULL,
      customer_phone TEXT NOT NULL,
      region TEXT NOT NULL,
      district TEXT NOT NULL,
      ward TEXT NOT NULL,
      payment_method TEXT NOT NULL DEFAULT 'M-Pesa',
      payment_status TEXT NOT NULL DEFAULT 'paid',
      delivery_status TEXT NOT NULL DEFAULT 'pending',
      tracking_info TEXT NOT NULL DEFAULT '',
      admin_notes TEXT NOT NULL DEFAULT '',
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );

    CREATE INDEX IF NOT EXISTS idx_product_orders_receipt ON product_orders (receipt_number);
    CREATE INDEX IF NOT EXISTS idx_product_orders_user ON product_orders (user_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS idx_product_orders_delivery ON product_orders (delivery_status, created_at DESC);

    INSERT INTO products (id, title, subtitle, description, price, original_price, discount_percent, image_url, badge_text, stock_quantity, category, benefits, how_to_use)
    VALUES 
    ('dawa_tumbo', 'Dawa Asili ya Vidonda vya Tumbo & Gesi', 'Mchanganyiko maalum wa Mshubiri & Mizizi ya Asili', 'Tiba madhubuti ya vidonda vya tumbo sugu (peptic ulcers), kiungulia, gesi kujaa tumboni, na kurekebisha tindikali.', 25000, 50000, 50, 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=600', 'PUNGUZO LA 50% 🔥', 45, 'tumbo', '["Huponya vidonda vya tumbo kuanzia siku 7 za mwanzo", "Huondoa kiungulia kikali na kutapika maji machungu", "Hulainisha kuta za tumbo na kusawazisha tindikali", "Inafaa kwa watoto na watu wazima (100% asilia)"]', 'Kijiko 1 cha chakula kwenye maji vuguvugu asubuhi kabla ya kula na usiku kabla ya kulala.'),
    ('dawa_kisukari', 'Mchanganyiko wa Asili wa Kudhibiti Kisukari', 'Magome na Majani ya Mwarobaini & Mlonge', 'Tiba asilia ya kusaidia kongosho kuzalisha homoni ya insulini, kusafisha damu, na kudhibiti viwango vya juu vya sukari.', 30000, 60000, 50, 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&q=80&w=600', 'PUNGUZO LA 50% 🔥', 30, 'kisukari', '["Hushusha sukari na kuweka kiwango thabiti", "Huondoa uchovu mwingi na kizunguzungu", "Hulinda macho na mafigo dhidi ya madhara ya sukari"]', 'Kikombe nusu asubuhi na jioni kwa siku 14 mfululizo.'),
    ('dawa_presha', 'Dawa ya Kusafisha Mishipa & Presha ya Juu', 'Mvuke na Dondoo ya Kitunguu Saumu & Tangawizi', 'Huongeza upenyaji wa damu, kuyeyusha mafuta mabaya (cholesterol), na kushusha shinikizo la damu kwenye mishipa ya moyo.', 28000, 56000, 50, 'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?auto=format&fit=crop&q=80&w=600', 'PUNGUZO LA 50% 🔥', 25, 'presha', '["Hushusha presha na kupunguza maumivu ya kisogo", "Huyeyusha cholesterol na kusafisha damu", "Huleta utulivu mzito wa mapigo ya moyo"]', 'Kijiko 1 asubuhi kwenye chai au maji ya vuguvugu.'),
    ('dawa_ngozi', 'Mafuta & Sabuni ya Asili ya Ngozi na Chunusi', 'Mshubiri, Mwarobaini & Manjano Safi', 'Huondoa chunusi sugu, vipele, muwasho wa ngozi, fangasi, mabaka meusi, na kurejesha ngozi kuwa nyororo na yenye mng’ao.', 20000, 40000, 50, 'https://images.unsplash.com/photo-1608248597359-598d1a100a73?auto=format&fit=crop&q=80&w=600', 'PUNGUZO LA 50% 🔥', 60, 'ngozi', '["Hukausha chunusi ndani ya masaa 48", "Huondoa madoa na makovu ya zamani", "Hutibu fangasi sugu na kuwasha kwa ngozi"]', 'Paka mara 2 kwa siku baada ya kuosha uso au eneo lililoathirika.')
    ON CONFLICT (id) DO NOTHING;
  `);

  console.log('Database schema ready');
}
