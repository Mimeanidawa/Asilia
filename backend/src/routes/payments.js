import { Router } from 'express';
import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';
import { requireUser } from '../middleware/userAuth.js';
import {
  createSonicOrder,
  getSonicOrderStatus,
  isPaymentSuccessful,
  normalizePhone,
} from '../services/sonicpesa.js';
import { fulfillPaymentOrder } from '../services/payment_fulfillment.js';

const router = Router();

async function getPremiumPrice(db) {
  const { rows } = await db.query(
    "SELECT value FROM app_settings WHERE key = 'premium_price'",
  );
  return parseInt(rows[0]?.value || '15000', 10);
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
    sonicOrderId: row.sonic_order_id,
    reference: row.reference,
    transid: row.transid,
    title: row.title,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

router.post('/initiate', requireUser, async (req, res) => {
  try {
    const { type, contentId, phone } = req.body;
    const db = getPool();
    const userId = req.user.sub;

    const user = await loadUser(db, userId);
    if (!user) return res.status(404).json({ error: 'Mtumiaji haipatikani' });

    const normalizedPhone = normalizePhone(phone || user.phone);
    if (!normalizedPhone) {
      return res.status(400).json({
        error: 'Namba ya simu si sahihi. Tumia muundo 07XXXXXXXX au 2557XXXXXXXX',
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

    const paymentId = uuidv4();
    const buyerEmail = user.email || `user-${userId}@asilia.app`;
    const buyerName = user.full_name || 'Mteja';

    const sonic = await createSonicOrder({
      buyerEmail,
      buyerName,
      buyerPhone: normalizedPhone,
      amount,
      currency: 'TZS',
    });

    const sonicOrderId = sonic.order_id
      || sonic.data?.order_id
      || sonic.transaction?.order_id
      || `sp_${Date.now()}`;

    await db.query(
      `INSERT INTO payment_orders
        (id, user_id, type, content_id, amount, currency, phone, sonic_order_id, status, title, reference)
       VALUES ($1,$2,$3,$4,$5,'TZS',$6,$7,'pending',$8,$9)`,
      [
        paymentId,
        userId,
        resolvedType,
        resolvedType === 'content' ? contentId : null,
        amount,
        normalizedPhone,
        sonicOrderId,
        title,
        `ASILIA-${paymentId.slice(0, 8)}`,
      ],
    );

    res.status(201).json({
      ok: true,
      payment: rowToPayment({
        id: paymentId,
        type: resolvedType,
        content_id: resolvedType === 'content' ? contentId : null,
        amount,
        currency: 'TZS',
        phone: normalizedPhone,
        status: 'pending',
        sonic_order_id: sonicOrderId,
        title,
        reference: `ASILIA-${paymentId.slice(0, 8)}`,
        transid: null,
        created_at: new Date(),
        updated_at: new Date(),
      }),
      message: 'Ombi la malipo limetumwa. Angalia simu yako na thibitisha.',
      sonicMessage: sonic.message,
    });
  } catch (err) {
    console.error('POST /payments/initiate:', err);
    res.status(500).json({ error: err.message || 'Imeshindwa kuanzisha malipo' });
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

    if (order.status === 'pending' && order.sonic_order_id) {
      try {
        const sonicStatus = await getSonicOrderStatus(order.sonic_order_id);
        if (isPaymentSuccessful(sonicStatus)) {
          await fulfillPaymentOrder(order);
          const { rows: updated } = await db.query(
            'SELECT * FROM payment_orders WHERE id = $1',
            [order.id],
          );
          order = updated[0] || order;
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
            order = { ...order, status: 'failed' };
          }
        }
      } catch (pollErr) {
        console.error('SonicPesa status poll:', pollErr.message);
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

router.post('/webhook', async (req, res) => {
  try {
    const payload = req.body;
    const orderId = payload?.order_id || payload?.data?.order_id;
    const paymentStatus = payload?.payment_status || payload?.data?.payment_status;

    if (!orderId) {
      return res.status(400).json({ error: 'order_id missing' });
    }

    if (!isPaymentSuccessful({ data: { payment_status: paymentStatus } })) {
      return res.json({ ok: true, ignored: true });
    }

    const db = getPool();
    const { rows } = await db.query(
      'SELECT * FROM payment_orders WHERE sonic_order_id = $1',
      [orderId],
    );
    if (!rows.length) return res.json({ ok: true, notFound: true });

    await fulfillPaymentOrder(rows[0]);
    await db.query(
      `UPDATE payment_orders SET transid = $2, updated_at = NOW() WHERE id = $1`,
      [rows[0].id, payload?.transid || payload?.data?.transid || null],
    );

    res.json({ ok: true });
  } catch (err) {
    console.error('POST /payments/webhook:', err);
    res.status(500).json({ error: 'Webhook failed' });
  }
});

export default router;
