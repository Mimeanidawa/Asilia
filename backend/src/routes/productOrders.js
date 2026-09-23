import { Router } from 'express';
import { getPool } from '../db.js';
import { optionalUser } from '../middleware/userAuth.js';

const router = Router();

function mapOrderRow(r) {
  return {
    id: r.id,
    receiptNumber: r.receipt_number,
    receipt_number: r.receipt_number,
    userId: r.user_id,
    user_id: r.user_id,
    productId: r.product_id,
    product_id: r.product_id,
    productTitle: r.product_title,
    product_title: r.product_title,
    productImageUrl: r.product_image_url,
    product_image_url: r.product_image_url,
    unitPrice: r.unit_price,
    unit_price: r.unit_price,
    quantity: r.quantity,
    transferFee: r.transfer_fee != null ? Number(r.transfer_fee) : 12000,
    transfer_fee: r.transfer_fee != null ? Number(r.transfer_fee) : 12000,
    totalAmount: r.total_amount,
    total_amount: r.total_amount,
    customerName: r.customer_name,
    customer_name: r.customer_name,
    customerPhone: r.customer_phone,
    customer_phone: r.customer_phone,
    region: r.region,
    district: r.district,
    ward: r.ward,
    paymentMethod: r.payment_method,
    payment_method: r.payment_method,
    paymentStatus: r.payment_status,
    payment_status: r.payment_status,
    deliveryStatus: r.delivery_status,
    delivery_status: r.delivery_status,
    trackingInfo: r.tracking_info,
    tracking_info: r.tracking_info,
    adminNotes: r.admin_notes,
    admin_notes: r.admin_notes,
    createdAt: r.created_at,
    created_at: r.created_at,
  };
}

// POST /api/orders/create - create an order & generate permanent receipt
router.post('/create', optionalUser, async (req, res) => {
  try {
    const {
      id,
      receiptNumber,
      productId,
      productTitle,
      productImageUrl,
      unitPrice,
      quantity = 1,
      transferFee = 12000,
      totalAmount,
      customerName,
      customerPhone,
      region,
      district,
      ward,
      paymentMethod = 'M-Pesa',
    } = req.body;

    if (!productId || !customerPhone || !region) {
      return res.status(400).json({ error: 'Missing required order fields' });
    }

    const db = getPool();
    const now = new Date();
    const orderId = id || `ORD-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const recNum = receiptNumber || `ASILIA-RC-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}-${Math.floor(1000 + Math.random() * 9000)}`;
    const parsedTransferFee = transferFee != null ? parseInt(transferFee, 10) : 12000;
    const finalTransferFee = isNaN(parsedTransferFee) ? 12000 : parsedTransferFee;
    const calcTotal = totalAmount || ((unitPrice * quantity) + finalTransferFee);
    const userId = req.user?.id || req.body.userId || null;

    const query = `
      INSERT INTO product_orders (
        id, receipt_number, user_id, product_id, product_title, product_image_url,
        unit_price, quantity, transfer_fee, total_amount, customer_name, customer_phone,
        region, district, ward, payment_method, payment_status, delivery_status,
        tracking_info, admin_notes, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, 'paid', 'pending', '', '', NOW(), NOW()
      )
      ON CONFLICT (id) DO UPDATE SET
        customer_phone = EXCLUDED.customer_phone,
        region = EXCLUDED.region,
        district = EXCLUDED.district,
        ward = EXCLUDED.ward,
        updated_at = NOW()
      RETURNING *
    `;

    const { rows } = await db.query(query, [
      orderId,
      recNum,
      userId,
      productId,
      productTitle || 'Dawa ya Asili',
      productImageUrl || '',
      unitPrice || (calcTotal - finalTransferFee),
      quantity,
      finalTransferFee,
      calcTotal,
      customerName || 'Mteja',
      customerPhone,
      region,
      district || '',
      ward || '',
      paymentMethod,
    ]);

    const order = mapOrderRow(rows[0]);
    res.status(201).json({ success: true, order });
  } catch (error) {
    console.error('Error creating order:', error);
    res.status(500).json({ error: 'Failed to create order' });
  }
});

// GET /api/orders/my-orders - list customer's orders
router.get('/my-orders', optionalUser, async (req, res) => {
  try {
    const db = getPool();
    const userId = req.user?.id || req.query.userId;
    const phone = req.query.phone;

    let rows = [];
    if (userId) {
      const result = await db.query(
        `SELECT * FROM product_orders WHERE user_id = $1 ORDER BY created_at DESC`,
        [userId]
      );
      rows = result.rows;
    } else if (phone) {
      const result = await db.query(
        `SELECT * FROM product_orders WHERE customer_phone = $1 ORDER BY created_at DESC`,
        [phone]
      );
      rows = result.rows;
    } else {
      return res.json({ orders: [] });
    }

    res.json({ orders: rows.map(mapOrderRow) });
  } catch (error) {
    console.error('Error fetching my-orders:', error);
    res.status(500).json({ error: 'Failed to fetch orders' });
  }
});

// GET /api/orders/receipt/:receiptNumber - view digital receipt
router.get('/receipt/:receiptNumber', async (req, res) => {
  try {
    const db = getPool();
    const { rows } = await db.query(
      `SELECT * FROM product_orders WHERE receipt_number = $1`,
      [req.params.receiptNumber]
    );
    if (rows.length === 0) {
      return res.status(404).json({ error: 'Receipt not found' });
    }
    res.json({ receipt: mapOrderRow(rows[0]) });
  } catch (error) {
    console.error('Error fetching receipt:', error);
    res.status(500).json({ error: 'Failed to fetch receipt' });
  }
});

export default router;
