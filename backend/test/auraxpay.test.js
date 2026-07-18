import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import test from 'node:test';

import {
  createAuraxPayment,
  detectAuraxChannel,
  normalizeAuraxChannel,
  normalizeAuraxPhone,
  normalizeAuraxStatus,
  resolveAuraxChannel,
  toLocalPhone,
  verifyAuraxWebhook,
} from '../src/services/auraxpay.js';

test('normalizes Tanzanian phones to local 0 and Aurax +255', () => {
  assert.equal(toLocalPhone('0712 345 678'), '0712345678');
  assert.equal(toLocalPhone('255712345678'), '0712345678');
  assert.equal(toLocalPhone('+255712345678'), '0712345678');
  assert.equal(normalizeAuraxPhone('0712345678'), '+255712345678');
  assert.equal(normalizeAuraxPhone('255712345678'), '+255712345678');
  assert.equal(normalizeAuraxPhone('123'), null);
});

test('detects all major Tanzanian networks from local numbers', () => {
  assert.equal(detectAuraxChannel('0744123456'), 'MPESA');
  assert.equal(detectAuraxChannel('0688123456'), 'AIRTEL_MONEY');
  assert.equal(detectAuraxChannel('0655123456'), 'TIGO_PESA');
  assert.equal(detectAuraxChannel('0712123456'), 'TIGO_PESA');
  assert.equal(detectAuraxChannel('0622123456'), 'HALOPESA');
  assert.equal(resolveAuraxChannel('0688123456', 'MPESA'), 'AIRTEL_MONEY');
  assert.equal(normalizeAuraxChannel('mpesa'), 'MPESA');
  assert.equal(normalizeAuraxChannel('bank'), null);
});

test('maps only explicit terminal payment statuses', () => {
  assert.equal(normalizeAuraxStatus({ transaction: { status: 'SUCCESSFUL' } }), 'success');
  assert.equal(normalizeAuraxStatus({ transaction: { status: 'FAILED' } }), 'failed');
  assert.equal(normalizeAuraxStatus({ transaction: { status: 'PROCESSING' } }), 'pending');
  assert.equal(normalizeAuraxStatus({ transaction: { status: 'UNKNOWN' } }), 'pending');
});

test('creates payments with +255 phone even when client sends local 0', async () => {
  const originalFetch = global.fetch;
  process.env.AURAXPAY_API_KEY = 'test-key';
  process.env.AURAXPAY_BASE_URL = 'https://api.example.test/v1';

  global.fetch = async (url, options) => {
    assert.equal(url, 'https://api.example.test/v1/payments');
    assert.equal(options.headers['x-api-key'], 'test-key');
    const body = JSON.parse(options.body);
    assert.deepEqual(body, {
      amount: 2000,
      channel: 'TIGO_PESA',
      buyerPhone: '+255712345678',
      buyerName: 'Mteja',
      buyerEmail: 'mteja@example.com',
      description: 'Makala',
      metadata: { orderId: 'local-id' },
    });
    return new Response(JSON.stringify({
      success: true,
      transaction: { id: 'aurax-id', status: 'PENDING' },
    }), { status: 201, headers: { 'Content-Type': 'application/json' } });
  };

  try {
    const result = await createAuraxPayment({
      amount: 2000,
      channel: 'MPESA',
      buyerPhone: '0712345678',
      buyerName: 'Mteja',
      buyerEmail: 'mteja@example.com',
      description: 'Makala',
      metadata: { orderId: 'local-id' },
    });
    assert.equal(result.transaction.id, 'aurax-id');
  } finally {
    global.fetch = originalFetch;
  }
});

test('verifies hex and base64 webhook signatures', () => {
  process.env.AURAXPAY_WEBHOOK_SECRET = 'webhook-test-secret';
  const body = Buffer.from('{"event":"payment.completed"}');
  const digest = crypto
    .createHmac('sha256', process.env.AURAXPAY_WEBHOOK_SECRET)
    .update(body)
    .digest();

  assert.equal(verifyAuraxWebhook(body, digest.toString('hex')), true);
  assert.equal(verifyAuraxWebhook(body, `sha256=${digest.toString('hex')}`), true);
  assert.equal(verifyAuraxWebhook(body, digest.toString('base64')), true);
  assert.equal(verifyAuraxWebhook(body, 'invalid'), false);
});
