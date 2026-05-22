# CLAUDE.md — Agent Operating Manual

> **This file is your north star. Read it at the start of every session.**
> If anything in this file conflicts with another doc, this file wins.

---

## 1. Who you are and what you are building

You are the engineering agent on a **6-hour timeboxed take-home for WTF**. You are building **two Flutter apps** that talk to each other locally, plus a **tiny token server** for 100ms.

- **Guru App** → the Member-facing app (DK is the seeded member).
- **Trainer App** → the Trainer-facing app (Aarav is the seeded trainer).
- **token_server/** → small Node.js Express server that mints 100ms auth tokens.

The two apps share a **local message bus** (a shared Hive/SQLite DB + a simple file-watched event bridge) so chat and call requests flow between them without a real cloud backend.

**Hard fails (auto-zero):**
1. No 100ms integration that actually joins a room.
2. No `AI_LEDGER.md` with real entries.
3. The app does not run with one command.

Treat those three as production-blocking bugs at all times.

---

## 2. The three files you must keep in sync

Every time you finish a unit of work, update **all three** of these:

| File | Purpose | When to update |
|------|---------|----------------|
| `.claude/progress.md` | Running log of what's done, what's in flight, what's blocked | After every completed task, before every break, when something breaks |
| `.claude/task.md` | The ordered task queue. Tick boxes as you go. | When you start a task (mark in-progress), when you finish (mark done), when you discover new work (add to queue) |
| `AI_LEDGER.md` (repo root) | Evidence of AI-native workflow. Required by the rubric. | Every time you use AI to generate, debug, or refactor — minimum 10 entries |

If you only have time to update one, update `progress.md`. The user will check it to see where you are.

---

## 3. Read order at session start

When you open this project, read in this exact order **before writing any code**:

1. `.claude/CLAUDE.md` ← you are here
2. `.claude/project_spec.md` ← full requirements, data models, acceptance criteria
3. `.claude/progress.md` ← what state the project is in right now
4. `.claude/task.md` ← what to do next
5. `.claude/architecture.md` ← how the pieces fit together
6. `.claude/api_contract.md` ← the one-call API pattern (this is mandatory, read it)
7. `.claude/bloc_patterns.md` ← state management rules (mandatory)
8. `.claude/hms_integration.md` ← 100ms integration playbook

Only after reading those, look at the actual code.

---

## 4. The non-negotiable engineering rules

These come from the user directly. Violating any of these is a defect.

### 4.1 State management: BLoC only
- Use `flutter_bloc` ^8.1.0. No Provider, no Riverpod, no GetX, no setState for business logic.
- Every screen that does anything stateful gets a Bloc or Cubit.
- Events in, States out. No business logic in widgets.
- Pattern reference: `.claude/bloc_patterns.md`.

### 4.2 One API class to rule them all
- **There is exactly one HTTP client class:** `ApiClient` in `shared/services/api_client.dart`.
- It exposes `get`, `post`, `patch`, `delete` methods only.
- It returns a sealed `ApiResponse<T>` — either `ApiSuccess` (status 200/201) carrying the raw response, or `ApiFailure` carrying error code + message.
- **Parsing happens in the Bloc**, not in `ApiClient`. The Bloc takes the raw success response, parses it into a model, and emits `Loaded`. On `ApiFailure`, the Bloc emits an `Error` state.
- This applies to the token server calls and any other HTTP. Internal local-DB calls (Hive) use a separate `LocalStore` abstraction — they don't go through `ApiClient`.
- Full contract: `.claude/api_contract.md`.

### 4.3 Flutter best practices
- Null-safety on. `flutter_lints` enabled. Zero warnings on the final build.
- `const` constructors everywhere they apply.
- No business logic in `build()`.
- File naming: `snake_case.dart`. Class naming: `PascalCase`. No abbreviations in public APIs.
- Folder structure under each app's `lib/`:
  ```
  lib/
    main.dart
    app.dart
    core/         # theme, router, constants, di
    features/
      auth/       # bloc/, data/, presentation/
      chat/
      schedule/
      call/
      sessions/
    shared/       # re-exports from ../../shared if needed
  ```

### 4.4 Conventional Commits
Every commit message:
- `feat: add chat bubble widget`
- `fix: typing indicator stuck after disconnect`
- `chore: bump hmssdk_flutter to 1.10.7`
- `docs: AI ledger entry for call resilience`
- `test: scheduler past-time validation`
- `refactor: extract MessageBus from ChatService`

Commits that used AI must mention it in the body: `Used Claude Code to generate initial Bloc scaffold; manually edited error handling.`

### 4.5 No live secrets in the repo
- Real 100ms keys live only in `token_server/.env` (gitignored).
- Commit `token_server/.env.example` with placeholders.
- Flutter side only ever sees the token returned from the local token server — never the management key.

---

## 5. The two apps must talk to each other locally

This is the trickiest constraint. There is no cloud backend, but both apps need to see the same chat messages, call requests, and session logs **in near-real-time**.

**The strategy** (full detail in `.claude/architecture.md`):

1. Both apps point to a **shared Hive box on disk** via a known path (e.g., `~/wtf_shared/` on the host).
2. A `LocalEventBus` watches the Hive box for changes using a file watcher + a stream controller.
3. When Guru App writes a `Message`, Trainer App's watcher picks it up within ~200ms and emits to its `ChatBloc`.
4. For mobile emulators where filesystem sharing is hard, fall back to a **local HTTP loopback** inside `token_server/` that exposes `/events` SSE and `/messages` POST/GET. Both apps poll/subscribe.

**Decision**: Start with the loopback HTTP approach via `token_server/` — it's more robust across Android emulator + real device + desktop. The token server doubles as the event bus.

This means `token_server/` is not just for 100ms tokens. It is also:
- `POST /messages` — send a chat message
- `GET /messages?chatId=...&since=...` — fetch history (polled every 1.5s, or SSE if time permits)
- `POST /call-requests` — create a call request
- `PATCH /call-requests/:id` — approve / decline
- `GET /call-requests?userId=...`
- `POST /session-logs`
- `GET /session-logs?userId=...`
- `POST /token` — mint a 100ms auth token (the original purpose)

The server keeps everything in a single in-memory store + a JSON file for persistence across restarts. Simple, fast, fits the timebox.

---

## 6. The 6-hour budget

Use this as your default plan unless `task.md` says otherwise. Adjust as you go.

| Phase | Time | Deliverable |
|-------|------|-------------|
| 0 — Setup | 0:00 – 0:30 | Repo scaffold, both apps boot, token server runs, shared models defined |
| 1 — Auth + Onboarding | 0:30 – 1:00 | Both apps have mock auth, DK seeded, Aarav seeded |
| 2 — Token server + ApiClient | 1:00 – 1:45 | Server endpoints live, ApiClient working end-to-end, one test |
| 3 — Chat | 1:45 – 3:00 | Real-time chat working between both apps with status ticks, typing |
| 4 — Schedule | 3:00 – 3:45 | Request → approve/decline → system message in chat |
| 5 — 100ms call | 3:45 – 5:00 | Join, in-call UI, mute/video/flip/end, auto-write session log |
| 6 — Sessions + polish | 5:00 – 5:30 | Sessions list, ratings, post-call sheets, DevPanel |
| 7 — Wrap | 5:30 – 6:00 | AI_LEDGER finalized, demo video script, README, push |

If you fall behind: **cut the bonus items first** (attachments, push notifications, light/dark toggle). Never cut: chat, scheduler, 100ms join, session log, AI_LEDGER.

---

## 7. How to mark progress

In `task.md`, every task has a status: `[ ]` todo, `[~]` in-progress, `[x]` done, `[!]` blocked.

In `progress.md`, append a dated entry every time a task moves to done or blocked:

```
## 2026-05-22 12:34 — Chat send/receive working
- ChatBloc emits Sent → Delivered → Read correctly
- Tested with two emulators
- Known issue: typing indicator stuck if peer force-quits app. Tracking as P2.
- Files: guru_app/lib/features/chat/, shared/services/chat_service.dart
```

Keep entries terse but specific. The user will scan these to verify you're not lying about progress.

---

## 8. AI Ledger requirements

Required: minimum **10 entries** in `AI_LEDGER.md` at repo root. Aim for 15+. Each entry must have:

```
### Entry N — <short title>
- **Tool**: Claude Code
- **Intent**: <what you were trying to do>
- **Prompt summary**: <one-line summary of what you asked>
- **Output use**: <generated as-is | adapted | rejected after attempt>
- **Commit**: <commit hash or "uncommitted, see file X">
- **Notes**: <any gotchas, what you had to fix manually>
```

Spread entries across: scaffold generation, Bloc patterns, 100ms integration, debugging a real error, writing tests, writing docs. Reviewers check for authenticity — do not pad with fake entries.

---

## 9. When you get stuck

1. Re-read `.claude/project_spec.md` — the answer is probably there.
2. Check `.claude/hms_integration.md` for SDK-specific gotchas.
3. If genuinely blocked, mark the task `[!]` in `task.md`, write what you tried in `progress.md`, and **move to the next task**. Document the blocker for the user. Do not loop forever on one issue.
4. Fallbacks are acceptable and **must be documented**: if real 100ms reconnect logic is flaky on the emulator, document it, ship the best version you have, and put a note in `DECISIONS.md`.

---

## 10. The final 30 minutes

When the clock hits 5:30:
1. Stop adding features. Anything not done is documented and shipped.
2. Update `progress.md` with final state.
3. Verify `AI_LEDGER.md` has ≥10 entries.
4. Verify `README.md` has one-command run instructions for both apps + token server.
5. Run both apps end-to-end one last time against the 9-step manual test in `project_spec.md` §6.
6. Write the 3-min demo video script in `DEMO_SCRIPT.md`.
7. Commit everything. Push. Done.

---

**Now read `.claude/project_spec.md` next.**
