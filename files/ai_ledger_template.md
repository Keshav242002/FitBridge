# ai_ledger_template.md — How to write `AI_LEDGER.md`

> The actual ledger lives at the **repo root** as `AI_LEDGER.md`. This file is just the template + examples to copy from.

---

## Header section (paste at top of AI_LEDGER.md)

```markdown
# AI Ledger — WTF Flutter Assessment

This file is required evidence of AI-native workflow. Every meaningful use of an AI tool during this build is logged here with prompt intent, output, and how it was used in the codebase.

**Tools used**: Claude Code (primary), occasional web search.

**Authenticity note**: Outputs were rarely used verbatim. Most entries describe adaptation, debugging, or guided generation. Where output was rejected, the entry explains why.

---
```

---

## Entry template

```markdown
### Entry N — <one-line title>
- **Tool**: Claude Code
- **Time**: ~YYYY-MM-DD HH:MM (approximate, local time)
- **Phase**: <0–7 from task.md>
- **Intent**: <what I was trying to accomplish in one sentence>
- **Prompt summary**: <2–3 lines describing what I asked, NOT the literal prompt unless short>
- **Output use**: <as-is | adapted heavily | rejected and rewrote>
- **Commit**: <hash or "in WIP commit">
- **Notes**: <gotchas, fixes I had to make, why this saved time>
```

---

## Worked examples (use these as a quality bar)

### Entry 1 — Scaffold the five shared models
- **Tool**: Claude Code
- **Time**: ~2026-05-22 10:35
- **Phase**: 0
- **Intent**: Generate Dart classes for User, Message, CallRequest, SessionLog, RoomMeta with `fromJson`/`toJson`/`copyWith`/`Equatable` props, all immutable.
- **Prompt summary**: Gave the agent the five model specs from `project_spec.md` §2 verbatim and asked for one file per model under `shared/lib/models/`, plus a barrel file. Asked for `enum` types where the spec required them.
- **Output use**: Adapted heavily. The generated `fromJson` for `DateTime` used `DateTime.parse` without a null-guard — added try/catch and a sensible default for backward compatibility with messages stored before this change. Renamed `Status` to `MessageStatus` to avoid collisions with `CallRequestStatus`.
- **Commit**: `feat: shared models with json round-trip` — `a1b2c3d`
- **Notes**: Generated boilerplate I would otherwise type by hand for 20 minutes in under 2 minutes. The hand-edits were mostly defensive coding.

### Entry 2 — Token server Express skeleton
- **Tool**: Claude Code
- **Time**: ~2026-05-22 11:05
- **Phase**: 2
- **Intent**: Stand up Express server with the 8 endpoints documented in `task.md` 2.2, including SSE.
- **Prompt summary**: Pasted the endpoint list from `task.md`. Asked for one route file per resource, a single `store.js` for in-memory state with debounced `data.json` persistence, and an `events.js` SSE handler keyed by `userId`.
- **Output use**: As-is for routes; adapted `store.js`. The first version of `flush()` wrote synchronously on every mutation — replaced with a `setTimeout`-based 200ms debouncer to avoid pegging the disk during the chat polling tests.
- **Commit**: `feat: token server with 8 endpoints and SSE` — `b2c3d4e`
- **Notes**: SSE implementation needed two fixes after first run: (1) the `Cache-Control: no-cache` header wasn't being set so EventSource on the Dart side received nothing; (2) heartbeat was missing — added `: ping\n\n` every 25s.

### Entry 3 — Debug: 100ms join silently fails
- **Tool**: Claude Code
- **Time**: ~2026-05-22 14:12
- **Phase**: 5
- **Intent**: Find why `hmsSDK.join()` returned without throwing but `onJoin` never fired.
- **Prompt summary**: Pasted the `CallService` code, the logs around the join call, and the symptom: "Token POST succeeds, join called, no errors, but `onJoin` callback never fires and the UI stays on Joining state forever."
- **Output use**: Adapted. Suggestion was that `hmsSDK.build()` wasn't being awaited. Verified by adding a log line right after `build()` — confirmed the listener was added before build resolved. Fixed by moving `addUpdateListener` to **after** the await.
- **Commit**: `fix: await hmsSDK.build before adding listener` — `c3d4e5f`
- **Notes**: Saved at least 30 minutes of binary-search debugging. The hint about the listener-before-build ordering was the lock-picking insight.

### Entry 4 — ChatBloc with optimistic send
- **Tool**: Claude Code
- **Time**: ~2026-05-22 12:25
- **Phase**: 3
- **Intent**: Write `ChatBloc` with five events (LoadHistory, SendMessage, MessageReceived, MarkRead, PeerStartedTyping) and four states, following the patterns in `.claude/bloc_patterns.md`.
- **Prompt summary**: Linked `.claude/bloc_patterns.md` and `.claude/api_contract.md`. Asked specifically for optimistic UI on send (status sending → sent), and for `MessageReceived` to dedupe by id when both the server-acked send and the SSE echo arrive.
- **Output use**: Adapted. The dedupe logic used `where().toList()` which is fine, but the generated `_onMarkRead` didn't batch — was firing one PATCH per message. Replaced with a single `POST /messages/read-batch` (added that endpoint to the server too).
- **Commit**: `feat: ChatBloc with optimistic send and dedupe` — `d4e5f60`
- **Notes**: Bloc was ~140 lines; the request gave me a working starting point in 60s.

### Entry 5 — Refactor: extract repeated network-error UI
- **Tool**: Claude Code
- **Time**: ~2026-05-22 16:18
- **Phase**: 6
- **Intent**: I had three near-identical error widgets across screens; consolidate into one reusable `ErrorRetry` widget in `shared/widgets/`.
- **Prompt summary**: Pasted the three implementations and asked to extract the shared widget with a clean API (`ErrorRetry({required message, required onRetry, illustration})`).
- **Output use**: As-is. Drop-in replacement worked first try.
- **Commit**: `refactor: extract ErrorRetry shared widget` — `e5f6071`
- **Notes**: Small win, but the kind of refactor I'd skip under time pressure if I didn't have AI to do it in 30 seconds.

---

## What makes a good entry vs a bad entry

**Good (counts)**:
- Names a specific file/feature it produced
- Says how it was adapted (and why) or why rejected
- Links to a commit
- Distinguishes "I would have typed this anyway" from "I would not have found this on my own"

**Bad (looks padded)**:
- "Asked Claude to help with chat" — too vague
- "Generated full app" — too coarse
- 10 entries that all say "as-is" — looks like uncritical use
- Identical phrasing across entries — looks copy-pasted

---

## Coverage targets

Make sure the final ledger has at least one entry in **each** of these buckets:

- [ ] Initial scaffolding / boilerplate generation
- [ ] A complex feature (chat or call) Bloc
- [ ] Token server code
- [ ] A real debugging session (paste the error symptom)
- [ ] A refactor
- [ ] Test writing
- [ ] Documentation (README / ARCHITECTURE)

If you can hit all 7 categories + 3 more, you're at 10+ entries naturally. No padding required.
