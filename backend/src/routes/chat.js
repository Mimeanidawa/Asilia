import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';
import { requireUser } from '../middleware/userAuth.js';
import { requireAdmin } from '../middleware/auth.js';
import { sendMwalimuReplyNotification } from '../services/firebase.js';

const router = Router();

async function getOrCreateConversation(db, userId) {
  const { rows } = await db.query(
    'SELECT id FROM chat_conversations WHERE user_id = $1 ORDER BY updated_at DESC LIMIT 1',
    [userId],
  );
  if (rows.length) return rows[0].id;

  const convId = uuidv4();
  await db.query(
    'INSERT INTO chat_conversations (id, user_id) VALUES ($1, $2)',
    [convId, userId],
  );
  return convId;
}

router.get('/settings', async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query('SELECT key, value FROM app_settings');
    const settings = {};
    for (const r of rows) settings[r.key] = r.value;

    res.json({
      settings: {
        mwalimuName: settings.mwalimu_name || settings.mtabibu_name || 'Mwalimu Mussa Hassan',
        mwalimuImage: settings.mwalimu_image || settings.mtabibu_image || '',
        mwalimuWelcome: settings.mwalimu_welcome || settings.mtabibu_welcome ||
          'Karibu! Mimi ni Mwalimu wako wa elimu ya dawa za asili. Uliza kuhusu mimea, mizizi, miti na matunda — kwa elimu tu, si ushauri wa kimatibabu.',
        freeMessageLimit: parseInt(settings.free_message_limit || '5', 10),
        premiumPrice: parseInt(settings.premium_price || '15000', 10),
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata mipangilio' });
  }
});

router.put('/settings', requireAdmin, async (req, res) => {
  try {
    const { mwalimuName, mwalimuImage, mwalimuWelcome, freeMessageLimit, premiumPrice,
      mtabibuName, mtabibuImage, mtabibuWelcome } = req.body;
    const db = getPool();

    const updates = [
      ['mwalimu_name', mwalimuName ?? mtabibuName],
      ['mwalimu_image', mwalimuImage ?? mtabibuImage],
      ['mwalimu_welcome', mwalimuWelcome ?? mtabibuWelcome],
      ['free_message_limit', freeMessageLimit?.toString()],
      ['premium_price', premiumPrice?.toString()],
    ];

    for (const [key, value] of updates) {
      if (value != null) {
        await db.query(
          `INSERT INTO app_settings (key, value, updated_at) VALUES ($1, $2, NOW())
           ON CONFLICT (key) DO UPDATE SET value = $2, updated_at = NOW()`,
          [key, value],
        );
      }
    }

    res.json({ ok: true });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kusasisha mipangilio' });
  }
});

// User: get messages
router.get('/messages', requireUser, async (req, res) => {
  try {
    const db = getPool();
    const convId = await getOrCreateConversation(db, req.user.sub);

    const { rows: messages } = await db.query(
      `SELECT id, sender_type AS "senderType", content, created_at AS "createdAt"
       FROM chat_messages WHERE conversation_id = $1 ORDER BY created_at ASC`,
      [convId],
    );

    const { rows: users } = await db.query(
      'SELECT message_count, is_premium, premium_until FROM users WHERE id = $1',
      [req.user.sub],
    );
    const user = users[0];
    const isPremium = user?.is_premium &&
      (!user.premium_until || new Date(user.premium_until) > new Date());

    const { rows: settings } = await db.query(
      "SELECT value FROM app_settings WHERE key = 'free_message_limit'",
    );
    const limit = parseInt(settings[0]?.value || '5', 10);

    res.json({
      messages,
      messageCount: user?.message_count || 0,
      messageLimit: isPremium ? null : limit,
      isPremium,
    });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata ujumbe' });
  }
});

// User: send message
router.post('/messages', requireUser, async (req, res) => {
  try {
    const { content } = req.body;
    if (!content?.trim()) return res.status(400).json({ error: 'Ujumbe unahitajika' });

    const db = getPool();
    const userId = req.user.sub;

    const { rows: users } = await db.query(
      'SELECT message_count, is_premium, premium_until FROM users WHERE id = $1',
      [userId],
    );
    const user = users[0];
    const isPremium = user?.is_premium &&
      (!user.premium_until || new Date(user.premium_until) > new Date());

    if (!isPremium) {
      const { rows: settings } = await db.query(
        "SELECT value FROM app_settings WHERE key = 'free_message_limit'",
      );
      const limit = parseInt(settings[0]?.value || '5', 10);
      if ((user?.message_count || 0) >= limit) {
        return res.status(403).json({
          error: 'Umefikia kikomo cha ujumbe. Lipia Premium au subiri.',
          limitReached: true,
        });
      }
    }

    const convId = await getOrCreateConversation(db, userId);
    const msgId = uuidv4();

    await db.query(
      'INSERT INTO chat_messages (id, conversation_id, sender_type, content) VALUES ($1,$2,$3,$4)',
      [msgId, convId, 'user', content.trim()],
    );

    await db.query(
      `UPDATE users SET message_count = message_count + 1, updated_at = NOW() WHERE id = $1`,
      [userId],
    );

    await db.query(
      'UPDATE chat_conversations SET updated_at = NOW() WHERE id = $1',
      [convId],
    );

    res.status(201).json({
      message: {
        id: msgId,
        senderType: 'user',
        content: content.trim(),
        createdAt: new Date().toISOString(),
      },
    });
  } catch (err) {
    console.error('POST /chat/messages:', err);
    res.status(500).json({ error: 'Imeshindwa kutuma ujumbe' });
  }
});

// Admin: list conversations
router.get('/admin/conversations', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(`
      SELECT c.id, c.user_id, c.status, c.updated_at,
             u.full_name, u.phone, u.email, u.is_premium, u.message_count,
             (SELECT content FROM chat_messages WHERE conversation_id = c.id
              ORDER BY created_at DESC LIMIT 1) AS last_message
      FROM chat_conversations c
      JOIN users u ON u.id = c.user_id
      ORDER BY c.updated_at DESC
    `);
    res.json({
      conversations: rows.map((r) => ({
        id: r.id,
        userId: r.user_id,
        status: r.status,
        updatedAt: r.updated_at,
        userName: r.full_name,
        userPhone: r.phone,
        userEmail: r.email,
        isPremium: r.is_premium,
        messageCount: r.message_count,
        lastMessage: r.last_message,
      })),
    });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata mazungumzo' });
  }
});

// Admin: get conversation messages
router.get('/admin/conversations/:id/messages', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT id, sender_type AS "senderType", content, created_at AS "createdAt"
       FROM chat_messages WHERE conversation_id = $1 ORDER BY created_at ASC`,
      [req.params.id],
    );
    res.json({ messages: rows });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata ujumbe' });
  }
});

// Admin: reply
router.post('/admin/conversations/:id/reply', requireAdmin, async (req, res) => {
  try {
    const { content } = req.body;
    if (!content?.trim()) return res.status(400).json({ error: 'Ujumbe unahitajika' });

    const db = getPool();
    const msgId = uuidv4();

    await db.query(
      'INSERT INTO chat_messages (id, conversation_id, sender_type, content) VALUES ($1,$2,$3,$4)',
      [msgId, req.params.id, 'admin', content.trim()],
    );

    await db.query(
      'UPDATE chat_conversations SET updated_at = NOW() WHERE id = $1',
      [req.params.id],
    );

    const { rows: convRows } = await db.query(
      'SELECT user_id FROM chat_conversations WHERE id = $1',
      [req.params.id],
    );
    const userId = convRows[0]?.user_id;

    let notification = null;
    if (userId) {
      try {
        notification = await sendMwalimuReplyNotification({
          userId,
          preview: content.trim(),
        });
      } catch (_) {}
    }

    res.status(201).json({
      message: {
        id: msgId,
        senderType: 'admin',
        content: content.trim(),
        createdAt: new Date().toISOString(),
      },
      notification,
    });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kutuma jibu' });
  }
});

export default router;
