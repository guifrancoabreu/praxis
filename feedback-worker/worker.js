const MAX_BODY = 32000;

export default {
  async fetch(request, env) {
    if (request.method !== 'POST') return new Response(null, { status: 405, headers: { Allow: 'POST' } });
    if (!env.RESEND_API_KEY || !env.FEEDBACK_FROM_EMAIL || !env.FEEDBACK_RATE_LIMITER) return new Response(null, { status: 503 });
    const ip = request.headers.get('CF-Connecting-IP');
    if (!ip || !(await env.FEEDBACK_RATE_LIMITER.limit({ key: ip })).success) return new Response(null, { status: 429 });
    if (!request.headers.get('content-type')?.toLowerCase().startsWith('application/json')) return new Response(null, { status: 415 });
    if (Number(request.headers.get('content-length')) > MAX_BODY) return new Response(null, { status: 413 });
    let input;
    try {
      const reader = request.body?.getReader();
      if (!reader) return new Response(null, { status: 400 });
      const chunks = [];
      let size = 0;
      while (true) {
        const { done, value } = await reader.read();
        if (done) break;
        size += value.byteLength;
        if (size > MAX_BODY) { await reader.cancel(); return new Response(null, { status: 413 }); }
        chunks.push(value);
      }
      const bytes = new Uint8Array(size);
      let offset = 0;
      for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.byteLength; }
      input = JSON.parse(new TextDecoder().decode(bytes));
    } catch { return new Response(null, { status: 400 }); }
    if (!input || !['bug', 'suggestion'].includes(input.type) || typeof input.details !== 'string' || typeof input.email !== 'string') return new Response(null, { status: 400 });
    const details = input.details.trim();
    const email = input.email.trim();
    if (!details || details.length > 5000 || email.length > 254 || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return new Response(null, { status: 400 });
    try {
      const response = await fetch('https://api.resend.com/emails', {
        method: 'POST',
        headers: { Authorization: `Bearer ${env.RESEND_API_KEY}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ from: env.FEEDBACK_FROM_EMAIL, to: ['support@guifran.co'], reply_to: email, subject: input.type === 'bug' ? 'Praxis: relato de bug' : 'Praxis: sugestão', text: `E-mail: ${email}\n\n${details}` }),
        signal: AbortSignal.timeout(10000),
      });
      return new Response(null, { status: response.ok ? 200 : 502 });
    } catch { return new Response(null, { status: 502 }); }
  },
};
