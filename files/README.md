# .claude/ — Agent Workspace

This folder is the **operating brain** for the Claude Code agent building this 6-hour WTF assessment. Everything the agent needs to do its job lives here.

---

## Read order

1. **`CLAUDE.md`** — Operating manual. Rules, time budget, what to do when stuck. Read first, every session.
2. **`project_spec.md`** — Full requirements from the assignment PDF. The "what to build".
3. **`progress.md`** — Running log of what's done. **Update this constantly.**
4. **`task.md`** — Ordered task queue with checkboxes. **Tick boxes as you go.**
5. **`architecture.md`** — How the pieces fit together. Client-server topology, layering.
6. **`api_contract.md`** — The mandatory one-API-class pattern. Non-negotiable.
7. **`bloc_patterns.md`** — BLoC conventions. Non-negotiable.
8. **`backend_spec.md`** — Token server endpoints, persistence, SSE — full backend contract.
9. **`hms_integration.md`** — 100ms Flutter SDK playbook. Read before any RTC code.
10. **`ai_ledger_template.md`** — How to write `AI_LEDGER.md` entries. Required by the rubric.

---

## The three files to keep alive during the build

| File | Update when |
|------|------------|
| `.claude/progress.md` | Every completed task, every block, every decision |
| `.claude/task.md` | When starting (`[~]`), finishing (`[x]`), or discovering work |
| `AI_LEDGER.md` (repo root) | Every AI-assisted unit of work, minimum 10 total |

If you only have time to update one, update `progress.md`.

---

## The hard fails (auto-zero on the rubric)

1. No 100ms integration that actually joins a room.
2. No `AI_LEDGER.md` with real entries.
3. App doesn't run with one command.

Plus the user-mandated rules:

4. State management must be BLoC. No Provider, Riverpod, GetX, or `setState` for business logic.
5. All HTTP must go through the single `ApiClient` class. Parsing happens in Blocs.
6. Two apps must talk to each other locally via the token_server message bus.

---

## Time budget at a glance

```
0:00 ── 0:30  Phase 0  Setup
0:30 ── 1:00  Phase 1  Auth + Onboarding
1:00 ── 1:45  Phase 2  Token server + ApiClient
1:45 ── 3:00  Phase 3  Chat
3:00 ── 3:45  Phase 4  Schedule
3:45 ── 5:00  Phase 5  100ms call  ← biggest single bucket
5:00 ── 5:30  Phase 6  Sessions + polish
5:30 ── 6:00  Phase 7  Wrap (docs, ledger, demo video)
```

When in doubt, look at `task.md`.
