const API_BASE = 'https://api.sonicpesa.com/api/v1';

function isMockMode() {
  return process.env.SONICPESA_MOCK === 'true' || !process.env.SONICPESA_API_KEY;
}

export function normalizePhone(raw) {
  if (!raw) return null;
  let digits = String(raw).replace(/\D/g, '');
  if (digits.startsWith('0')) digits = `255${digits.slice(1)}`;
  if (digits.length === 9) digits = `255${digits}`;
  if (!digits.startsWith('255') || digits.length < 12) return null;
  return digits;
}

async function sonicRequest(path, body) {
  const apiKey = process.env.SONICPESA_API_KEY;
  if (!apiKey) {
    throw new Error('SonicPesa haijasanidiwa kwenye seva');
  }

  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-KEY': apiKey,
    },
    body: JSON.stringify(body),
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    const msg = data?.message || data?.error || `SonicPesa error (${res.status})`;
    throw new Error(msg);
  }
  return data;
}

export async function createSonicOrder({
  buyerEmail,
  buyerName,
  buyerPhone,
  amount,
  currency = 'TZS',
}) {
  if (isMockMode()) {
    return {
      status: 'success',
      message: 'Mock order created',
      order_id: `mock_sp_${Date.now()}`,
      data: { payment_status: 'PENDING', amount, currency },
      mock: true,
    };
  }

  return sonicRequest('/payment/create_order', {
    buyer_email: buyerEmail,
    buyer_name: buyerName,
    buyer_phone: buyerPhone,
    amount,
    currency,
  });
}

export async function getSonicOrderStatus(orderId) {
  if (isMockMode()) {
    const created = parseInt(orderId.split('_').pop(), 10) || Date.now();
    const elapsed = Date.now() - created;
    const paymentStatus = elapsed > 4000 ? 'SUCCESS' : 'PENDING';
    return {
      status: 'success',
      data: {
        order_id: orderId,
        payment_status: paymentStatus,
        transid: paymentStatus === 'SUCCESS' ? `MOCK${Date.now()}` : null,
        reference: `ASILIA-${created}`,
      },
      mock: true,
    };
  }

  return sonicRequest('/payment/order_status', { order_id: orderId });
}

export function isPaymentSuccessful(statusPayload) {
  const paymentStatus = (
    statusPayload?.data?.payment_status
    || statusPayload?.transaction?.status
    || statusPayload?.payment_status
    || ''
  ).toString().toUpperCase();

  return ['SUCCESS', 'COMPLETED', 'PAID', 'SUCCESSFUL'].includes(paymentStatus);
}
