# Token Server — WTF Flutter Assessment

A lightweight Node.js / Express server that acts as both the 100ms token minter and the shared event bus (message store, call-request lifecycle, session logs) for the Guru App and Trainer App.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Node.js | 20+ |
| npm | 9+ |

---

## Setup

### 1 — Copy the env file

```bash
cd token_server
cp .env.example .env
```

### 2 — Fill in your 100ms credentials

Open `.env` and set the following fields. Get them from [https://dashboard.100ms.live/](https://dashboard.100ms.live/).

| Variable | Where to find it |
|----------|-----------------|
| `HMS_APP_ACCESS_KEY` | Dashboard → Developer → App Access Key |
| `HMS_APP_SECRET` | Dashboard → Developer → App Secret |
| `HMS_TEMPLATE_ID` | Dashboard → Templates → copy the template ID |
| `HMS_ROOM_ID` | Dashboard → Rooms → any pre-created room ID (fallback) |
| `HMS_MANAGEMENT_TOKEN` | Dashboard → Developer → generate Management Token |
| `HMS_FALLBACK_TOKEN` | Dashboard → a room → "Join with SDK" → copy token (expires in 2 h) |

> **Fallback mode (no credentials):** If `HMS_APP_ACCESS_KEY` and `HMS_APP_SECRET` are left blank, the server boots in `hmsMode=fallback` and returns `HMS_FALLBACK_TOKEN` for every token request. Both apps join the same static room. This is enough for a local demo without a 100ms account.

### 3 — Install dependencies

```bash
npm install
```

### 4 — Start the server

```bash
npm start
```

You should see:

```
[SERVER] WTF token server running on :8787  (hmsMode=jwt)
```

Or if credentials are blank:

```
[SERVER] WTF token server running on :8787  (hmsMode=fallback)
```

The server listens on **`http://localhost:8787`** by default. Change `PORT` in `.env` if needed.

---

## API endpoints

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/health` | Uptime + hmsMode |
| `GET` | `/users` | List seeded users |
| `POST` | `/token` | Mint a 100ms auth JWT for a given userId + role + callRequestId |
| `GET` | `/messages` | Fetch messages (query: `chatId`, `since`) |
| `POST` | `/messages` | Send a message |
| `POST` | `/messages/read-batch` | Mark messages as read |
| `GET` | `/call-requests` | List call requests (query: `memberId` or `trainerId`) |
| `POST` | `/call-requests` | Create a new call request |
| `PATCH` | `/call-requests/:id` | Approve / Decline / Cancel a request |
| `GET` | `/session-logs` | List session logs |
| `POST` | `/session-logs` | Create a session log after a call ends |
| `PATCH` | `/session-logs/:id` | Update rating or notes on a session log |
| `GET` | `/events` | SSE stream for real-time push (per userId, via `?userId=`) |

---

## Persistence

All data is stored in memory and flushed to `data.json` with a 200 ms debounce. The file is created automatically on first write and survives server restarts. It is gitignored.

---

## Token minting (`POST /token`)

**Request body:**
```json
{
  "userId": "dk_member",
  "role": "member",
  "callRequestId": "req_abc123"
}
```

**Response (jwt mode):**
```json
{
  "token": "<HS256-signed JWT>",
  "hmsRoomId": "6a108910..."
}
```

**Response (fallback mode):**
```json
{
  "token": "<HMS_FALLBACK_TOKEN value>",
  "hmsRoomId": "<HMS_ROOM_ID value>"
}
```

---

## Dynamic room creation

When a call request is **approved** (`PATCH /call-requests/:id` with `{ "status": "approved" }`), the server calls the 100ms Management API to create a new room scoped to that call request and stores the resulting `hmsRoomId` in `data.json`. Subsequent `/token` calls for the same `callRequestId` reuse that room.

If dynamic room creation fails (e.g. Management Token is expired), the server falls back to `HMS_ROOM_ID`.

---

## Running in dev mode (auto-restart on save)

```bash
npm run dev
```

Requires Node.js 20+ (uses `node --watch`).
