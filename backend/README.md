# PitBoy Backend

Simple backend for your watch app endpoint.

## Endpoint

- `POST /api/watch-chat`
- Body:

```json
{
  "text": "What is on my calendar tomorrow?",
  "source": "pitboy-watch"
}
```

- Response:

```json
{
  "reply": "..."
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

## Providers

Set `CHAT_PROVIDER` in `.env`:

- `echo` (default) — for smoke tests
- `openai` — uses OpenAI Chat Completions API
- `openclaw` — forwards to `OPENCLAW_CHAT_URL`

## Watch app config

Update `JarvisAPIClient.swift` endpoint to your backend URL, for example:

- Local machine testing: `http://<your-mac-lan-ip>:8787/api/watch-chat`
- Tunnel/prod: your HTTPS domain

## Optional request auth

If you set `PITBOY_API_KEY` on the server, send this header from watch:

`x-api-key: <same key>`
