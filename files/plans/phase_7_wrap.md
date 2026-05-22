# Phase 7 — Wrap (5:30 – 6:00)

**Goal:** Ship-ready. Docs complete. 9-step manual test passes.

## Tasks

| Task | Detail |
|------|--------|
| `7.1` | Run the full 9-step manual test. Fix blocking issues. Document remaining issues in `progress.md` + `README.md` Known Limitations |
| `7.2` | `AI_LEDGER.md`: verify ≥10 entries covering scaffold, Bloc, token server, debugging, refactor, tests, docs |
| `7.3` | `README.md`: one-line description, prerequisites, setup commands, run commands with `--dart-define`, project structure, rubric map, known limitations |
| `7.4` | `ARCHITECTURE.md`: client-server topology diagram, ApiClient pattern, Bloc layering, 100ms call lifecycle (ASCII ok) |
| `7.5` | `DECISIONS.md`: ADR-1 BLoC choice, ADR-2 Hive + local server, ADR-3 100ms room strategy (one shared room) |
| `7.6` | `DEMO_SCRIPT.md`: 3-min outline — setup (15s), chat (45s), schedule+approve (40s), join+in-call (60s), end+session (20s) |
| `7.7` | Record 3-min screen recording with both emulators side by side |
| `7.8` | Final commit: `docs: README, ARCHITECTURE, DECISIONS, demo script, final AI ledger` |
| `7.9` | Push. Verify clone-and-run from a fresh folder |

## The 9-Step Manual Test (must pass)
1. Launch Trainer App, login as Aarav (seeded)
2. Launch Guru App, onboarding DK → assigned to Aarav
3. DK sends "Hi Coach 👋" → Trainer sees unread badge, opens chat, replies
4. DK schedules a call for "today 6:00 PM", note: "Macros review"
5. Trainer approves; DK sees system message in chat + entry in Upcoming Calls
6. Both tap **Join Call** → device check → connect (use DevPanel override to bypass 10-min window)
7. Trainer toggles mute / video / flip; Member sees changes smoothly
8. End call → SessionLog written. DK rates 5★ + note; Trainer adds notes
9. Open Sessions list → latest entry on top with rating + duration

## AI_LEDGER Coverage Required
- [ ] Initial scaffolding / boilerplate generation
- [ ] A complex feature Bloc (chat or call)
- [ ] Token server code
- [ ] A real debugging session (paste the error symptom)
- [ ] A refactor
- [ ] Test writing
- [ ] Documentation (README / ARCHITECTURE)
Minimum 10 entries, aim for 15+.

## README Must Include
- One-line description
- Prerequisites (Flutter 3.x, Node 20+, Android Studio / Xcode)
- Setup: `cd token_server && cp .env.example .env && npm i && npm start`
- Run: `cd guru_app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787`
- Run: `cd trainer_app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787`
- Project structure
- Rubric scoring map
- Known limitations

## DECISIONS.md ADRs
- ADR-1: BLoC over Provider/Riverpod — user requirement + testability
- ADR-2: Hive + local Node server — local-first, no cloud lock-in, cross-app message bus
- ADR-3: 100ms room strategy — one pre-created room for v1; document limitation
