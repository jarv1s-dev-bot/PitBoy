# PitBoy Backend

Simple backend for your watch app endpoint.

## Endpoints

- `POST /api/watch-chat`
- `POST /api/watch-tts`
- `GET /health`

### `/api/watch-chat` body

```json
{
  "text": "What is on my calendar tomorrow?",
  "source": "pitboy-watch"
}
```

Response:

```json
{
  "reply": "..."
}
```

### `/api/watch-tts` body

```json
{
  "text": "Hello Eddie"
}
```

Response:

```json
{
  "audioBase64": "...",
  "mimeType": "audio/mpeg"
}
```

## Quick start

```bash
cd backend
cp .env.example .env
npm install
npm run dev
```

Server starts on `http://localhost:8787` by default.

## Chat providers

Set `CHAT_PROVIDER` in `.env`:

- `echo` (default) — smoke tests
- `openai` — uses OpenAI Chat Completions API
- `openclaw` — forwards to `OPENCLAW_CHAT_URL`

## TTS provider

Set `TTS_PROVIDER=openai` and define:

- `OPENAI_API_KEY`
- `OPENAI_TTS_MODEL` (default `gpt-4o-mini-tts`)
- `OPENAI_TTS_VOICE` (default `alloy`)
- `OPENAI_TTS_FORMAT` (`mp3` or `wav`)

## Watch app config

Update `JarvisAPIClient.swift` endpoint to your backend URL, e.g.:

- Simulator: `http://127.0.0.1:8787/api/watch-chat`
- Device on LAN: `http://<your-mac-lan-ip>:8787/api/watch-chat`
- Public/tunnel: your HTTPS domain

## Optional request auth

If you set `PITBOY_API_KEY`, send this header from watch:

`x-api-key: <same key>`
