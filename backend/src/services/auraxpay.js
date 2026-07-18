import crypto from 'crypto';

const DEFAULT_BASE_URL = 'https://api.auraxpay.net/v1';
export const AURAX_MIN_AMOUNT = 500;

export const AURAX_CHANNELS = new Set([
  'MPESA',
  'AIRTEL_MONEY',
  'TIGO_PESA',
  'HALOPESA',
]);

/** Local 0X prefixes → Aurax channel (Tanzania MNOs). */
const PREFIX_CHANNEL = {
  '061': 'HALOPESA',
  '062': 'HALOPESA',
  '065': 'TIGO_PESA',
  '067': 'TIGO_PESA',
  '068': 'AIRTEL_MONEY',
  '069': 'AIRTEL_MONEY',
  '071': 'TIGO_PESA',
  '074': 'MPESA',
  '075': 'MPESA',
  '076': 'MPESA',
  '077': 'TIGO_PESA',
  '078': 'AIRTEL_MONEY',
  '079': 'AIRTEL_MONEY',
};

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

function formatAuraxError(data, status) {
  const details = data?.details;
  if (details && typeof details === 'object') {
    if (details.amount) {
      return `Kiasi cha malipo lazima kiwe angalau TZS ${AURAX_MIN_AMOUNT}`;
    }
    if (details.buyerPhone) {
      return 'Namba ya simu si sahihi. Tumia muundo 07XXXXXXXX';
    }
    if (details.channel) {
      return 'Mtandao wa malipo hausikiani na namba ya simu';
    }
    const flat = Object.values(details).flat().filter(Boolean);
    if (flat.length) return flat.join(', ');
  }
  return data?.error || data?.message || `Aurax Pay error (${status})`;
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
    throw new Error(formatAuraxError(data, response.status));
  }
  return data;
}

/** Digits only as 255XXXXXXXXX, or null. */
export function toTzMsisdnDigits(raw) {
  if (!raw) return null;
  let digits = String(raw).replace(/\D/g, '');
  if (digits.startsWith('0')) digits = `255${digits.slice(1)}`;
  if (digits.length === 9) digits = `255${digits}`;
  if (!/^255\d{9}$/.test(digits)) return null;
  return digits;
}

/** Local display/storage form: 07XXXXXXXX */
export function toLocalPhone(raw) {
  const digits = toTzMsisdnDigits(raw);
  if (!digits) return null;
  return `0${digits.slice(3)}`;
}

/**
 * Aurax API requires E.164 (+255…). Accepts local 0…, 255…, or +255…
 * from the app and always returns +255… for the provider.
 */
export function normalizeAuraxPhone(raw) {
  const digits = toTzMsisdnDigits(raw);
  return digits ? `+${digits}` : null;
}

export function detectAuraxChannel(rawPhone) {
  const local = toLocalPhone(rawPhone);
  if (!local || local.length < 3) return null;
  return PREFIX_CHANNEL[local.slice(0, 3)] || null;
}

export function normalizeAuraxChannel(raw) {
  const channel = String(raw || '').trim().toUpperCase();
  return AURAX_CHANNELS.has(channel) ? channel : null;
}

/**
 * Prefer channel inferred from the phone so all MNOs work even if the
 * client sends the wrong chip selection. Fall back to explicit channel.
 */
export function resolveAuraxChannel(rawPhone, explicitChannel) {
  return detectAuraxChannel(rawPhone) || normalizeAuraxChannel(explicitChannel);
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
  const phone = normalizeAuraxPhone(buyerPhone);
  if (!phone) {
    throw new Error('Namba ya simu si sahihi. Tumia muundo 07XXXXXXXX');
  }
  const resolvedChannel = resolveAuraxChannel(buyerPhone, channel);
  if (!resolvedChannel) {
    throw new Error('Chagua mtandao wa malipo: M-Pesa, Airtel Money, Mixx by Yas au HaloPesa');
  }
  const chargeAmount = Number(amount);
  if (!Number.isFinite(chargeAmount) || chargeAmount < AURAX_MIN_AMOUNT) {
    throw new Error(`Kiasi cha malipo lazima kiwe angalau TZS ${AURAX_MIN_AMOUNT}`);
  }

  return auraxRequest('/payments', {
    method: 'POST',
    body: {
      amount: chargeAmount,
      channel: resolvedChannel,
      buyerPhone: phone,
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
