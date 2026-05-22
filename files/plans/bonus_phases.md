# Bonus Phases (only if Phase 7 complete with time remaining)

**Rule:** Never start a bonus phase unless Phase 7 is fully done. Cut bonuses before cutting any core phase.

## Priority Order

| Priority | Task | Package | Notes |
|----------|------|---------|-------|
| B1 | Local notification 10 min before scheduled call | `flutter_local_notifications` | Schedule notification at approval time using `scheduledFor - 10min` |
| B2 | Image attachments in chat | `image_picker` | Store base64 or local path; thumbnail bubble in chat UI |
| B3 | Offline send queue | Hive | Write to local Hive box when server unreachable; replay on reconnect |
| B4 | Light / Dark theme toggle | — | Extend `theme.dart` with dark variants; `ThemeBloc` or `ThemeCubit` at app root |
| B5 | Export session summary as shareable text | `share_plus` | Format: date, duration, rating, notes → share sheet |

## What NOT to cut (protected core)
- 100ms join (25 pts — biggest single bucket)
- Chat send/receive with status ticks (15 pts)
- Session log auto-write after call
- AI_LEDGER.md with ≥10 real entries
- App runs with one command (README one-liner)

## Cut order if behind schedule
1. Bonus phases (B1–B5) — first to go
2. Phase 6 polish (skeleton loaders, snackbar "Copy error")
3. Phase 4 scheduler edge cases (conflict check client-side pre-validation)
4. Phase 1 onboarding animations and slide transitions
5. Never cut: chat, 100ms join, session log, AI_LEDGER
