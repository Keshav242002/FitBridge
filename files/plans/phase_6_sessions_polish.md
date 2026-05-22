# Phase 6 — Sessions + Polish (5:00 – 5:30)

**Goal:** Sessions list works with filters. DevPanel live. All screens have error/empty/loading states.

## Tasks

| Task | Detail |
|------|--------|
| `6.1` | `SessionsBloc`: loads from `GET /session-logs?userId=...`. Filter chips: All / Last 7 days / This Month |
| `6.2` | Session row: date, duration "12m 34s", rating stars (if any). Tap → detail modal with both notes |
| `6.3` | Sort by `startedAt` desc |
| `6.4` | Empty state: "Schedule your first call" with CTA |
| `6.5` | Unit test: `session_duration_test.dart` — `SessionLog(start: t, end: t+12min).durationSec == 720` |
| `6.6` | DevPanel: floating ⋮ (debug only) → bottom sheet with env info (masked secrets), build mode, last 20 log lines, "Copy logs", "Clear logs", **"Allow joining calls anytime"** toggle |
| `6.7` | Polish pass: skeleton loaders on every initial load; error states with retry on every screen; snackbars with "Copy error"; verify all 6 required copy strings are used verbatim |
| `6.8` | Commit: `feat: sessions list, filters, DevPanel, polish` |

## DevPanel Details
- Only visible in `kDebugMode`
- Floating ⋮ button as overlay
- Bottom sheet shows:
  - App build info (version, build mode)
  - Env vars (masked: `HMS_KEY_PREFIX=...****`)
  - Last 20 log lines from in-memory ring buffer
  - Buttons: "Copy logs", "Clear logs"
  - Toggle: "Allow joining calls anytime" (bypasses 10-min window check)

## Sessions Filter Logic
- **All**: no date filter
- **Last 7 days**: `startedAt >= now - 7days`
- **This Month**: `startedAt >= first day of current month`

## Required Shared Widgets Checklist
- [ ] `AppBarWithRole` — shows "Trainer • Aarav" / "Member • DK"
- [ ] `ChatBubble` — left/right alignment, status ticks
- [ ] `TypingIndicator` — dot animation
- [ ] `TimeChip` — 30-min scheduler slots
- [ ] `PrimaryButton` — filled CTA
- [ ] `EmptyState` — illustration + CTA
- [ ] `SkeletonLoader` — placeholder during loads
- [ ] `ErrorRetry` — error message + retry button

## 6 Required Copy Strings (all must appear verbatim)
1. Empty chat: "No messages yet. Start the conversation."
2. Request sent: "Call requested. Waiting for trainer approval."
3. Approved: "Call approved for {date} {time}."
4. Declined: "Call request declined. Reason: {text}."
5. Pre-join: "Ready to join? Check mic and camera."
6. Post-call: "Session saved to your logs."
