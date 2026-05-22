# DECISIONS.md — Architecture Decision Records

---

## ADR-1: State management — BLoC over Provider / Riverpod / GetX

**Status:** Accepted  
**Date:** 2026-05-22

### Context

The assessment required state management for at minimum 8 distinct feature flows (auth, onboarding, chat, schedule, requests, call lifecycle, sessions, dev panel). Common Flutter choices include Provider, Riverpod, BLoC, and GetX.

### Decision

Use `flutter_bloc` ^8.1.0 exclusively. No Provider, no Riverpod, no GetX, no `setState` for business logic anywhere.

### Rationale

1. **Explicit user requirement.** The project spec states "BLoC only" — this is a hard constraint, not a preference.
2. **Testability.** BLoC exposes a pure `(State, Event) → State` contract. Unit tests call `bloc.add(Event)` and `expect(bloc.stream, emitsInOrder([...]))` without mocking widgets. All three required unit tests exploit this.
3. **Clear event/state boundaries.** The call lifecycle has 7 states (`Idle → Preparing → PreJoin → Joining → InCall → Ended → Error`). Modelling these as sealed classes makes illegal transitions compile-time errors rather than runtime bugs.
4. **Debuggability.** `BlocObserver` logs every event/state transition — directly surfaced in the DevPanel ring buffer.

### Trade-offs

- More boilerplate than Riverpod (separate event, state, and bloc files per feature).
- `BlocProvider.value` is required to share a single `CallBloc` instance between `PreJoinPage` and `InCallPage` — a non-obvious pattern that tripped up generation (see AI_LEDGER entry 8).

---

## ADR-2: Storage — Hive (client) + local Node.js server (shared bus)

**Status:** Accepted  
**Date:** 2026-05-22

### Context

The two Flutter apps need to share data in near-real time without a cloud backend. Options considered:

1. Shared Hive file on host disk — two Flutter processes watch the same path.
2. SQLite via `drift` — same problem as Hive for cross-process sharing.
3. Local HTTP server as the shared event bus.
4. Firebase / Supabase — excluded (cloud lock-in, requires internet, overkill for a 6-hour timebox).

### Decision

- **Client-side:** Hive for user session state (`meta` box: `currentUserId`, `hasOnboarded`, `hasSeeded`). Hive is fast, zero-setup, and sufficient for auth state that does not need to cross app boundaries.
- **Cross-app data:** Node.js Express server on `localhost:8787`. Both apps POST and GET over loopback HTTP. Server persists to `data.json` with a 200ms debounced write.

### Rationale

1. **Reliability.** Android emulators and iOS simulators cannot easily share a filesystem path on the host in real time. A loopback HTTP server works identically across emulator, simulator, and real device (with a LAN IP).
2. **Required for 100ms anyway.** The assessment rubric penalizes putting 100ms management keys in the Flutter app. A server-side token minter is mandatory — the same process doubles as the message bus at zero added complexity.
3. **Persistence across restarts.** `data.json` survives killing and restarting either app; the chat history and session logs remain.
4. **SSE ready.** The server already implements `GET /events` with a per-user SSE fan-out. Adding a Dart SSE client later drops chat latency from ~1.5s (poll) to ~100ms without touching the server.

### Trade-offs

- Chat send → peer render is ~1.5s worst-case (polling interval). Documented as a known limitation.
- Requires the token server to be running before either app launches. Documented in README setup order.
- `data.json` is ephemeral — no migration story. Acceptable for a v1 demo.

---

## ADR-3: 100ms room strategy — one pre-configured room per call request

**Status:** Accepted  
**Date:** 2026-05-22

### Context

100ms requires a room to exist before a token can be minted for it. Strategies considered:

1. **One permanent shared room** (single `HMS_ROOM_ID` in `.env`): simplest, but any two concurrent calls collide.
2. **Room created per call request via Management API**: server calls `POST https://api.100ms.live/v2/rooms` at approve-time, stores the room ID in `data.json`.
3. **Room code shortcut** (`getAuthTokenByRoomCode`): only works if you have meeting URLs from the 100ms dashboard; incompatible with the server-side JWT approach.

### Decision

Server creates a 100ms room via the Management API when a call request is **approved** (`PATCH /call-requests/:id` with `status=approved`). The resulting `hmsRoomId` is stored in `data.json` under `roomMetas`. `POST /token` looks up the `RoomMeta` for the given `callRequestId` and signs a JWT scoped to that room.

**Fallback (mode B):** If `HMS_APP_ACCESS_KEY` / `HMS_APP_SECRET` are blank, the server returns `HMS_FALLBACK_TOKEN` from `.env`. Both apps join the same test room. The server logs `hmsMode=fallback` at boot.

### Rationale

- One room per call request prevents participant bleed-across when multiple call requests exist.
- The Management API approach keeps secrets server-side (rubric requirement).
- Fallback mode lets the demo run without live 100ms credentials for local testing.

### Known limitations

1. **Token expiry not retried.** 100ms tokens are short-lived (default 2h). If a call runs past token expiry, the SDK will disconnect. Workaround: regenerate `HMS_FALLBACK_TOKEN` from the dashboard before a long demo. A proper fix would implement token refresh via a `POST /token/refresh` endpoint and an SDK re-join sequence.
2. **One trainer–member pair in v1.** Room lookup uses `callRequestId`; the schema supports multiple members per trainer, but the UI surfaces only the Aarav ↔ DK conversation.
3. **No TURN server configuration.** 100ms manages TURN internally; no custom TURN is configured. On restricted corporate networks, calls may fail to establish.
