import crypto from 'crypto';

const API_BASE = 'https://api.sonicpesa.com/api/v1';

export const SONIC_MIN_AMOUNT = 500;

/** Local 0X prefixes → channel label (Tanzania MNOs). */
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

function getCredentials() {
  const accessKey = process.env.SONICPESA_ACCESS_KEY;
  if (!accessKey) {
    throw new Error('SonicPesa haijasanidiwa kwenye seva');
  }
  return { accessKey };
}

/** Normalize any TZ phone to 255XXXXXXXXX (digits only), or null. */
export function normalizePhone(raw) {
  if (!raw) return null;
  let digits = String(raw).replace(/\D/g, '');
  if (digits.startsWith('0')) digits = `255${digits.slice(1)}`;
  if (digits.length === 9) digits = `255${digits}`;
  if (!/^255\d{9}$/.test(digits)) return null;
  return digits;
}

/** Local display/storage form: 07XXXXXXXX */
export function toLocalPhone(raw) {
  const digits = normalizePhone(raw);
  if (!digits) return null;
  return `0${digits.slice(3)}`;
}

/** Detect MNO channel from phone number. */
export function detectChannel(rawPhone) {
  const local = toLocalPhone(rawPhone);
  if (!local || local.length < 3) return null;
  return PREFIX_CHANNEL[local.slice(0, 3)] || null;
}

async function sonicRequest(path, body) {
  const { accessKey } = getCredentials();

  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-API-KEY': accessKey,
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

/**
 * Create a SonicPesa STK-push order.
 * buyer_phone must be in 255XXXXXXXXX format.
 */
export async function createSonicOrder({
  buyerEmail,
  buyerName,
  buyerPhone,
  amount,
  currency = 'TZS',
}) {
  const phone = normalizePhone(buyerPhone);
  if (!phone) {
    throw new Error('Namba ya simu si sahihi. Tumia muundo 07XXXXXXXX');
  }

  const chargeAmount = Number(amount);
  if (!Number.isFinite(chargeAmount) || chargeAmount < SONIC_MIN_AMOUNT) {
    throw new Error(`Kiasi cha malipo lazima kiwe angalau TZS ${SONIC_MIN_AMOUNT}`);
  }

  return sonicRequest('/payment/create_order', {
    buyer_email: buyerEmail || `${phone}@asilia.app`,
    buyer_name: buyerName || 'Mteja',
    buyer_phone: phone,
    amount: chargeAmount,
    currency,
  });
}

export async function getSonicOrderStatus(orderId) {
  return sonicRequest('/payment/order_status', { order_id: orderId });
}

/** Extract our internal order ID from a SonicPesa webhook payload. */
export function sonicPaymentId(payload) {
  return (
    payload?.order_id
    || payload?.data?.order_id
    || payload?.transaction?.order_id
    || payload?.orderId
    || payload?.data?.orderId
    || payload?.payment_id
    || payload?.data?.payment_id
    || null
  );
}

/** Extract the provider transaction ID from a SonicPesa payload. */
export function sonicTransactionId(payload) {
  return (
    payload?.transid
    || payload?.data?.transid
    || payload?.transaction?.transid
    || payload?.reference
    || payload?.data?.reference
    || null
  );
}

/** Normalize a SonicPesa payment status to 'success' | 'failed' | 'pending'. */
export function normalizeSonicStatus(payload) {
  const raw = (
    payload?.payment_status
    || payload?.data?.payment_status
    || payload?.status
    || payload?.data?.status
    || ''
  ).toString().toUpperCase();

  if (['SUCCESS', 'COMPLETED', 'PAID', 'SUCCESSFUL'].includes(raw)) return 'success';
  if (['FAILED', 'CANCELLED', 'CANCELED', 'EXPIRED', 'REJECTED'].includes(raw)) return 'failed';
  return 'pending';
}

export function isPaymentSuccessful(statusPayload) {
  return normalizeSonicStatus(statusPayload) === 'success';
}

/**
 * Verify a SonicPesa webhook using the secret key.
 * SonicPesa signs payloads with HMAC-SHA256 using the secret key.
 * The signature is sent in the X-SONIC-SIGNATURE header.
 */
export function verifySonicWebhook(rawBody, signature) {
  const secret = process.env.SONICPESA_SECRET_KEY;
  // If no secret configured, skip verification (dev mode)
  if (!secret) return true;
  if (!rawBody || !signature) return false;

  const digest = crypto.createHmac('sha256', secret).update(rawBody).digest();
  const supplied = String(signature).trim().replace(/^sha256=/i, '');
  const candidates = [digest.toString('hex'), digest.toString('base64')];

  return candidates.some((candidate) => {
    try {
      const expectedBuffer = Buffer.from(candidate);
      const suppliedBuffer = Buffer.from(supplied);
      return (
        expectedBuffer.length === suppliedBuffer.length
        && crypto.timingSafeEqual(expectedBuffer, suppliedBuffer)
      );
    } catch {
      return false;
    }
  });
}
