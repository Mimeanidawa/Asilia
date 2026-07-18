import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';
import { requireUser } from '../middleware/userAuth.js';
import {
  getSonicOrderStatus,
  isPaymentSuccessful,
} from '../services/sonicpesa.js';
import {
  AURAX_MIN_AMOUNT,
  auraxPaymentId,
  auraxTransaction,
  auraxTransactionId,
  createAuraxPayment,
  getAuraxPayment,
  normalizeAuraxPhone,
  normalizeAuraxStatus,
  resolveAuraxChannel,
  toLocalPhone,
  verifyAuraxWebhook,
} from '../services/auraxpay.js';
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

function providerAmount(payload) {
  const value = auraxTransaction(payload)?.amount;
  if (value == null) return null;
  const amount = Number(value);
  return Number.isFinite(amount) ? amount : null;
}

function providerCurrency(payload) {
  return String(auraxTransaction(payload)?.currency || '').trim().toUpperCase() || null;
}

function assertAuraxPaymentMatches(order, payload) {
  const amount = providerAmount(payload);
  const currency = providerCurrency(payload);
  if (amount != null && amount !== Number(order.amount)) {
    throw new Error('Aurax Pay amount mismatch');
  }
  if (currency && currency !== String(order.currency).toUpperCase()) {
    throw new Error('Aurax Pay currency mismatch');
  }
}

router.post('/initiate', requireUser, async (req, res) => {
  try {
    const { type, contentId, phone, channel } = req.body;
    const db = getPool();
    const userId = req.user.sub;

    const user = await loadUser(db, userId);
    if (!user) return res.status(404).json({ error: 'Mtumiaji haipatikani' });

    const inputPhone = phone || user.phone;
    const localPhone = toLocalPhone(inputPhone);
    if (!localPhone || !normalizeAuraxPhone(inputPhone)) {
      return res.status(400).json({
        error: 'Namba ya simu si sahihi. Tumia muundo 07XXXXXXXX',
      });
    }
    const normalizedChannel = resolveAuraxChannel(inputPhone, channel);
    if (!normalizedChannel) {
      return res.status(400).json({
        error: 'Chagua mtandao wa malipo: M-Pesa, Airtel Money, Mixx by Yas au HaloPesa',
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

    // Aurax rejects amounts under 500 — raise tiny catalog prices so checkout works.
    if (amount < AURAX_MIN_AMOUNT) {
      amount = AURAX_MIN_AMOUNT;
    }

    const paymentId = uuidv4();
    const buyerEmail = user.email || `user-${userId}@asilia.app`;
    const buyerName = user.full_name || 'Mteja';
    const reference = `ASILIA-${paymentId.slice(0, 8)}`;

    await db.query(
      `INSERT INTO payment_orders
        (id, user_id, type, content_id, amount, currency, phone, status, title,
         reference, provider, channel)
       VALUES ($1,$2,$3,$4,$5,'TZS',$6,'pending',$7,$8,'aurax',$9)`,
      [
        paymentId,
        userId,
        resolvedType,
        resolvedType === 'content' ? contentId : null,
        amount,
        localPhone,
        title,
        reference,
        normalizedChannel,
      ],
    );

    let aurax;
    try {
      aurax = await createAuraxPayment({
        amount,
        channel: normalizedChannel,
        buyerPhone: localPhone,
        buyerName,
        buyerEmail,
        description: title,
        metadata: {
          orderId: paymentId,
          reference,
          type: resolvedType,
          ...(contentId ? { contentId } : {}),
        },
      });
    } catch (providerError) {
      await db.query(
        `UPDATE payment_orders SET status = 'failed', updated_at = NOW() WHERE id = $1`,
        [paymentId],
      );
      throw providerError;
    }

    const providerOrderId = auraxPaymentId(aurax);
    if (!providerOrderId) {
      await db.query(
        `UPDATE payment_orders SET status = 'failed', updated_at = NOW() WHERE id = $1`,
        [paymentId],
      );
      throw new Error('Aurax Pay haikurudisha namba ya muamala');
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
        provider: 'aurax',
        provider_order_id: providerOrderId,
        channel: normalizedChannel,
        title,
        reference,
        transid: null,
        created_at: new Date(),
        updated_at: new Date(),
      }),
      message: aurax.message || 'Ombi la malipo limetumwa. Angalia simu yako na thibitisha.',
    });
  } catch (err) {
    console.error('POST /payments/initiate:', err);
    const msg = err.message || 'Imeshindwa kuanzisha malipo';
    const status = /simu|mtandao|kiasi|angalau/i.test(msg) ? 400 : 500;
    res.status(status).json({ error: msg });
  }
});

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
        if (order.provider === 'aurax') {
          const auraxStatus = await getAuraxPayment(providerOrderId);
          const normalizedStatus = normalizeAuraxStatus(auraxStatus);
          assertAuraxPaymentMatches(order, auraxStatus);
          if (normalizedStatus === 'success') {
            await fulfillPaymentOrder(order);
            await db.query(
              `UPDATE payment_orders
               SET provider_transaction_id = $2, transid = $2, updated_at = NOW()
               WHERE id = $1`,
              [order.id, auraxTransactionId(auraxStatus)],
            );
          } else if (normalizedStatus === 'failed') {
            await db.query(
              `UPDATE payment_orders SET status = 'failed', updated_at = NOW() WHERE id = $1`,
              [order.id],
            );
          }
        } else {
          // Continue supporting already-created SonicPesa orders during rollout.
          const sonicStatus = await getSonicOrderStatus(providerOrderId);
          if (isPaymentSuccessful(sonicStatus)) {
            await fulfillPaymentOrder(order);
            await db.query(
              `UPDATE payment_orders SET transid = $2, updated_at = NOW() WHERE id = $1`,
              [
                order.id,
                sonicStatus?.data?.transid || sonicStatus?.transaction?.transid || null,
              ],
            );
          } else {
            const failed = ['FAILED', 'CANCELLED', 'EXPIRED', 'REJECTED'].includes(
              (sonicStatus?.data?.payment_status || '').toUpperCase(),
            );
            if (failed) {
              await db.query(
                `UPDATE payment_orders SET status = 'failed', updated_at = NOW() WHERE id = $1`,
                [order.id],
              );
            }
          }
        }
      } catch (pollErr) {
        console.error(`${order.provider || 'sonicpesa'} status poll:`, pollErr.message);
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

router.post('/aurax/webhook', async (req, res) => {
  try {
    const signature = req.get('X-Aurax-Signature');
    if (!verifyAuraxWebhook(req.rawBody, signature)) {
      return res.status(401).json({ error: 'Invalid webhook signature' });
    }

    const payload = req.body;
    const transaction = auraxTransaction(payload);
    const providerOrderId = auraxPaymentId(payload);
    const metadataOrderId = transaction?.metadata?.orderId
      || transaction?.metadata?.order_id
      || payload?.metadata?.orderId;

    if (!providerOrderId && !metadataOrderId) {
      return res.status(400).json({ error: 'payment id missing' });
    }

    const normalizedStatus = normalizeAuraxStatus(payload);
    if (normalizedStatus === 'pending') {
      return res.json({ ok: true, ignored: true });
    }

    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM payment_orders
       WHERE provider = 'aurax'
         AND (provider_order_id = $1 OR id::text = $2)
       LIMIT 1`,
      [providerOrderId, metadataOrderId || ''],
    );
    if (!rows.length) return res.json({ ok: true, notFound: true });

    const order = rows[0];
    assertAuraxPaymentMatches(order, payload);

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
      [order.id, auraxTransactionId(payload)],
    );

    res.json({ ok: true });
  } catch (err) {
    console.error('POST /payments/aurax/webhook:', err);
    res.status(500).json({ error: 'Webhook failed' });
  }
});

export default router;
