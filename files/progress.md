# progress.md — Running Progress Log

> **How to use this file**: Append a dated entry every time a task moves to done, blocked, or you take a meaningful decision. Newest at the top. Keep entries terse but specific. The user will scan this to verify state.
>
> **Format**:
> ```
> ## YYYY-MM-DD HH:MM — <short title>
> - What got done
> - What's in flight
> - What's blocked, and what was tried
> - Files touched
> - Next step
> ```

---

## 2026-05-22 11:00 — Phase 1 complete: auth + onboarding

- AuthService in shared/: Hive-backed login/currentUser/logout/seed (idempotent `hasSeeded` flag)
- Trainer App: LoginBloc (sealed events/states) + LoginScreen (email prefilled aarav@wtf.local) + HomeScreen (4 tiles)
- Guru App: OnboardingBloc + 2-slide OnboardingScreen + ProfileSetup + HomeScreen (3 cards)
- AppBarWithRole widget in both apps (role badge chip in AppBar)
- Themes applied: Trainer #E50914 red, Guru #1769E0 blue, WtfColors extension for success/warning
- `dart analyze lib/` → No issues found on all 3 packages
- Files: shared/lib/services/auth_service.dart, trainer_app/lib/features/auth/**, guru_app/lib/features/auth/**, both app.dart + main.dart, core/theme.dart in both
- Next: Phase 2 — token server endpoints + ApiClient

---

## YYYY-MM-DD HH:MM — Session start (template — replace this)

- Project initialized from PRD in `.claude/`
- All planning docs read
- About to start Phase 0 setup tasks
- Files: none yet
- Next: task 0.1 — `git init` and gitignore

---

<!--
Append new entries above this line as you go.

Examples of good entries:

## 2026-05-22 11:45 — Token server endpoints live
- POST /messages, GET /messages, POST /token, /events SSE all working
- Tested with curl; all return correct shape
- Persisted to data.json with 200ms debounce
- Files: token_server/src/index.js, token_server/src/routes/*.js
- Next: 2.6 — Dart ApiClient class

## 2026-05-22 13:20 — BLOCKED: 100ms reconnect not firing on emulator
- Killed wifi adapter mid-call; onReconnecting never fired
- Tried: forcing airplane mode toggle on emulator; toggling network manually in host
- Suspect: emulator network virtualization swallows the disconnect event before SDK notices
- Workaround: tested on real device — works fine. Documented in DECISIONS.md.
- Files: shared/lib/services/call_service.dart
- Next: 5.10 — onEnd handler and session log auto-write
-->
