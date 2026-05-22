# Phase 2 — Token Server + ApiClient (1:00 – 1:45)

**Goal:** Server is live, all endpoints respond correctly, Flutter has one HTTP class.

## Token Server Tasks (Node.js)

| Task | Detail |
|------|--------|
| `2.1` | `src/index.js`: Express on `:8787`, CORS open, `GET /health` returns `{ok: true, uptime, hmsMode}` |
| `2.2` | `src/store.js`: in-memory state + debounced `data.json` writes (200ms). Seeds `tr_aarav` + `mb_dk` on init |
| `2.3` | `src/routes/events.js`: SSE `/events?userId=...` with `Map<userId, Set<Response>>`, 25s heartbeat |
| `2.4` | `src/routes/messages.js`: `POST /messages`, `GET /messages?chatId&since`, `POST /messages/read-batch` — fan-out SSE on each |
| `2.5` | `src/routes/call_requests.js`: `POST /call-requests` (past-time + conflict validation), `PATCH /call-requests/:id` (creates RoomMeta + system message on approval), `GET /call-requests?userId` |
| `2.6` | `src/routes/session_logs.js`: `POST /session-logs`, `PATCH /session-logs/:id`, `GET /session-logs?userId&from&to` |
| `2.7` | `src/routes/token.js` + `src/hms.js`: JWT signing (HS256) with `HMS_APP_ACCESS_KEY/SECRET`; fallback to `HMS_FALLBACK_TOKEN` |
| `2.8` | `.env.example`: `HMS_APP_ACCESS_KEY`, `HMS_APP_SECRET`, `HMS_ROOM_ID`, `HMS_FALLBACK_TOKEN`, `PORT=8787` |

## Flutter Side Tasks

| Task | Detail |
|------|--------|
| `2.9` | `shared/lib/services/api_client.dart` — **the only HTTP class**. Sealed `ApiResponse`: `ApiSuccess(statusCode, body, headers)` / `ApiFailure(statusCode?, code, message, body?)`. Methods: `get/post/patch/delete`. No model parsing inside |
| `2.10` | Base URL via `--dart-define=API_BASE_URL` (default `http://10.0.2.2:8787` Android / `http://localhost:8787` elsewhere) |
| `2.11` | Smoke test: debug button in either app calls `GET /health`, shows snackbar |
| `2.12` | Commit: `feat: token server + sealed ApiClient` |

## All Endpoints

| Method | Path | Notes |
|--------|------|-------|
| GET | `/health` | `{ok, uptime, hmsMode}` |
| POST | `/token` | `{userId, role, callRequestId?}` → `{token, hmsRoomId, expiresAt}` |
| GET | `/users` | seeded users array |
| POST | `/messages` | 201 with full Message + SSE fan-out |
| GET | `/messages?chatId&since` | sorted asc, last 100 if no `since` |
| POST | `/messages/read-batch` | `{ids, readerId}` → updates status + SSE to sender |
| POST | `/call-requests` | validate past/conflict; 201 + SSE |
| PATCH | `/call-requests/:id` | approve creates RoomMeta + system msg; decline creates system msg |
| GET | `/call-requests?userId&since` | sorted by scheduledFor asc |
| POST | `/session-logs` | 201 with computed durationSec |
| PATCH | `/session-logs/:id` | rating, notes |
| GET | `/session-logs?userId&from&to` | |
| GET | `/events?userId` | SSE stream |

## Validation Rules
- Past time on call request → 400 `{ error: "Cannot schedule in the past" }`
- Note > 140 chars → 400
- Trainer has approved request within 30-min window → 409
- Role not `host`/`guest` → 400
- Unknown user IDs → 400

## Verify with cURL before leaving Phase 2
```bash
curl http://localhost:8787/health
curl http://localhost:8787/users
curl -X POST http://localhost:8787/messages -H 'Content-Type: application/json' -d '{"chatId":"c_aarav_dk","senderId":"mb_dk","receiverId":"tr_aarav","text":"Hi Coach"}'
curl 'http://localhost:8787/messages?chatId=c_aarav_dk'
curl -X POST http://localhost:8787/token -H 'Content-Type: application/json' -d '{"userId":"mb_dk","role":"guest"}'
```
