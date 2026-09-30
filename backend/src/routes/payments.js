import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';
import { requireUser } from '../middleware/userAuth.js';
import {
  createSonicOrder,
  getSonicOrderStatus,
  isPaymentSuccessful,
  normalizeSonicStatus,
  sonicPaymentId,
  sonicTransactionId,
  toLocalPhone,
  normalizePhone,
  detectChannel,
  SONIC_MIN_AMOUNT,
  verifySonicWebhook,
} from '../services/sonicpesa.js';
import { fulfillPaymentOrder } from '../services/payment_fulfillment.js';

const router = Router();

async function getPremiumPrice(db) {
  const { rows } = await db.query(
    "SELECT value FROM app_settings WHERE key = 'premium_price'",
  );
  const parsed = parseInt(rows[0]?.value || '15000', 10);
  return Math.max(500, Number.isFinite(parsed) && parsed > 0 ? parsed : 15000);
}

async function loadUser(db, userId) {
  const { rows } = await db.query(
    'SELECT id, full_name, email, phone FROM users WHERE id = $1',
    [userId],
  );
  return rows[0] || null;
}

function rowToPayment(row) {
  return {
    id: row.id,
    type: row.type,
    contentId: row.content_id,
    amount: row.amount,
    currency: row.currency,
    phone: row.phone,
    status: row.status,
    provider: row.provider,
    providerOrderId: row.provider_order_id || row.sonic_order_id,
    channel: row.channel,
    reference: row.reference,
    transid: row.provider_transaction_id || row.transid,
    title: row.title,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

// POST /api/payments/initiate
router.post('/initiate', requireUser, async (req, res) => {
  try {
    const { type, contentId, phone, channel } = req.body;
    const db = getPool();
    const userId = req.user.sub;

    const user = await loadUser(db, userId);
    if (!user) return res.status(404).json({ error: 'Mtumiaji haipatikani' });

    const inputPhone = phone || user.phone;
    const localPhone = toLocalPhone(inputPhone);
    if (!localPhone || !normalizePhone(inputPhone)) {
      return res.status(400).json({
        error: 'Namba ya simu si sahihi. Tumia muundo 07XXXXXXXX',
      });
    }

    let amount;
    let title;
    let resolvedType = type === 'premium' ? 'premium' : 'content';

    if (resolvedType === 'premium') {
      amount = await getPremiumPrice(db);
      title = 'Premium — Dawa Asili (siku 30)';

      const { rows: premiumRows } = await db.query(
        'SELECT is_premium, premium_until FROM users WHERE id = $1',
        [userId],
      );
      const row = premiumRows[0];
      const active = row?.is_premium
        && (!row.premium_until || new Date(row.premium_until) > new Date());
      if (active) {
        return res.json({ ok: true, alreadyActive: true, type: 'premium' });
      }
    } else {
      if (!contentId) {
        return res.status(400).json({ error: 'Maudhui yanahitajika' });
      }

      const { rows: posts } = await db.query(
        'SELECT id, title, price, is_premium, is_published FROM content_posts WHERE id = $1',
        [contentId],
      );
      if (!posts.length || !posts[0].is_published) {
        return res.status(404).json({ error: 'Maudhui hayapatikani' });
      }
      if (!posts[0].is_premium) {
        return res.status(400).json({ error: 'Makala hii si ya Premium' });
      }

      const { rows: existing } = await db.query(
        'SELECT id FROM user_purchases WHERE user_id = $1 AND content_id = $2',
        [userId, contentId],
      );
      if (existing.length) {
        return res.json({ ok: true, alreadyPurchased: true, contentId });
      }

      amount = posts[0].price || 2000;
      title = posts[0].title;
    }

    // Ensure amount meets minimum
    if (amount < SONIC_MIN_AMOUNT) {
      amount = SONIC_MIN_AMOUNT;
    }

    const paymentId = uuidv4();
    const buyerEmail = user.email || `user-${userId}@asilia.app`;
    const buyerName = user.full_name || 'Mteja';
    const reference = `ASILIA-${paymentId.slice(0, 8)}`;
    const detectedChannel = detectChannel(localPhone) || channel || null;

    await db.query(
      `INSERT INTO payment_orders
        (id, user_id, type, content_id, amount, currency, phone, status, title,
         reference, provider, channel)
       VALUES ($1,$2,$3,$4,$5,'TZS',$6,'pending',$7,$8,'sonicpesa',$9)`,
      [
        paymentId,
        userId,
        resolvedType,
        resolvedType === 'content' ? contentId : null,
        amount,
        localPhone,
        title,
        reference,
        detectedChannel,
      ],
    );

    let sonic;
    try {
      sonic = await createSonicOrder({
        amount,
        buyerPhone: localPhone,
        buyerName,
        buyerEmail,
        currency: 'TZS',
      });
    } catch (providerError) {
      await db.query(
        `UPDATE payment_orders SET status = 'failed', updated_at = NOW() WHERE id = $1`,
        [paymentId],
      );
      throw providerError;
    }

    const providerOrderId = sonicPaymentId(sonic) || sonic?.order_id || sonic?.data?.order_id;
    if (!providerOrderId) {
      await db.query(
        `UPDATE payment_orders SET status = 'failed', updated_at = NOW() WHERE id = $1`,
        [paymentId],
      );
      throw new Error('SonicPesa haikurudisha namba ya muamala');
    }

    await db.query(
      `UPDATE payment_orders
       SET provider_order_id = $2, updated_at = NOW()
       WHERE id = $1`,
      [paymentId, providerOrderId],
    );

    res.status(201).json({
      ok: true,
      payment: rowToPayment({
        id: paymentId,
        type: resolvedType,
        content_id: resolvedType === 'content' ? contentId : null,
        amount,
        currency: 'TZS',
        phone: localPhone,
        status: 'pending',
        provider: 'sonicpesa',
        provider_order_id: providerOrderId,
        channel: detectedChannel,
        title,
        reference,
        transid: null,
        created_at: new Date(),
        updated_at: new Date(),
      }),
      message: sonic.message || 'Ombi la malipo limetumwa. Angalia simu yako na thibitisha.',
    });
  } catch (err) {
    console.error('POST /payments/initiate:', err);
    const msg = err.message || 'Imeshindwa kuanzisha malipo';
    const status = /simu|mtandao|kiasi|angalau/i.test(msg) ? 400 : 500;
    res.status(status).json({ error: msg });
  }
});

// GET /api/payments/:id/status
router.get('/:id/status', requireUser, async (req, res) => {
  try {
    const db = getPool();
    const userId = req.user.sub;
    const { rows } = await db.query(
      'SELECT * FROM payment_orders WHERE id = $1 AND user_id = $2',
      [req.params.id, userId],
    );
    if (!rows.length) return res.status(404).json({ error: 'Malipo hayapatikani' });

    let order = rows[0];

    const providerOrderId = order.provider_order_id || order.sonic_order_id;
    if (order.status === 'pending' && providerOrderId) {
      try {
        const sonicStatus = await getSonicOrderStatus(providerOrderId);
        const normalizedStatus = normalizeSonicStatus(sonicStatus);

        if (normalizedStatus === 'success') {
          await fulfillPaymentOrder(order);
          await db.query(
            `UPDATE payment_orders
             SET provider_transaction_id = $2, transid = $2, updated_at = NOW()
             WHERE id = $1`,
            [order.id, sonicTransactionId(sonicStatus)],
          );
        } else if (normalizedStatus === 'failed') {
          await db.query(
            `UPDATE payment_orders SET status = 'failed', updated_at = NOW() WHERE id = $1`,
            [order.id],
          );
        }
      } catch (pollErr) {
        console.error('sonicpesa status poll:', pollErr.message);
      }
    }

    const { rows: fresh } = await db.query(
      'SELECT * FROM payment_orders WHERE id = $1',
      [order.id],
    );
    order = fresh[0] || order;

    let purchasedContentIds = [];
    let userPremium = false;
    if (order.status === 'success') {
      const { rows: purchases } = await db.query(
        'SELECT content_id FROM user_purchases WHERE user_id = $1',
        [userId],
      );
      purchasedContentIds = purchases.map((p) => p.content_id);
      const { rows: users } = await db.query(
        'SELECT is_premium, premium_until FROM users WHERE id = $1',
        [userId],
      );
      const u = users[0];
      userPremium = u?.is_premium
        && (!u.premium_until || new Date(u.premium_until) > new Date());
    }

    res.json({
      ok: true,
      payment: rowToPayment(order),
      purchasedContentIds,
      isPremiumActive: userPremium,
    });
  } catch (err) {
    console.error('GET /payments/:id/status:', err);
    res.status(500).json({ error: 'Imeshindwa kuangalia hali ya malipo' });
  }
});

export async function handleSonicPesaWebhook(req, res) {
  try {
    const signature = req.get('X-Sonic-Signature')
      || req.get('X-SonicPesa-Signature')
      || req.get('X-SONIC-SIGNATURE');
    if (!verifySonicWebhook(req.rawBody, signature)) {
      return res.status(401).json({ error: 'Invalid webhook signature' });
    }

    const payload = req.body;
    const normalizedStatus = normalizeSonicStatus(payload);

    // Ignore non-terminal statuses
    if (normalizedStatus === 'pending') {
      return res.json({ ok: true, ignored: true });
    }

    const providerOrderId = sonicPaymentId(payload);
    if (!providerOrderId) {
      return res.status(400).json({ error: 'order_id missing from webhook' });
    }

    const db = getPool();

    const { rows } = await db.query(
      `SELECT * FROM payment_orders
       WHERE provider_order_id = $1 OR sonic_order_id = $1
       LIMIT 1`,
      [providerOrderId],
    );

    if (rows.length) {
      const order = rows[0];
      if (normalizedStatus === 'failed') {
        await db.query(
          `UPDATE payment_orders SET status = 'failed', updated_at = NOW() WHERE id = $1`,
          [order.id],
        );
        return res.json({ ok: true });
      }
      await fulfillPaymentOrder(order);
      await db.query(
        `UPDATE payment_orders
         SET provider_transaction_id = $2, transid = $2, updated_at = NOW()
         WHERE id = $1`,
        [order.id, sonicTransactionId(payload)],
      );
      return res.json({ ok: true });
    }

    const { rows: pRows } = await db.query(
      `SELECT * FROM product_orders
       WHERE provider_order_id = $1
       LIMIT 1`,
      [providerOrderId],
    );

    if (pRows.length) {
      const pOrder = pRows[0];
      if (normalizedStatus === 'failed') {
        await db.query(
          `UPDATE product_orders
           SET payment_status = 'pending',
               tracking_info = 'Ombi la malipo lilisitishwa au halikukamilika. Risiti inasubiri malipo.',
               updated_at = NOW()
           WHERE id = $1`,
          [pOrder.id],
        );
      } else if (normalizedStatus === 'success') {
        await db.query(
          `UPDATE product_orders
           SET payment_status = 'paid',
               payment_reference = $2,
               tracking_info = 'Agizo lako limethibitishwa na malipo yamepokelewa kikamilifu.',
               updated_at = NOW()
           WHERE id = $1`,
          [pOrder.id, sonicTransactionId(payload) || providerOrderId],
        );
      }
      return res.json({ ok: true, productOrder: true });
    }

    return res.json({ ok: true, notFound: true });
  } catch (err) {
    console.error('POST sonicpesa webhook:', err);
    res.status(500).json({ error: 'Webhook failed' });
  }
}

// Exact SonicPesa dashboard path: /api/v1/webhooks/sonicpesa
router.post('/sonicpesa', handleSonicPesaWebhook);
router.post('/sonicpesa/webhook', handleSonicPesaWebhook);

export default router;
