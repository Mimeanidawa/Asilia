import { Router } from 'express';
import { getPool } from '../db.js';
import { optionalUser } from '../middleware/userAuth.js';
import {
  SONIC_MIN_AMOUNT,
  createSonicOrder,
  getSonicOrderStatus,
  normalizeSonicStatus,
  sonicPaymentId,
  sonicTransactionId,
  toLocalPhone,
  normalizePhone,
} from '../services/sonicpesa.js';

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
    paymentReference: r.payment_reference || '',
    payment_reference: r.payment_reference || '',
    providerOrderId: r.provider_order_id || '',
    provider_order_id: r.provider_order_id || '',
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
    const userId = req.user?.id || req.body.userId || null;
    const now = new Date();
    const orderId = id || `ORD-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const recNum = receiptNumber || `ASILIA-RC-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}-${Math.floor(1000 + Math.random() * 9000)}`;
    const parsedTransferFee = transferFee != null ? parseInt(transferFee, 10) : 12000;
    const finalTransferFee = isNaN(parsedTransferFee) ? 12000 : parsedTransferFee;
    const calcTotal = totalAmount || ((unitPrice * quantity) + finalTransferFee);
    const initialPaymentStatus = (req.body.paymentStatus === 'paid' || req.body.payment_status === 'paid')
      ? 'paid'
      : 'pending';
    const initialTracking = initialPaymentStatus === 'paid'
      ? 'Agizo lako limethibitishwa na malipo yamepokelewa kikamilifu.'
      : 'Inasubiri uthibitisho wa malipo.';

    const query = `
      INSERT INTO product_orders (
        id, receipt_number, user_id, product_id, product_title, product_image_url,
        unit_price, quantity, transfer_fee, total_amount, customer_name, customer_phone,
        region, district, ward, payment_method, payment_status, delivery_status,
        tracking_info, admin_notes, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, 'pending', $18, '', NOW(), NOW()
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
      initialPaymentStatus,
      initialTracking,
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
        [userId],
      );
      rows = result.rows;
    } else if (phone) {
      const result = await db.query(
        `SELECT * FROM product_orders WHERE customer_phone = $1 ORDER BY created_at DESC`,
        [phone],
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
      [req.params.receiptNumber],
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

// POST /api/orders/initiate-payment - send real mobile money STK push
router.post('/initiate-payment', optionalUser, async (req, res) => {
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
      return res.status(400).json({ error: 'Tafadhali jaza taarifa zote zinazohitajika' });
    }

    const localPhone = toLocalPhone(customerPhone);
    if (!localPhone || !normalizePhone(customerPhone)) {
      return res.status(400).json({
        error: 'Namba ya simu si sahihi. Tafadhali tumia namba ya Tanzania kama 07XXXXXXXX au 06XXXXXXXX',
      });
    }

    const db = getPool();
    const now = new Date();
    const orderId = id || `ORD-${Date.now()}-${Math.floor(1000 + Math.random() * 9000)}`;
    const recNum = receiptNumber || `ASILIA-RC-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}-${Math.floor(1000 + Math.random() * 9000)}`;
    const parsedTransferFee = transferFee != null ? parseInt(transferFee, 10) : 12000;
    const finalTransferFee = isNaN(parsedTransferFee) ? 12000 : parsedTransferFee;
    const calcTotal = totalAmount || ((unitPrice * quantity) + finalTransferFee);
    const userId = req.user?.id || req.body.userId || null;

    // Ensure amount meets minimum
    const chargeAmount = Math.max(calcTotal, SONIC_MIN_AMOUNT);

    const query = `
      INSERT INTO product_orders (
        id, receipt_number, user_id, product_id, product_title, product_image_url,
        unit_price, quantity, transfer_fee, total_amount, customer_name, customer_phone,
        region, district, ward, payment_method, payment_status, delivery_status,
        tracking_info, admin_notes, provider, created_at, updated_at
      ) VALUES (
        $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, 'pending', 'pending',
        'Inasubiri uthibitisho wa malipo kwenye simu ya mteja.', '', 'sonicpesa', NOW(), NOW()
      )
      ON CONFLICT (id) DO UPDATE SET
        customer_phone = EXCLUDED.customer_phone,
        region = EXCLUDED.region,
        district = EXCLUDED.district,
        ward = EXCLUDED.ward,
        payment_status = 'pending',
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
      unitPrice || (chargeAmount - finalTransferFee),
      quantity,
      finalTransferFee,
      chargeAmount,
      customerName || 'Mteja',
      localPhone,
      region,
      district || '',
      ward || '',
      paymentMethod,
    ]);

    let providerOrderId = null;
    let paymentMessage = `Ombi la malipo limetumwa kwenye namba yako ${localPhone}. Tafadhali angalia simu yako na uweke PIN.`;

    if (process.env.SONICPESA_ACCESS_KEY) {
      try {
        const sonic = await createSonicOrder({
          amount: chargeAmount,
          buyerPhone: localPhone,
          buyerName: customerName || 'Mteja',
          buyerEmail: `${localPhone}@asilia.app`,
          currency: 'TZS',
        });

        providerOrderId = sonicPaymentId(sonic) || sonic?.order_id || sonic?.data?.order_id;
        if (sonic.message) paymentMessage = sonic.message;

        if (providerOrderId) {
          await db.query(
            `UPDATE product_orders SET provider_order_id = $2, updated_at = NOW() WHERE id = $1`,
            [orderId, providerOrderId],
          );
        }
      } catch (err) {
        console.error('SonicPesa error:', err);
        return res.status(400).json({
          error: err.message || 'Imeshindwa kutuma ombi la malipo kwenye simu yako. Tafadhali hakikisha namba yako ina salio kisha jaribu tena.',
        });
      }
    } else {
      console.warn('SONICPESA_ACCESS_KEY not set in environment. Running in dev mock mode.');
      providerOrderId = `mock-${orderId}`;
      await db.query(
        `UPDATE product_orders SET provider_order_id = $2, updated_at = NOW() WHERE id = $1`,
        [orderId, providerOrderId],
      );
    }

    const { rows: freshRows } = await db.query(`SELECT * FROM product_orders WHERE id = $1`, [orderId]);
    const order = mapOrderRow(freshRows[0] || rows[0]);

    res.status(201).json({
      success: true,
      order,
      providerOrderId,
      message: paymentMessage,
    });
  } catch (error) {
    console.error('Error initiating order payment:', error);
    res.status(500).json({ error: 'Hitilafu imetokea wakati wa kutuma ombi la malipo' });
  }
});

// GET /api/orders/:id/payment-status - check live mobile money payment status
router.get('/:id/payment-status', async (req, res) => {
  try {
    const db = getPool();
    const { id } = req.params;

    const { rows } = await db.query(
      `SELECT * FROM product_orders WHERE id = $1 OR receipt_number = $1`,
      [id],
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Agizo halikupatikana' });
    }

    const order = rows[0];

    if (order.payment_status === 'paid') {
      return res.json({
        success: true,
        status: 'paid',
        order: mapOrderRow(order),
      });
    }

    if (
      order.provider_order_id
      && !order.provider_order_id.startsWith('mock-')
      && process.env.SONICPESA_ACCESS_KEY
    ) {
      try {
        const sonicData = await getSonicOrderStatus(order.provider_order_id);
        const normStatus = normalizeSonicStatus(sonicData);

        if (normStatus === 'success') {
          const transId = sonicTransactionId(sonicData) || order.provider_order_id;
          const { rows: updated } = await db.query(
            `UPDATE product_orders
             SET payment_status = 'paid',
                 payment_reference = $2,
                 tracking_info = 'Agizo lako limethibitishwa na malipo yamepokelewa kikamilifu.',
                 updated_at = NOW()
             WHERE id = $1 RETURNING *`,
            [order.id, transId],
          );
          return res.json({
            success: true,
            status: 'paid',
            order: mapOrderRow(updated[0]),
          });
        } else if (normStatus === 'failed') {
          await db.query(
            `UPDATE product_orders
             SET payment_status = 'pending',
                 tracking_info = 'Ombi la malipo lilisitishwa au PIN haikuwekwa. Risiti inasubiri malipo.',
                 updated_at = NOW()
             WHERE id = $1`,
            [order.id],
          );
          return res.json({
            success: false,
            status: 'pending',
            message: 'Malipo hayakukamilika (yalisitishwa au PIN haikuwekwa). Risiti inasubiri malipo.',
            order: mapOrderRow({
              ...order,
              payment_status: 'pending',
              tracking_info: 'Ombi la malipo lilisitishwa au PIN haikuwekwa. Risiti inasubiri malipo.',
            }),
          });
        }
      } catch (checkErr) {
        console.warn('Could not query SonicPesa status directly:', checkErr.message);
      }
    }

    // Unpaid orders remain pending until user completes payment.
    res.json({
      success: true,
      status: order.payment_status || 'pending',
      order: mapOrderRow(order),
      message: 'Inasubiri kuweka PIN kwenye simu yako...',
    });
  } catch (error) {
    console.error('Error checking payment status:', error);
    res.status(500).json({ error: 'Hitilafu ya kuangalia hali ya malipo' });
  }
});

// POST /api/orders/:id/confirm-payment - mark payment verified
router.post('/:id/confirm-payment', async (req, res) => {
  try {
    const db = getPool();
    const { id } = req.params;
    const { paymentReference } = req.body;

    const { rows } = await db.query(
      `UPDATE product_orders
       SET payment_status = 'paid',
           payment_reference = COALESCE($2, payment_reference, 'CONFIRMED'),
           tracking_info = 'Agizo lako limethibitishwa na malipo yamepokelewa kikamilifu.',
           updated_at = NOW()
       WHERE id = $1 OR receipt_number = $1
       RETURNING *`,
      [id, paymentReference || null],
    );

    if (rows.length === 0) {
      return res.status(404).json({ error: 'Agizo halikupatikana' });
    }

    res.json({
      success: true,
      status: 'paid',
      order: mapOrderRow(rows[0]),
    });
  } catch (error) {
    console.error('Error confirming payment:', error);
    res.status(500).json({ error: 'Hitilafu ya kuthibitisha malipo' });
  }
});

export default router;
