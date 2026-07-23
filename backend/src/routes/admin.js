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
        ), 0)::int AS last_month
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
        totalRevenue,
        userGrowthRate: pctChange(userCounts[0].new_this_month, userCounts[0].new_last_month),
        revenueGrowthRate: pctChange(revenueCounts[0].monthly, revenueCounts[0].last_month),
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

export default router;
