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

async function getFreeMessageLimit(db) {
  const { rows } = await db.query(
    "SELECT value FROM app_settings WHERE key = 'free_message_limit'",
  );
  return parseInt(rows[0]?.value || '5', 10);
}

async function getOrCreateGuestConversation(db, sessionId) {
  const { rows } = await db.query(
    'SELECT id, guest_message_count FROM chat_conversations WHERE guest_session_id = $1',
    [sessionId],
  );
  if (rows.length) return rows[0];

  const convId = uuidv4();
  await db.query(
    'INSERT INTO chat_conversations (id, guest_session_id, guest_message_count) VALUES ($1, $2, 0)',
    [convId, sessionId],
  );
  return { id: convId, guest_message_count: 0 };
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
        premiumPrice: Math.max(500, parseInt(settings.premium_price || '15000', 10) || 15000),
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
      ['premium_price', premiumPrice != null
        ? Math.max(500, parseInt(String(premiumPrice), 10) || 15000).toString()
        : undefined],
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
      `INSERT INTO chat_messages (id, conversation_id, sender_type, content, is_read_by_admin)
       VALUES ($1,$2,$3,$4,FALSE)`,
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

// Guest: get messages (no auth — keyed by device session)
router.get('/guest/messages', async (req, res) => {
  try {
    const sessionId = req.query.sessionId?.trim();
    if (!sessionId || sessionId.length < 8 || sessionId.length > 128) {
      return res.status(400).json({ error: 'sessionId si sahihi' });
    }

    const db = getPool();
    const limit = await getFreeMessageLimit(db);

    const { rows: convRows } = await db.query(
      'SELECT id, guest_message_count FROM chat_conversations WHERE guest_session_id = $1',
      [sessionId],
    );

    if (!convRows.length) {
      return res.json({ messages: [], messageCount: 0, messageLimit: limit });
    }

    const conv = convRows[0];
    const { rows: messages } = await db.query(
      `SELECT id, sender_type AS "senderType", content, created_at AS "createdAt"
       FROM chat_messages WHERE conversation_id = $1 ORDER BY created_at ASC`,
      [conv.id],
    );

    res.json({
      messages,
      messageCount: conv.guest_message_count || 0,
      messageLimit: limit,
    });
  } catch (err) {
    console.error('GET /chat/guest/messages:', err);
    res.status(500).json({ error: 'Imeshindwa kupata ujumbe' });
  }
});

// Guest: send message (no auth)
router.post('/guest/messages', async (req, res) => {
  try {
    const { content, sessionId } = req.body;
    if (!content?.trim()) return res.status(400).json({ error: 'Ujumbe unahitajika' });
    if (!sessionId?.trim() || sessionId.length < 8 || sessionId.length > 128) {
      return res.status(400).json({ error: 'sessionId si sahihi' });
    }

    const db = getPool();
    const limit = await getFreeMessageLimit(db);
    const conv = await getOrCreateGuestConversation(db, sessionId.trim());

    if ((conv.guest_message_count || 0) >= limit) {
      return res.status(403).json({
        error: 'Umefikia kikomo cha maswali. Jisajili ili uendelee.',
        limitReached: true,
      });
    }

    const msgId = uuidv4();
    await db.query(
      `INSERT INTO chat_messages (id, conversation_id, sender_type, content, is_read_by_admin)
       VALUES ($1,$2,$3,$4,FALSE)`,
      [msgId, conv.id, 'user', content.trim()],
    );

    const { rows: updated } = await db.query(
      `UPDATE chat_conversations
       SET guest_message_count = guest_message_count + 1, updated_at = NOW()
       WHERE id = $1
       RETURNING guest_message_count`,
      [conv.id],
    );

    res.status(201).json({
      message: {
        id: msgId,
        senderType: 'user',
        content: content.trim(),
        createdAt: new Date().toISOString(),
      },
      messageCount: updated[0]?.guest_message_count || 0,
      messageLimit: limit,
    });
  } catch (err) {
    console.error('POST /chat/guest/messages:', err);
    res.status(500).json({ error: 'Imeshindwa kutuma ujumbe' });
  }
});

// Guest: link session to registered user after signup/login
router.post('/guest/link', requireUser, async (req, res) => {
  try {
    const sessionId = req.body.sessionId?.trim();
    if (!sessionId) return res.json({ ok: true });

    const db = getPool();
    const userId = req.user.sub;

    const { rows: guestRows } = await db.query(
      'SELECT id, guest_message_count FROM chat_conversations WHERE guest_session_id = $1',
      [sessionId],
    );
    if (!guestRows.length) return res.json({ ok: true });

    const guestConv = guestRows[0];
    const userConvId = await getOrCreateConversation(db, userId);

    if (guestConv.id !== userConvId) {
      await db.query(
        'UPDATE chat_messages SET conversation_id = $1 WHERE conversation_id = $2',
        [userConvId, guestConv.id],
      );

      if (guestConv.guest_message_count > 0) {
        await db.query(
          `UPDATE users SET message_count = message_count + $1, updated_at = NOW() WHERE id = $2`,
          [guestConv.guest_message_count, userId],
        );
      }

      await db.query('DELETE FROM chat_conversations WHERE id = $1', [guestConv.id]);
      await db.query(
        'UPDATE chat_conversations SET updated_at = NOW() WHERE id = $1',
        [userConvId],
      );
    }

    res.json({ ok: true });
  } catch (err) {
    console.error('POST /chat/guest/link:', err);
    res.status(500).json({ error: 'Imeshindwa kuunganisha akaunti' });
  }
});

// Admin: list conversations
router.get('/admin/conversations', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(`
      SELECT c.id, c.user_id, c.guest_session_id, c.status, c.updated_at,
             u.full_name, u.phone, u.email, u.is_premium, u.message_count,
             c.guest_message_count,
             (SELECT content FROM chat_messages WHERE conversation_id = c.id
              ORDER BY created_at DESC LIMIT 1) AS last_message,
             (SELECT sender_type FROM chat_messages WHERE conversation_id = c.id
              ORDER BY created_at DESC LIMIT 1) AS last_sender_type,
             (SELECT COUNT(*)::int FROM chat_messages
              WHERE conversation_id = c.id
                AND sender_type = 'user'
                AND is_read_by_admin = FALSE) AS unread_count
      FROM chat_conversations c
      LEFT JOIN users u ON u.id = c.user_id
      WHERE EXISTS (
        SELECT 1 FROM chat_messages m WHERE m.conversation_id = c.id
      )
      ORDER BY
        CASE WHEN (
          SELECT COUNT(*) FROM chat_messages
          WHERE conversation_id = c.id
            AND sender_type = 'user'
            AND is_read_by_admin = FALSE
        ) > 0 THEN 0 ELSE 1 END,
        c.updated_at DESC
    `);
    res.json({
      conversations: rows.map((r) => ({
        id: r.id,
        userId: r.user_id,
        guestSessionId: r.guest_session_id,
        isGuest: !r.user_id,
        status: r.status,
        updatedAt: r.updated_at,
        userName: r.full_name || (r.guest_session_id ? 'Mgeni' : 'Mtumiaji'),
        userPhone: r.phone,
        userEmail: r.email,
        isPremium: r.is_premium ?? false,
        messageCount: r.user_id ? r.message_count : r.guest_message_count,
        lastMessage: r.last_message,
        lastSenderType: r.last_sender_type,
        unreadCount: r.unread_count || 0,
        hasUnread: (r.unread_count || 0) > 0,
      })),
    });
  } catch (err) {
    console.error('GET /chat/admin/conversations:', err);
    res.status(500).json({ error: 'Imeshindwa kupata mazungumzo' });
  }
});

// Admin: unread summary for nav badge
router.get('/admin/unread-summary', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(`
      SELECT
        COUNT(*) FILTER (
          WHERE m.sender_type = 'user' AND m.is_read_by_admin = FALSE
        )::int AS total_unread,
        COUNT(DISTINCT m.conversation_id) FILTER (
          WHERE m.sender_type = 'user' AND m.is_read_by_admin = FALSE
        )::int AS conversations_with_unread
      FROM chat_messages m
    `);
    const { rows: latest } = await db.query(`
      SELECT m.id, m.content, m.created_at,
             c.id AS conversation_id,
             COALESCE(u.full_name, CASE WHEN c.guest_session_id IS NOT NULL THEN 'Mgeni' ELSE 'Mtumiaji' END) AS user_name
      FROM chat_messages m
      JOIN chat_conversations c ON c.id = m.conversation_id
      LEFT JOIN users u ON u.id = c.user_id
      WHERE m.sender_type = 'user' AND m.is_read_by_admin = FALSE
      ORDER BY m.created_at DESC
      LIMIT 20
    `);
    res.json({
      totalUnread: rows[0]?.total_unread || 0,
      conversationsWithUnread: rows[0]?.conversations_with_unread || 0,
      latest: latest.map((r) => ({
        id: r.id,
        conversationId: r.conversation_id,
        userName: r.user_name,
        preview: r.content,
        createdAt: r.created_at,
      })),
    });
  } catch (err) {
    console.error('GET /chat/admin/unread-summary:', err);
    res.status(500).json({ error: 'Imeshindwa kupata muhtasari' });
  }
});

// Admin: get conversation messages
router.get('/admin/conversations/:id/messages', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT id, sender_type AS "senderType", content, created_at AS "createdAt",
              is_read_by_admin AS "isReadByAdmin"
       FROM chat_messages WHERE conversation_id = $1 ORDER BY created_at ASC`,
      [req.params.id],
    );
    res.json({ messages: rows });
  } catch (err) {
    res.status(500).json({ error: 'Imeshindwa kupata ujumbe' });
  }
});

// Admin: mark conversation messages as read
router.post('/admin/conversations/:id/read', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const { rowCount } = await db.query(
      `UPDATE chat_messages
       SET is_read_by_admin = TRUE
       WHERE conversation_id = $1
         AND sender_type = 'user'
         AND is_read_by_admin = FALSE`,
      [req.params.id],
    );
    res.json({ ok: true, marked: rowCount || 0 });
  } catch (err) {
    console.error('POST /chat/admin/conversations/:id/read:', err);
    res.status(500).json({ error: 'Imeshindwa kuweka kuwa imesomwa' });
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
      `INSERT INTO chat_messages (id, conversation_id, sender_type, content, is_read_by_admin)
       VALUES ($1,$2,$3,$4,TRUE)`,
      [msgId, req.params.id, 'admin', content.trim()],
    );

    // Opening/replying implies admin has seen the thread.
    await db.query(
      `UPDATE chat_messages
       SET is_read_by_admin = TRUE
       WHERE conversation_id = $1
         AND sender_type = 'user'
         AND is_read_by_admin = FALSE`,
      [req.params.id],
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
