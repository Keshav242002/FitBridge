# ARCHITECTURE.md — System Topology & Design

---

## 1. Client-server topology

```
┌──────────────────────────┐        ┌──────────────────────────┐
│   Guru App (Member/DK)   │        │  Trainer App (Aarav)     │
│   Flutter · BLoC         │        │  Flutter · BLoC          │
│                          │        │                          │
│  ┌──────────────────┐    │        │   ┌──────────────────┐   │
│  │   Feature Blocs  │    │        │   │   Feature Blocs  │   │
│  │  Chat/Schedule/  │    │        │   │  Chat/Requests/  │   │
│  │  Call/Sessions   │    │        │   │  Call/Sessions   │   │
│  └────────┬─────────┘    │        │   └────────┬─────────┘   │
│           │              │        │            │              │
│  ┌────────▼─────────┐    │        │   ┌────────▼─────────┐   │
│  │   Services       │    │        │   │   Services       │   │
│  │  ChatService     │    │        │   │  ChatService     │   │
│  │  ScheduleService │    │        │   │  ScheduleService │   │
│  │  SessionService  │    │        │   │  SessionService  │   │
│  │  CallService     │    │        │   │  CallService     │   │
│  └────────┬─────────┘    │        │   └────────┬─────────┘   │
│           │              │        │            │              │
│  ┌────────▼─────────┐    │        │   ┌────────▼─────────┐   │
│  │   ApiClient      │    │        │   │   ApiClient      │   │
│  │  (single HTTP    │    │        │   │  (single HTTP    │   │
│  │   class, sealed  │    │        │   │   class, sealed  │   │
│  │   ApiResponse)   │    │        │   │   ApiResponse)   │   │
│  └────────┬─────────┘    │        │   └────────┬─────────┘   │
│           │              │        │            │              │
│  ┌────────▼─────────┐    │        │   ┌────────▼─────────┐   │
│  │ hmssdk_flutter   │    │        │   │ hmssdk_flutter   │   │
│  └────────┬─────────┘    │        │   └────────┬─────────┘   │
└───────────┼──────────────┘        └────────────┼─────────────┘
            │                                    │
            │  HTTP/SSE @ localhost:8787          │
            ▼                                    ▼
   ┌────────────────────────────────────────────────────┐
   │               token_server  (Node.js / Express)    │
   │                                                    │
   │   GET  /health          → uptime + hmsMode         │
   │   POST /token           → mint 100ms auth JWT      │
   │   POST/GET /messages    → chat persistence         │
   │   POST /messages/read-batch → mark read            │
   │   POST/PATCH/GET /call-requests → lifecycle        │
   │   POST/PATCH/GET /session-logs  → after-call data  │
   │   GET  /events          → SSE per-user push        │
   │                                                    │
   │   in-memory store  ──debounce 200ms──▶  data.json  │
   └────────────────────────┬───────────────────────────┘
                            │ HTTPS (JWT-signed)
                            ▼
                  ┌──────────────────┐
                  │   100ms Cloud    │
                  │  (auth + relay)  │
                  └────────┬─────────┘
                           │ WebRTC media (DTLS/SRTP)
              ┌────────────┴────────────┐
   (Guru App connects)        (Trainer App connects)
```

---

## 2. ApiClient pattern

There is exactly **one HTTP class** in the codebase: `shared/lib/services/api_client.dart`.

```
ApiClient
  ├── get(path)    → Future<ApiResponse<dynamic>>
  ├── post(path, body)
  ├── patch(path, body)
  └── delete(path)

ApiResponse<T>  (sealed)
  ├── ApiSuccess<T>  { statusCode, data }
  └── ApiFailure<T>  { statusCode, message }
```

**Rules enforced throughout the codebase:**
- `ApiClient` never parses JSON into models — it returns raw `dynamic`.
- Parsing happens in the **Bloc**: on `ApiSuccess`, the Bloc calls `Model.fromJson(data)` and emits `Loaded`. On `ApiFailure`, it emits `Error`.
- All HTTP calls — chat, scheduling, sessions, token — go through `ApiClient`. The only exception is `hmssdk_flutter`, which manages its own WebRTC transport.

Base URL is injected at compile time via `--dart-define=API_BASE_URL=...` and falls back to `http://localhost:8787`.

---

## 3. BLoC layering

Each feature follows a strict layered pattern:

```
Presentation (Page/Screen)
      │  add(Event)
      ▼
    Bloc
      │  calls service methods
      ▼
   Service   ──▶  ApiClient  ──▶  token_server
      │  returns model / stream
      ▼
    Bloc parses, emits State
      │
      ▼
Presentation rebuilds via BlocBuilder / BlocListener
```

**No exceptions:**
- No `setState` for business logic (only `StatefulWidget` for animation controllers).
- No `Provider` / `Riverpod` / `GetX`.
- Every screen that does anything stateful has a `Bloc` or `Cubit`.
- Events in — States out. Widgets only call `context.read<Bloc>().add(Event)`.

**Feature Blocs:**

| Bloc | Events | Key States |
|------|--------|-----------|
| `LoginBloc` | `SubmitLogin` | `LoginInitial`, `LoginLoading`, `LoginSuccess`, `LoginError` |
| `OnboardingBloc` | `NextSlide`, `SubmitProfile` | `OnboardingSlide1/2`, `ProfileSetup`, `OnboardingDone` |
| `ChatListBloc` | `LoadChatList` | `ChatListLoading`, `ChatListLoaded` |
| `ChatBloc` | `LoadHistory`, `SendMessage`, `MessageReceived`, `MarkRead`, `PeerTyping` | `ChatLoading`, `ChatLoaded(messages, isPeerTyping)`, `ChatError` |
| `ScheduleBloc` | `LoadSlots`, `SelectSlot`, `SubmitRequest` | `ScheduleInitial`, `ScheduleLoaded`, `ScheduleSubmitted` |
| `MyRequestsBloc` | `LoadMyRequests` | `MyRequestsLoading`, `MyRequestsLoaded` |
| `RequestsBloc` | `LoadRequests`, `ApproveRequest`, `DeclineRequest` | `RequestsLoading`, `RequestsLoaded` |
| `CallBloc` | `PrepareJoin`, `JoinNow`, `EndCall`, `ToggleMic`, `ToggleVideo`, `FlipCamera` | `CallIdle`, `CallPreparing`, `CallPreJoin`, `CallJoining`, `CallInCall`, `CallEnded`, `CallError` |
| `SessionsBloc` | `LoadSessions`, `FilterChanged` | `SessionsLoading`, `SessionsLoaded`, `SessionsError` |

---

## 4. 100ms call lifecycle

```
USER TAPS "JOIN CALL"
         │
         ▼
  CallBloc.add(PrepareJoin(callRequestId, userId, role))
         │
         ▼  [CallPreparing]
  ensureCallPermissions()  ── camera, microphone, bluetoothConnect
         │
         ▼
  ApiClient.post('/token', {userId, role, callRequestId})
         │
         │  token_server signs HS256 JWT using HMS_APP_SECRET
         │  looks up (or creates) HMSRoom for callRequestId
         │  returns { token, hmsRoomId }
         ▼
  [CallPreJoin]  ─── PreJoinPage renders mic/cam toggles
         │
  USER TAPS "JOIN"
         │
         ▼  [CallJoining]
  CallService.join(token, userName)
    ├── hmsSDK.build()
    ├── hmsSDK.addUpdateListener(this)
    └── hmsSDK.join(HMSConfig(authToken: token, userName: name))
         │
         ▼
  HMSUpdateListener callbacks → private Bloc events
    ├── onJoin(room)         → _Joined  → [CallInCall]
    ├── onPeerUpdate         → _PeerUpdated → InCall.copyWith(peers)
    ├── onTrackUpdate        → _TrackUpdated → InCall.copyWith(track)
    ├── onReconnecting       → _Reconnecting → InCall(isReconnecting: true)
    ├── onReconnected        → _Reconnected  → InCall(isReconnecting: false)
    └── onHMSError           → _SdkError → [CallError]
         │
         ▼
  InCallPage: 2-peer vertical grid
    ├── Remote peer: HMSVideoView (top)   or CircleAvatar (muted/absent)
    ├── Local peer:  HMSVideoView(setMirror:true) (bottom)
    ├── Gradient control bar: 🎤 📷 🔄 🔴
    └── CircularProgressIndicator overlay when isReconnecting
         │
  USER TAPS END (red button)
         │
         ▼
  CallBloc.add(EndCall)
  CallService.leave()  →  hmsSDK.leave()
         │  _Left event fires
         ▼
  ApiClient.post('/session-logs', {memberId, trainerId, startedAt, endedAt, durationSec})
  [CallEnded]  →  navigate to PostCallPage
         │
         ▼
  PostCallPage (role-aware)
    ├── Member: 5-star rating + optional note → PATCH /session-logs/:id
    └── Trainer: notes + "Mark as complete"  → PATCH /session-logs/:id
  "Session saved to your logs."
```

**Key SDK gotchas documented here so the next engineer doesn't repeat them:**
- `await hmsSDK.build()` must be called before `join`. Forgetting it causes a silent no-op join.
- Permissions must be granted before `join`; joining without them results in a muted/no-video peer.
- Use `toggleMicMuteState()` / `toggleCameraMuteState()` — the older `switchAudio` / `switchVideo` are deprecated.
- `HMSVideoTrack` is a subtype of `HMSTrack`; always check `track is HMSVideoTrack` before casting, since audio tracks arrive on the same `onTrackUpdate` callback.

---

## 5. Data persistence strategy

| Data | Where stored | Who owns it |
|------|-------------|-------------|
| User session (currentUserId) | Hive `meta` box (client-side) | `AuthService` |
| Chat messages, call requests, session logs | `token_server/data.json` (server) | token_server `store.js` |
| Room metadata | `data.json` | token_server `hms.js` |
| Structured log ring buffer (last 200 lines) | In-memory (client) | `Logger` |

`data.json` is debounced 200ms and persists across server restarts. It is gitignored.

---

## 6. Cross-app communication

Both apps point to the same token server (`localhost:8787`). The server is the **message bus**:

- Guru App POSTs a message → server stores it → Trainer App polls `GET /messages?since=<cursor>` every 1.5s → ChatBloc receives it → UI updates.
- On approve/decline, server writes a system message → same poll path surfaces it in both apps' chat.
- SSE (`GET /events`) is implemented server-side and can replace polling when a native SSE client is wired up. Current implementation uses polling-only for simplicity (documented trade-off).
