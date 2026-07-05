import { v4 as uuidv4 } from 'uuid';
import { getPool } from '../db.js';

export async function fulfillPaymentOrder(orderRow) {
  const db = getPool();

  if (orderRow.status === 'success') {
    return { alreadyFulfilled: true };
  }

  if (orderRow.type === 'premium') {
    await db.query(
      `UPDATE users SET is_premium = TRUE,
       premium_until = NOW() + INTERVAL '30 days', updated_at = NOW()
       WHERE id = $1`,
      [orderRow.user_id],
    );
  } else if (orderRow.content_id) {
    const { rows: existing } = await db.query(
      'SELECT id FROM user_purchases WHERE user_id = $1 AND content_id = $2',
      [orderRow.user_id, orderRow.content_id],
    );
    if (!existing.length) {
      await db.query(
        'INSERT INTO user_purchases (id, user_id, content_id, amount) VALUES ($1,$2,$3,$4)',
        [uuidv4(), orderRow.user_id, orderRow.content_id, orderRow.amount],
      );
    }
  }

  await db.query(
    `UPDATE payment_orders SET status = 'success', updated_at = NOW() WHERE id = $1`,
    [orderRow.id],
  );

  return { fulfilled: true };
}
