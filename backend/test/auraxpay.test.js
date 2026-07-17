import assert from 'node:assert/strict';
import crypto from 'node:crypto';
import test from 'node:test';

import {
  createAuraxPayment,
  normalizeAuraxChannel,
  normalizeAuraxPhone,
  normalizeAuraxStatus,
  verifyAuraxWebhook,
} from '../src/services/auraxpay.js';

test('normalizes Tanzanian phone numbers and channels', () => {
  assert.equal(normalizeAuraxPhone('0712 345 678'), '+255712345678');
  assert.equal(normalizeAuraxPhone('255712345678'), '+255712345678');
  assert.equal(normalizeAuraxPhone('123'), null);
  assert.equal(normalizeAuraxChannel('mpesa'), 'MPESA');
  assert.equal(normalizeAuraxChannel('bank'), null);
});

test('maps only explicit terminal payment statuses', () => {
  assert.equal(normalizeAuraxStatus({ transaction: { status: 'SUCCESSFUL' } }), 'success');
  assert.equal(normalizeAuraxStatus({ transaction: { status: 'FAILED' } }), 'failed');
  assert.equal(normalizeAuraxStatus({ transaction: { status: 'PROCESSING' } }), 'pending');
  assert.equal(normalizeAuraxStatus({ transaction: { status: 'UNKNOWN' } }), 'pending');
});

test('creates payments using backend-only API authentication', async () => {
  const originalFetch = global.fetch;
  process.env.AURAXPAY_API_KEY = 'test-key';
  process.env.AURAXPAY_BASE_URL = 'https://api.example.test/v1';

  global.fetch = async (url, options) => {
    assert.equal(url, 'https://api.example.test/v1/payments');
    assert.equal(options.headers['x-api-key'], 'test-key');
    const body = JSON.parse(options.body);
    assert.deepEqual(body, {
      amount: 2000,
      channel: 'MPESA',
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
      buyerPhone: '+255712345678',
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

