import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';

export async function fulfillPaymentOrder(orderRow) {
  const db = getPool();
  const client = await db.connect();
  try {
    await client.query('BEGIN');
    const { rows } = await client.query(
      'SELECT * FROM payment_orders WHERE id = $1 FOR UPDATE',
      [orderRow.id],
    );
    const order = rows[0];
    if (!order) throw new Error('Payment order not found');
    if (order.status === 'success') {
      await client.query('COMMIT');
      return { alreadyFulfilled: true };
    }

    if (order.type === 'premium') {
      await client.query(
        `UPDATE users SET is_premium = TRUE,
         premium_until = GREATEST(COALESCE(premium_until, NOW()), NOW()) + INTERVAL '30 days',
         updated_at = NOW()
         WHERE id = $1`,
        [order.user_id],
      );
    } else if (order.content_id) {
      await client.query(
        `INSERT INTO user_purchases (id, user_id, content_id, amount)
         VALUES ($1,$2,$3,$4)
         ON CONFLICT (user_id, content_id) DO NOTHING`,
        [uuidv4(), order.user_id, order.content_id, order.amount],
      );
    }

    await client.query(
      `UPDATE payment_orders SET status = 'success', updated_at = NOW() WHERE id = $1`,
      [order.id],
    );
    await client.query('COMMIT');
    return { fulfilled: true };
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
}
