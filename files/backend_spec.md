# backend_spec.md — token_server Detailed Backend Spec

> The user asked specifically to call out backend requirements. This document is the contract.
>
> Stack: **Node.js 20+, Express 4**. Plain JavaScript. Stored on disk in `data.json`.

---

## 1. Project setup

```bash
cd token_server
npm init -y
npm i express cors dotenv jsonwebtoken uuid
npm i -D nodemon
```

`package.json` scripts:
```json
"scripts": {
  "start": "node src/index.js",
  "dev": "nodemon src/index.js"
}
```

Node 20+ required for built-in `--watch` and modern fetch.

---

## 2. `.env.example`

```
# 100ms credentials. Get from https://dashboard.100ms.live/
HMS_APP_ACCESS_KEY=
HMS_APP_SECRET=

# Pre-created room from 100ms dashboard. Use one room for all calls in v1.
HMS_ROOM_ID=

# Optional fallback: a token copied directly from 100ms dashboard "Join with SDK".
# Used only if HMS_APP_ACCESS_KEY/SECRET are blank. Tokens expire — refresh during demo if needed.
HMS_FALLBACK_TOKEN=

# Server
PORT=8787
DATA_FILE=./data.json
```

Real `.env` is gitignored.

---

## 3. Endpoint reference

All requests / responses are JSON. All timestamps are ISO-8601 strings.

### `GET /health`
- **200** `{ "ok": true, "uptime": <seconds>, "hmsMode": "managed" | "fallback" | "none" }`

### `POST /token`
- **Body**: `{ userId: string, role: "host" | "guest", callRequestId?: string }`
- **200**: `{ token: string, hmsRoomId: string, expiresAt: <iso> }`
- **400**: missing fields
- **500**: HMS creds misconfigured AND no fallback

If `HMS_APP_ACCESS_KEY` + `HMS_APP_SECRET` are set: sign a JWT per `hms_integration.md` §8.
Else if `HMS_FALLBACK_TOKEN` is set: return that token literally.
Else: 500 with `{ error: "HMS not configured" }`.

`hmsRoomId` comes from `HMS_ROOM_ID` (or `roomMetas[callRequestId].hmsRoomId` if it was created at approval time).

### `GET /users`
- **200**: array of seeded users
- Includes seeded `tr_aarav` and `mb_dk` at boot.

### `POST /messages`
- **Body**: `{ chatId, senderId, receiverId, text }`
- **201**: full `Message` with `id` (uuid v4), `createdAt` (now), `status: "sent"`
- Fan-outs SSE event `message.created` to both sender (for status confirmation) and receiver.

### `GET /messages?chatId=...&since=<iso>`
- **200**: array of messages with `createdAt > since`, sorted asc.
- `since` is inclusive of equal — easier polling. If omitted, returns last 100.

### `POST /messages/read-batch`
- **Body**: `{ ids: string[], readerId: string }`
- **200**: `{ updatedCount: number }`
- Updates each `Message.status` to `"read"` if `receiverId === readerId`.
- Fan-outs SSE `message.read` to the original sender.

### `POST /call-requests`
- **Body**: `{ memberId, trainerId, scheduledFor: <iso>, note: string<=140 }`
- **201**: full `CallRequest` with `id`, `requestedAt`, `status: "pending"`
- **400**: if `scheduledFor` is in the past, or note > 140 chars
- **409**: if the trainer already has an `approved` request overlapping a 30-min window around `scheduledFor`
- Fan-outs `call_request.created` SSE to both users.

### `GET /call-requests?userId=...&since=<iso>`
- **200**: array of requests where `memberId === userId` OR `trainerId === userId`, sorted by `scheduledFor` asc.

### `PATCH /call-requests/:id`
- **Body**: `{ status: "approved" | "declined" | "cancelled", declineReason?: string }`
- **200**: updated request.
- On `approved`: create a `RoomMeta` (id = uuid, hmsRoomId = `HMS_ROOM_ID`, roles = `host` for trainer, `guest` for member). Also create a system `Message` in the chat: `"Call approved for {date} {time}."`.
- On `declined`: create a system `Message`: `"Call request declined. Reason: {declineReason}."`.
- Fan-outs `call_request.updated` SSE.

### `POST /session-logs`
- **Body**: `{ memberId, trainerId, callRequestId, startedAt, endedAt }`
- **201**: full `SessionLog` with computed `durationSec`.

### `PATCH /session-logs/:id`
- **Body**: `{ rating?: 1-5, memberNotes?: string, trainerNotes?: string }`
- **200**: updated log.

### `GET /session-logs?userId=...&from=<iso>&to=<iso>`
- **200**: array filtered by `memberId === userId || trainerId === userId`, optional date range.

### `GET /events?userId=...`
- **SSE stream**. `Content-Type: text/event-stream`.
- Server keeps `Map<userId, Set<Response>>` of active streams.
- On any state change for messages, call requests, session logs, room metas, server writes:
  ```
  event: <name>
  data: <json>

  ```
  where `<name>` is one of: `message.created`, `message.read`, `call_request.created`, `call_request.updated`, `session_log.created`, `session_log.updated`.
- Heartbeat: every 25s, write `: ping\n\n` to keep the connection alive through proxies.

---

## 4. Persistence (`store.js`)

```js
// src/store.js
const fs = require('fs');

const DATA_FILE = process.env.DATA_FILE || './data.json';

const initial = () => ({
  users: [
    { id: 'tr_aarav', role: 'trainer', name: 'Aarav', email: 'aarav@wtf.local', avatarUrl: null },
    { id: 'mb_dk', role: 'member', name: 'DK', email: 'dk@wtf.local', avatarUrl: null, assignedTrainerId: 'tr_aarav' },
  ],
  messages: [],
  callRequests: [],
  sessionLogs: [],
  roomMetas: [],
});

let state = initial();
try {
  if (fs.existsSync(DATA_FILE)) state = { ...state, ...JSON.parse(fs.readFileSync(DATA_FILE, 'utf-8')) };
} catch (e) {
  console.warn('Could not load data.json, starting fresh:', e.message);
}

let flushTimer = null;
function flush() {
  if (flushTimer) clearTimeout(flushTimer);
  flushTimer = setTimeout(() => {
    fs.writeFile(DATA_FILE, JSON.stringify(state, null, 2), (err) => {
      if (err) console.error('Failed to write data.json', err);
    });
  }, 200);
}

module.exports = {
  get: () => state,
  mutate: (fn) => { fn(state); flush(); },
  reset: () => { state = initial(); flush(); },
};
```

Every mutation goes through `store.mutate(state => { ... })` so persistence is automatic.

---

## 5. SSE handling (`events.js`)

```js
// src/routes/events.js
const express = require('express');
const router = express.Router();

const subscribers = new Map(); // userId -> Set<Response>

router.get('/events', (req, res) => {
  const userId = req.query.userId;
  if (!userId) return res.status(400).end();

  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');
  res.flushHeaders();

  res.write(`event: hello\ndata: ${JSON.stringify({ userId })}\n\n`);

  if (!subscribers.has(userId)) subscribers.set(userId, new Set());
  subscribers.get(userId).add(res);

  const ping = setInterval(() => res.write(`: ping\n\n`), 25000);

  req.on('close', () => {
    clearInterval(ping);
    subscribers.get(userId)?.delete(res);
  });
});

function publish(userIds, eventName, payload) {
  for (const uid of userIds) {
    const subs = subscribers.get(uid);
    if (!subs) continue;
    const frame = `event: ${eventName}\ndata: ${JSON.stringify(payload)}\n\n`;
    for (const r of subs) {
      try { r.write(frame); } catch { /* swallow */ }
    }
  }
}

module.exports = { router, publish };
```

Other route handlers `require('./events').publish(...)` after mutations.

---

## 6. Server-side validation rules

- **Past time on call request**: reject with 400 `{ error: "Cannot schedule in the past" }`.
- **Note length**: reject if `note.length > 140`.
- **Conflict**: query `callRequests` for the same trainer with `status === 'approved'` AND `|scheduledFor - newScheduledFor| < 30min` → 409.
- **Role mismatch on token**: if `role` is not `host` or `guest`, reject 400.
- **Unknown user IDs**: if sender/receiver/member/trainer not in users list, reject 400.

Keep validation simple — Joi/Zod are overkill for a 6-hour build. Hand-written `if`s.

---

## 7. Running the server

```bash
cd token_server
cp .env.example .env
# edit .env: paste HMS_FALLBACK_TOKEN from dashboard if you don't want to set up management API
npm install
npm start
```

Boot log should show:
```
[token_server] starting on :8787
[token_server] hmsMode = fallback   (or "managed" or "none")
[token_server] loaded data.json (3 messages, 1 call request)
[token_server] ready
```

If `hmsMode = none`, calls will fail with a clear message — fix `.env` and restart.

---

## 8. Test it from cURL

```bash
# Health
curl http://localhost:8787/health

# Get users
curl http://localhost:8787/users

# Send a message
curl -X POST http://localhost:8787/messages \
  -H 'Content-Type: application/json' \
  -d '{"chatId":"c_aarav_dk","senderId":"mb_dk","receiverId":"tr_aarav","text":"Hi Coach 👋"}'

# Tail messages
curl 'http://localhost:8787/messages?chatId=c_aarav_dk'

# Mint a token
curl -X POST http://localhost:8787/token \
  -H 'Content-Type: application/json' \
  -d '{"userId":"mb_dk","role":"guest"}'

# Watch events (in another terminal)
curl -N 'http://localhost:8787/events?userId=tr_aarav'
```

If all five of these work, the server side is done. Move on to Phase 3.

---

## 9. What this server is NOT

- Not a production backend. No auth, no rate limiting, no input sanitization beyond the basics, no HTTPS.
- Not horizontally scalable. Single process, in-memory state + JSON file.
- Not durable under concurrent writes from multiple servers. Single process by design.

These limitations are appropriate for a 6-hour take-home and are called out in `README.md` and `DECISIONS.md` ADR-2.
