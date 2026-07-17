import crypto from 'crypto';

const DEFAULT_BASE_URL = 'https://api.auraxpay.net/v1';

export const AURAX_CHANNELS = new Set([
  'MPESA',
  'AIRTEL_MONEY',
  'TIGO_PESA',
  'HALOPESA',
]);

function config() {
  const apiKey = process.env.AURAXPAY_API_KEY;
  if (!apiKey) {
    throw new Error('Aurax Pay haijasanidiwa kwenye seva');
  }
  return {
    apiKey,
    baseUrl: (process.env.AURAXPAY_BASE_URL || DEFAULT_BASE_URL).replace(/\/$/, ''),
  };
}

async function auraxRequest(path, { method = 'GET', body } = {}) {
  const { apiKey, baseUrl } = config();
  const response = await fetch(`${baseUrl}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  const data = await response.json().catch(() => ({}));
  if (!response.ok) {
    const details = data?.details
      ? Object.values(data.details).flat().join(', ')
      : null;
    throw new Error(details || data?.error || data?.message || `Aurax Pay error (${response.status})`);
  }
  return data;
}

export function normalizeAuraxPhone(raw) {
  if (!raw) return null;
  let digits = String(raw).replace(/\D/g, '');
  if (digits.startsWith('0')) digits = `255${digits.slice(1)}`;
  if (digits.length === 9) digits = `255${digits}`;
  if (!/^255\d{9}$/.test(digits)) return null;
  return `+${digits}`;
}

export function normalizeAuraxChannel(raw) {
  const channel = String(raw || '').trim().toUpperCase();
  return AURAX_CHANNELS.has(channel) ? channel : null;
}

export async function createAuraxPayment({
  amount,
  channel,
  buyerPhone,
  buyerName,
  buyerEmail,
  description,
  metadata,
}) {
  return auraxRequest('/payments', {
    method: 'POST',
    body: {
      amount,
      channel,
      buyerPhone,
      buyerName,
      ...(buyerEmail ? { buyerEmail } : {}),
      ...(description ? { description } : {}),
      ...(metadata ? { metadata } : {}),
    },
  });
}

export async function getAuraxPayment(paymentId) {
  return auraxRequest(`/payments/${encodeURIComponent(paymentId)}`);
}

export function auraxTransaction(payload) {
  return payload?.transaction || payload?.payment || payload?.data?.transaction
    || payload?.data?.payment || payload?.data || payload || {};
}

export function auraxPaymentId(payload) {
  const transaction = auraxTransaction(payload);
  return transaction.id || transaction.paymentId || transaction.payment_id
    || transaction.transactionId || transaction.transaction_id || null;
}

export function auraxPaymentStatus(payload) {
  const transaction = auraxTransaction(payload);
  return String(
    transaction.status || transaction.paymentStatus || transaction.payment_status || '',
  ).trim().toUpperCase();
}

export function normalizeAuraxStatus(payload) {
  const status = auraxPaymentStatus(payload);
  if (['SUCCESS', 'SUCCESSFUL', 'COMPLETED', 'PAID'].includes(status)) return 'success';
  if (['FAILED', 'CANCELLED', 'CANCELED', 'EXPIRED', 'REJECTED'].includes(status)) return 'failed';
  return 'pending';
}

export function auraxTransactionId(payload) {
  const transaction = auraxTransaction(payload);
  return transaction.transactionId || transaction.transaction_id
    || transaction.providerReference || transaction.reference || transaction.id || null;
}

export function verifyAuraxWebhook(rawBody, signature) {
  const secret = process.env.AURAXPAY_WEBHOOK_SECRET;
  if (!secret || !rawBody || !signature) return false;

  const digest = crypto.createHmac('sha256', secret).update(rawBody).digest();
  const supplied = String(signature).trim().replace(/^sha256=/i, '');
  const candidates = [digest.toString('hex'), digest.toString('base64')];

  return candidates.some((candidate) => {
    const expectedBuffer = Buffer.from(candidate);
    const suppliedBuffer = Buffer.from(supplied);
    return expectedBuffer.length === suppliedBuffer.length
      && crypto.timingSafeEqual(expectedBuffer, suppliedBuffer);
  });
}

