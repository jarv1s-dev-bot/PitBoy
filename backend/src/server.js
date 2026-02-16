import 'dotenv/config';
import express from 'express';
import cors from 'cors';

const app = express();
const port = Number(process.env.PORT || 8787);

app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.get('/health', (_req, res) => {
  res.json({ ok: true, service: 'pitboy-backend' });
});

app.post('/api/watch-chat', async (req, res) => {
  try {
    if (!isAuthorized(req)) {
      return res.status(401).json({ error: 'Unauthorized' });
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

app.post('/api/watch-tts', async (req, res) => {
  try {
    if (!isAuthorized(req)) {
      return res.status(401).json({ error: 'Unauthorized' });
    }

    const text = String(req.body?.text || '').trim();
    if (!text) {
      return res.status(400).json({ error: 'Missing text' });
    }

    const { audioBuffer, mimeType } = await synthesizeSpeech(text);
    const audioBase64 = audioBuffer.toString('base64');

    return res.json({
      audioBase64,
      mimeType
    });
  } catch (error) {
    console.error('[watch-tts] error', error);
    return res.status(500).json({ error: 'TTS error' });
  }
});

app.listen(port, () => {
  console.log(`PitBoy backend listening on http://localhost:${port}`);
});

function isAuthorized(req) {
  const requiredApiKey = process.env.PITBOY_API_KEY?.trim();
  if (!requiredApiKey) return true;
  const supplied = req.header('x-api-key')?.trim();
  return supplied && supplied === requiredApiKey;
}

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
  const systemPrompt = process.env.SYSTEM_PROMPT || "You are Jarvis, Eddie's sharp technical copilot. Sound calm, confident, and practical. Keep replies concise (1-4 sentences by default), avoid fluff, and prefer clear recommendations. For spoken responses, use natural punctuation and no markdown tables or code fences unless explicitly requested.";

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

async function synthesizeSpeech(text) {
  const ttsProvider = (process.env.TTS_PROVIDER || 'openai').toLowerCase();

  if (ttsProvider === 'openai') {
    return ttsWithOpenAI(text);
  }

  throw new Error(`Unsupported TTS_PROVIDER: ${ttsProvider}`);
}

async function ttsWithOpenAI(text) {
  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey) throw new Error('OPENAI_API_KEY missing for TTS');

  const model = process.env.OPENAI_TTS_MODEL || 'gpt-4o-mini-tts';
  const voice = process.env.OPENAI_TTS_VOICE || 'alloy';
  const format = process.env.OPENAI_TTS_FORMAT || 'mp3';

  const response = await fetch('https://api.openai.com/v1/audio/speech', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`
    },
    body: JSON.stringify({
      model,
      voice,
      input: text,
      response_format: format
    })
  });

  if (!response.ok) {
    const msg = await response.text();
    throw new Error(`OpenAI TTS error: ${response.status} ${msg}`);
  }

  const ab = await response.arrayBuffer();
  const audioBuffer = Buffer.from(ab);
  const mimeType = format === 'wav' ? 'audio/wav' : 'audio/mpeg';

  return { audioBuffer, mimeType };
}
