import { test } from 'node:test';
import assert from 'node:assert/strict';
import worker from './worker.js';

const env = { RESEND_API_KEY: 'test', FEEDBACK_FROM_EMAIL: 'Praxis <test@example.com>', FEEDBACK_RATE_LIMITER: { limit: async () => ({ success: true }) } };
const request = (body) => new Request('https://example.com', { method: 'POST', headers: { 'content-type': 'application/json', 'CF-Connecting-IP': '192.0.2.1' }, body: JSON.stringify(body) });
const valid = { type: 'bug', details: 'Something broke', email: 'reader@example.com' };

test('valid feedback forwards reply-to and plain text', async () => {
  const original = globalThis.fetch;
  let payload;
  globalThis.fetch = async (_, options) => { payload = JSON.parse(options.body); return new Response(null, { status: 200 }); };
  try {
    assert.equal((await worker.fetch(request(valid), env)).status, 200);
    assert.equal(payload.reply_to, valid.email);
    assert.deepEqual(payload.to, ['support@guifran.co']);
    assert.match(payload.text, /Something broke/);
  } finally { globalThis.fetch = original; }
});
test('rejects invalid, oversized and rate-limited submissions', async () => {
  assert.equal((await worker.fetch(request({ ...valid, email: 'bad\n@example.com' }), env)).status, 400);
  assert.equal((await worker.fetch(request({ ...valid, details: 'x'.repeat(5001) }), env)).status, 400);
  assert.equal((await worker.fetch(request(valid), { ...env, FEEDBACK_RATE_LIMITER: { limit: async () => ({ success: false }) } })).status, 429);
  assert.equal((await worker.fetch(request(valid), { ...env, RESEND_API_KEY: '' })).status, 503);
});
test('reports upstream failure without exposing it', async () => {
  const original = globalThis.fetch;
  globalThis.fetch = async () => new Response('secret diagnostic', { status: 500 });
  try { const response = await worker.fetch(request(valid), env); assert.equal(response.status, 502); assert.equal(await response.text(), ''); }
  finally { globalThis.fetch = original; }
});
