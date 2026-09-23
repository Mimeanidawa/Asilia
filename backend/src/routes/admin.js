import { Router } from 'express';
import { getPool } from '../db.js';
import { requireAdmin } from '../middleware/auth.js';

const router = Router();

const MONTH_LABELS = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

function pctChange(current, previous) {
  if (!previous) return current > 0 ? 100 : 0;
  return Math.round(((current - previous) / previous) * 1000) / 10;
}

function monthKey(date) {
  const d = new Date(date);
  return `${d.getUTCFullYear()}-${String(d.getUTCMonth() + 1).padStart(2, '0')}`;
}

function buildMonthlySeries(rows, valueKey = 'value') {
  const now = new Date();
  const series = [];
  for (let i = 11; i >= 0; i--) {
    const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() - i, 1));
    const key = monthKey(d);
    const match = rows.find((r) => r.month_key === key);
    series.push({
      month: MONTH_LABELS[d.getUTCMonth()],
      value: match ? Number(match[valueKey]) : 0,
    });
  }
  return series;
}

router.get('/dashboard', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();

    const { rows: userCounts } = await db.query(`
      SELECT
        COUNT(*)::int AS total,
        COUNT(*) FILTER (WHERE is_premium)::int AS premium,
        COUNT(*) FILTER (WHERE NOT is_premium)::int AS free,
        COUNT(*) FILTER (WHERE updated_at >= CURRENT_DATE)::int AS active_today,
        COUNT(*) FILTER (WHERE created_at >= date_trunc('month', NOW()))::int AS new_this_month,
        COUNT(*) FILTER (
          WHERE created_at >= date_trunc('month', NOW()) - INTERVAL '1 month'
            AND created_at < date_trunc('month', NOW())
        )::int AS new_last_month
      FROM users
    `);

    const { rows: revenueCounts } = await db.query(`
      SELECT
        COALESCE(SUM(amount), 0)::int AS total,
        COALESCE(SUM(amount) FILTER (
          WHERE created_at >= date_trunc('month', NOW())
        ), 0)::int AS monthly,
        COALESCE(SUM(amount) FILTER (
          WHERE created_at >= date_trunc('month', NOW()) - INTERVAL '1 month'
            AND created_at < date_trunc('month', NOW())
        ), 0)::int AS last_month,
        COALESCE(SUM(amount) FILTER (
          WHERE created_at >= CURRENT_DATE
        ), 0)::int AS today,
        COALESCE(SUM(amount) FILTER (
          WHERE created_at >= CURRENT_DATE - INTERVAL '1 day'
            AND created_at < CURRENT_DATE
        ), 0)::int AS yesterday
      FROM user_purchases
    `);

    const { rows: userGrowthRows } = await db.query(`
      SELECT
        to_char(date_trunc('month', created_at), 'YYYY-MM') AS month_key,
        COUNT(*)::int AS value
      FROM users
      WHERE created_at >= date_trunc('month', NOW()) - INTERVAL '11 months'
      GROUP BY 1
      ORDER BY 1
    `);

    const { rows: revenueRows } = await db.query(`
      SELECT
        to_char(date_trunc('month', created_at), 'YYYY-MM') AS month_key,
        COALESCE(SUM(amount), 0)::int AS value
      FROM user_purchases
      WHERE created_at >= date_trunc('month', NOW()) - INTERVAL '11 months'
      GROUP BY 1
      ORDER BY 1
    `);

    const { rows: premiumRows } = await db.query(`
      SELECT
        to_char(date_trunc('month', created_at), 'YYYY-MM') AS month_key,
        COUNT(*) FILTER (WHERE is_premium)::int AS value
      FROM users
      WHERE created_at >= date_trunc('month', NOW()) - INTERVAL '11 months'
      GROUP BY 1
      ORDER BY 1
    `);

    const { rows: signupActivity } = await db.query(`
      SELECT u.id, u.full_name, u.created_at
      FROM users u
      ORDER BY u.created_at DESC
      LIMIT 15
    `);

    const { rows: purchaseActivity } = await db.query(`
      SELECT p.id, p.created_at, p.amount, u.full_name
      FROM user_purchases p
      JOIN users u ON u.id = p.user_id
      ORDER BY p.created_at DESC
      LIMIT 15
    `);

    const { rows: chatActivity } = await db.query(`
      SELECT m.id, m.created_at, m.content,
             COALESCE(u.full_name,
               CASE WHEN c.guest_session_id IS NOT NULL THEN 'Mgeni' ELSE 'Mtumiaji' END
             ) AS full_name,
             c.id AS conversation_id,
             (c.user_id IS NULL) AS is_guest
      FROM chat_messages m
      JOIN chat_conversations c ON c.id = m.conversation_id
      LEFT JOIN users u ON u.id = c.user_id
      WHERE m.sender_type = 'user'
      ORDER BY m.created_at DESC
      LIMIT 15
    `);

    const total = userCounts[0].total;
    const premium = userCounts[0].premium;
    const free = userCounts[0].free;
    const monthlyRevenue = revenueCounts[0].monthly;
    const todayRevenue = revenueCounts[0].today;
    const totalRevenue = revenueCounts[0].total;
    const conversion = total > 0 ? Math.round((premium / total) * 1000) / 10 : 0;

    const activities = [
      ...signupActivity.map((r) => ({
        id: `signup-${r.id}`,
        type: 'user',
        description: 'New user registered',
        userName: r.full_name,
        timestamp: r.created_at,
      })),
      ...purchaseActivity.map((r) => ({
        id: `purchase-${r.id}`,
        type: 'premium',
        description: `Content purchase — TZS ${r.amount.toLocaleString()}`,
        userName: r.full_name,
        timestamp: r.created_at,
      })),
      ...chatActivity.map((r) => ({
        id: `chat-${r.id}`,
        type: 'mwalimu',
        description: r.is_guest
          ? 'Mgeni alituma swali kwa Mwalimu'
          : 'Aliuliza swali kwa Mwalimu',
        userName: r.full_name,
        preview: r.content,
        conversationId: r.conversation_id,
        timestamp: r.created_at,
      })),
    ]
      .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
      .slice(0, 25);

    res.json({
      stats: {
        totalUsers: total,
        premiumUsers: premium,
        freeUsers: free,
        monthlyRevenue,
        todayRevenue,
        totalRevenue,
        userGrowthRate: pctChange(userCounts[0].new_this_month, userCounts[0].new_last_month),
        revenueGrowthRate: pctChange(revenueCounts[0].monthly, revenueCounts[0].last_month),
        todayRevenueGrowthRate: pctChange(revenueCounts[0].today, revenueCounts[0].yesterday),
        premiumConversionRate: conversion,
        activeToday: userCounts[0].active_today,
        churnRate: 0,
      },
      userGrowth: buildMonthlySeries(userGrowthRows),
      revenueData: buildMonthlySeries(revenueRows),
      premiumGrowth: buildMonthlySeries(premiumRows),
      recentActivities: activities,
    });
  } catch (err) {
    console.error('GET /admin/dashboard:', err);
    res.status(500).json({ error: 'Imeshindwa kupata takwimu' });
  }
});

// ==========================================
// ADMIN PRODUCTS MANAGEMENT
// ==========================================

// GET /admin/products - list all products
router.get('/products', requireAdmin, async (_req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM products ORDER BY created_at DESC`
    );
    const products = rows.map((r) => ({
      id: r.id,
      title: r.title,
      subtitle: r.subtitle,
      description: r.description,
      price: r.price,
      originalPrice: r.original_price,
      original_price: r.original_price,
      discountPercent: r.discount_percent,
      discount_percent: r.discount_percent,
      imageUrl: r.image_url,
      image_url: r.image_url,
      badgeText: r.badge_text,
      badge_text: r.badge_text,
      stockQuantity: r.stock_quantity,
      stock_quantity: r.stock_quantity,
      category: r.category,
      benefits: Array.isArray(r.benefits) ? r.benefits : JSON.parse(r.benefits || '[]'),
      howToUse: r.how_to_use,
      how_to_use: r.how_to_use,
      isPublished: r.is_published,
      is_published: r.is_published,
      createdAt: r.created_at,
    }));
    res.json({ products });
  } catch (err) {
    console.error('GET /admin/products:', err);
    res.status(500).json({ error: 'Failed to fetch products' });
  }
});

// POST /admin/products - create new product
router.post('/products', requireAdmin, async (req, res) => {
  try {
    const {
      id,
      title,
      subtitle = '',
      description = '',
      price = 25000,
      originalPrice = 50000,
      discountPercent = 50,
      imageUrl = '',
      badgeText = 'PUNGUZO LA 50% 🔥',
      stockQuantity = 50,
      category = 'general',
      benefits = [],
      howToUse = '',
      isPublished = true,
    } = req.body;

    if (!title) {
      return res.status(400).json({ error: 'Title is required' });
    }

    const db = getPool();
    const productId = id || `dawa_${Date.now()}`;
    const benefitsJson = JSON.stringify(Array.isArray(benefits) ? benefits : []);

    const { rows } = await db.query(
      `INSERT INTO products (
        id, title, subtitle, description, price, original_price, discount_percent,
        image_url, badge_text, stock_quantity, category, benefits, how_to_use, is_published,
        created_at, updated_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12::jsonb, $13, $14, NOW(), NOW())
      RETURNING *`,
      [
        productId,
        title,
        subtitle,
        description,
        price,
        originalPrice,
        discountPercent,
        imageUrl,
        badgeText,
        stockQuantity,
        category,
        benefitsJson,
        howToUse,
        isPublished,
      ]
    );

    const r = rows[0];
    res.status(201).json({
      product: {
        id: r.id,
        title: r.title,
        subtitle: r.subtitle,
        description: r.description,
        price: r.price,
        originalPrice: r.original_price,
        discountPercent: r.discount_percent,
        imageUrl: r.image_url,
        badgeText: r.badge_text,
        stockQuantity: r.stock_quantity,
        category: r.category,
        benefits: Array.isArray(r.benefits) ? r.benefits : JSON.parse(r.benefits || '[]'),
        howToUse: r.how_to_use,
        isPublished: r.is_published,
      },
    });
  } catch (err) {
    console.error('POST /admin/products:', err);
    res.status(500).json({ error: 'Failed to create product' });
  }
});

// PUT /admin/products/:id - update product
router.put('/products/:id', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const {
      title,
      subtitle,
      description,
      price,
      originalPrice,
      discountPercent,
      imageUrl,
      badgeText,
      stockQuantity,
      category,
      benefits,
      howToUse,
      isPublished,
    } = req.body;

    const db = getPool();
    const benefitsJson = benefits !== undefined
      ? JSON.stringify(Array.isArray(benefits) ? benefits : [])
      : null;

    const { rows } = await db.query(
      `UPDATE products SET
        title = COALESCE($2, title),
        subtitle = COALESCE($3, subtitle),
        description = COALESCE($4, description),
        price = COALESCE($5, price),
        original_price = COALESCE($6, original_price),
        discount_percent = COALESCE($7, discount_percent),
        image_url = COALESCE($8, image_url),
        badge_text = COALESCE($9, badge_text),
        stock_quantity = COALESCE($10, stock_quantity),
        category = COALESCE($11, category),
        benefits = CASE WHEN $12::text IS NOT NULL THEN $12::jsonb ELSE benefits END,
        how_to_use = COALESCE($13, how_to_use),
        is_published = COALESCE($14, is_published),
        updated_at = NOW()
      WHERE id = $1
      RETURNING *`,
      [
        id,
        title,
        subtitle,
        description,
        price,
        originalPrice,
        discountPercent,
        imageUrl,
        badgeText,
        stockQuantity,
        category,
        benefitsJson,
        howToUse,
        isPublished,
      ]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Product not found' });
    }

    const r = rows[0];
    res.json({
      product: {
        id: r.id,
        title: r.title,
        subtitle: r.subtitle,
        description: r.description,
        price: r.price,
        originalPrice: r.original_price,
        discountPercent: r.discount_percent,
        imageUrl: r.image_url,
        badgeText: r.badge_text,
        stockQuantity: r.stock_quantity,
        category: r.category,
        benefits: Array.isArray(r.benefits) ? r.benefits : JSON.parse(r.benefits || '[]'),
        howToUse: r.how_to_use,
        isPublished: r.is_published,
      },
    });
  } catch (err) {
    console.error('PUT /admin/products/:id:', err);
    res.status(500).json({ error: 'Failed to update product' });
  }
});

// DELETE /admin/products/:id - delete product
router.delete('/products/:id', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    await db.query(`DELETE FROM products WHERE id = $1`, [req.params.id]);
    res.json({ success: true });
  } catch (err) {
    console.error('DELETE /admin/products/:id:', err);
    res.status(500).json({ error: 'Failed to delete product' });
  }
});

// ==========================================
// ADMIN ORDERS & RECEIPT MANAGEMENT
// ==========================================

// GET /admin/orders - list all customer orders
router.get('/orders', requireAdmin, async (req, res) => {
  try {
    const db = getPool();
    const { status } = req.query;

    let query = `SELECT * FROM product_orders`;
    const params = [];
    if (status) {
      query += ` WHERE delivery_status = $1`;
      params.push(status);
    }
    query += ` ORDER BY created_at DESC`;

    const { rows } = await db.query(query, params);
    const orders = rows.map((r) => ({
      id: r.id,
      receiptNumber: r.receipt_number,
      userId: r.user_id,
      productId: r.product_id,
      productTitle: r.product_title,
      productImageUrl: r.product_image_url,
      unitPrice: r.unit_price,
      quantity: r.quantity,
      transferFee: r.transfer_fee != null ? Number(r.transfer_fee) : 12000,
      totalAmount: r.total_amount,
      customerName: r.customer_name,
      customerPhone: r.customer_phone,
      region: r.region,
      district: r.district,
      ward: r.ward,
      paymentMethod: r.payment_method,
      paymentStatus: r.payment_status,
      deliveryStatus: r.delivery_status,
      trackingInfo: r.tracking_info,
      adminNotes: r.admin_notes,
      createdAt: r.created_at,
    }));

    res.json({ orders });
  } catch (err) {
    console.error('GET /admin/orders:', err);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// PUT /admin/orders/:id/status - update delivery status & tracking info
router.put('/orders/:id/status', requireAdmin, async (req, res) => {
  try {
    const { id } = req.params;
    const { deliveryStatus, trackingInfo, adminNotes } = req.body;

    if (!deliveryStatus) {
      return res.status(400).json({ error: 'deliveryStatus is required' });
    }

    const db = getPool();
    const { rows } = await db.query(
      `UPDATE product_orders SET
        delivery_status = $2,
        tracking_info = COALESCE($3, tracking_info),
        admin_notes = COALESCE($4, admin_notes),
        updated_at = NOW()
      WHERE id = $1
      RETURNING *`,
      [id, deliveryStatus, trackingInfo, adminNotes]
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Order not found' });
    }

    const r = rows[0];
    res.json({
      success: true,
      order: {
        id: r.id,
        receiptNumber: r.receipt_number,
        deliveryStatus: r.delivery_status,
        trackingInfo: r.tracking_info,
        adminNotes: r.admin_notes,
      },
    });
  } catch (err) {
    console.error('PUT /admin/orders/:id/status:', err);
    res.status(500).json({ error: 'Failed to update order status' });
  }
});

export default router;
