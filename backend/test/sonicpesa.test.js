import test from 'node:test';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';

import {
  createSonicOrder,
  detectChannel,
  normalizeSonicStatus,
  sonicPaymentId,
  verifySonicWebhook,
} from '../src/services/sonicpesa.js';

function mockFetch() {
  const calls = [];
  global.fetch = async (url, init) => {
    calls.push({ url, init, body: JSON.parse(init.body) });
    return new Response(JSON.stringify({ status: 'success', order_id: 'SP-1' }), { status: 200 });
  };
  return calls;
}

test('create_order matches SonicPesa quickstart for every network and phone format', async () => {
  process.env.SONICPESA_ACCESS_KEY = 'test-key';
  const calls = mockFetch();

  const phones = {
    '0754123456': ['255754123456', 'MPESA'],
    '0688123456': ['255688123456', 'AIRTEL_MONEY'],
    '0788123456': ['255788123456', 'AIRTEL_MONEY'],
    '0655123456': ['255655123456', 'TIGO_PESA'],
    '0712123456': ['255712123456', 'TIGO_PESA'],
    '0621123456': ['255621123456', 'HALOPESA'],
    '+255 754 123 456': ['255754123456', 'MPESA'],
    '255788123456': ['255788123456', 'AIRTEL_MONEY'],
    '754123456': ['255754123456', 'MPESA'],
  };

  for (const [input, [expected, channel]] of Object.entries(phones)) {
    await createSonicOrder({ buyerPhone: input, amount: 50000 });
    const call = calls.at(-1);
    assert.equal(call.url, 'https://api.sonicpesa.com/api/v1/payment/create_order');
    assert.equal(call.init.method, 'POST');
    assert.equal(call.init.headers['X-API-KEY'], 'test-key');
    assert.equal(call.body.buyer_phone, expected, input);
    assert.equal(call.body.amount, 50000);
    assert.equal(call.body.currency, 'TZS');
    assert.equal(detectChannel(input), channel, input);
  }
});

test('rejects bad phones and amounts before calling SonicPesa', async () => {
  process.env.SONICPESA_ACCESS_KEY = 'test-key';
  const calls = mockFetch();
  await assert.rejects(createSonicOrder({ buyerPhone: '12', amount: 5000 }));
  await assert.rejects(createSonicOrder({ buyerPhone: '0754123456', amount: 100 }));
  assert.equal(calls.length, 0);
});

test('webhook parsing and signature', () => {
  assert.equal(sonicPaymentId({ data: { order_id: 'A' } }), 'A');
  assert.equal(normalizeSonicStatus({ payment_status: 'COMPLETED' }), 'success');
  assert.equal(normalizeSonicStatus({ data: { status: 'CANCELLED' } }), 'failed');
  assert.equal(normalizeSonicStatus({}), 'pending');

  process.env.SONICPESA_SECRET_KEY = 'secret';
  const body = Buffer.from('{"order_id":"A"}');
  const sig = crypto.createHmac('sha256', 'secret').update(body).digest('hex');
  assert.equal(verifySonicWebhook(body, sig), true);
  assert.equal(verifySonicWebhook(body, 'bad'), false);
});
