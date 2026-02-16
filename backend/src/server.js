import 'dotenv/config';
import express from 'express';
import cors from 'cors';

const app = express();
const port = Number(process.env.PORT || 8787);

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'pitboy-backend' });
});

app.post('/api/watch-chat', async (req, res) => {
  try {
    const requiredApiKey = process.env.PITBOY_API_KEY?.trim();
    if (requiredApiKey) {
      const supplied = req.header('x-api-key')?.trim();
      if (!supplied || supplied !== requiredApiKey) {
        return res.status(401).json({ error: 'Unauthorized' });
      }
    }

    const text = String(req.body?.text || '').trim();
    const source = String(req.body?.source || 'pitboy-watch').trim();

    if (!text) {
      return res.status(400).json({ error: 'Missing text' });
    }

    const reply = await generateReply({ text, source });
    return res.json({ reply });
  } catch (error) {
    console.error('[watch-chat] error', error);
    return res.status(500).json({ error: 'Server error' });
  }
});

app.listen(port, () => {
  console.log(`PitBoy backend listening on http://localhost:${port}`);
});

async function generateReply({ text, source }) {
  const provider = (process.env.CHAT_PROVIDER || 'echo').toLowerCase();

  if (provider === 'openai') {
    return chatWithOpenAI({ text, source });
  }

  if (provider === 'openclaw') {
    return chatWithOpenClaw({ text, source });
  }

  return `ECHO: ${text}`;
}

async function chatWithOpenAI({ text }) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new Error('OPENAI_API_KEY missing');

  const model = process.env.OPENAI_MODEL || 'gpt-4o-mini';
  const systemPrompt = process.env.SYSTEM_PROMPT || 'You are Jarvis, concise and practical.';

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model,
      messages: [
        { role: 'system', content: systemPrompt },
        { role: 'user', content: text }
      ],
      temperature: 0.4
    })
  });

  if (!response.ok) {
    const msg = await response.text();
    throw new Error(`OpenAI error: ${response.status} ${msg}`);
  }

  const data = await response.json();
  return data?.choices?.[0]?.message?.content?.trim() || 'No response';
}

async function chatWithOpenClaw({ text, source }) {
  const url = process.env.OPENCLAW_CHAT_URL;
  if (!url) throw new Error('OPENCLAW_CHAT_URL missing');

  const token = process.env.OPENCLAW_BEARER_TOKEN?.trim();

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      ...(token ? { Authorization: `Bearer ${token}` } : {})
    },
    body: JSON.stringify({
      text,
      source,
      channel: 'pitboy-watch'
    })
  });

  if (!response.ok) {
    const msg = await response.text();
    throw new Error(`OpenClaw upstream error: ${response.status} ${msg}`);
  }

  const contentType = response.headers.get('content-type') || '';

  if (contentType.includes('application/json')) {
    const data = await response.json();
    if (typeof data.reply === 'string') return data.reply;
    if (typeof data.message === 'string') return data.message;
    if (typeof data.text === 'string') return data.text;
    return JSON.stringify(data);
  }

  const textBody = await response.text();
  return textBody || 'No response';
}
