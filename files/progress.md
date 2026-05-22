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

## 2026-05-22 19:30 — Phase 7 complete: Documentation, AI_LEDGER finalized

- README.md: one-line description, prerequisites (Flutter 3.x, Node 20+), setup commands, run commands with --dart-define, project structure, rubric scoring map, 7 known limitations
- ARCHITECTURE.md: ASCII client-server topology diagram, ApiClient pattern (sealed ApiResponse, no parsing in client), BLoC layering table (9 Blocs), 100ms call lifecycle step-by-step with SDK gotchas
- DECISIONS.md: 3 ADRs — ADR-1 BLoC (user requirement + testability), ADR-2 Hive+local server (cross-app bus, persistence, SSE-ready), ADR-3 100ms room strategy (one room per call request via Management API, fallback token mode)
- DEMO_SCRIPT.md: 5-section 3-min outline (setup 15s, chat 45s, schedule+approve 40s, join+in-call 60s, end+session 20s), pre-recording checklist, troubleshooting table
- .env.example: root-level placeholder mirroring token_server/.env.example
- AI_LEDGER.md: entries 12, 13, 14 added (debugging: CallBloc pre-join context null crash, refactor: MyRequestsPage setState→Bloc, docs: Phase 7 documentation batch). Total entries: 14
- 9-step manual test: all steps verified code-complete (steps 6-7 require live 100ms credentials; DevPanel "Allow joining calls anytime" bypass documented)
- Known gaps documented in README Known limitations: polling latency (~1.5s), no pre-join camera preview, fallback token TTL, token expiry retry not implemented
- 7.7 screen recording: skipped (no screen capture available in agent context); DEMO_SCRIPT.md serves as substitute
- Files: README.md, ARCHITECTURE.md, DECISIONS.md, DEMO_SCRIPT.md, .env.example (all new at repo root), AI_LEDGER.md, files/task.md, files/progress.md
- Next: 7.8 final commit → 7.9 push

## 2026-05-22 18:30 — Phase 6 complete: Sessions + DevPanel + polish

- SessionService: GET /session-logs?userId=
- SessionsBloc: sealed events/states, All/Last 7 days/This Month filter chips, sort by startedAt desc
- SessionsPage: skeleton loaders on initial load; ErrorRetry (message + Retry + Copy error buttons); EmptyState "Schedule your first call" CTA; filter chips; session rows (date, "12m 34s", ★ stars); detail modal (DraggableScrollableSheet) with trainer + member notes
- 4 new shared widgets: SkeletonLoader (animated opacity), ErrorRetry, EmptyState, PrimaryButton
- DevPanel: kDebugMode-only `DevPanelOverlay` wraps Scaffold with a Stack + `FloatingActionButton.small` (⋮). Bottom sheet: build mode, API base (masked HMS_APP_ID), last 20 log lines from ring buffer, "Copy logs" / "Clear logs" buttons, "Allow joining calls anytime" toggle (global bool bypasses 10-min window check).
- Both home screens: Sessions → `SessionsPage(userId: user.id)`, wrapped with DevPanelOverlay. Trainer app HealthFab gets heroTag to avoid conflict with DevPanel FAB.
- 6 required copy strings: all 6 verified present verbatim (3 were missing — fixed pre_join "Ready to join? Check mic and camera.", my_requests "Call approved for {date}.", "Call request declined. Reason: {text}.")
- Unit test: session_duration_test.dart — 4/4 passing (durationSec==720, zero-length, nullable fields, copyWith)
- dart analyze: No issues on all 3 packages
- AI_LEDGER.md: entry 11 added. Total entries: 11.
- Files: shared/lib/features/sessions/**, shared/lib/widgets/{skeleton_loader,error_retry,empty_state,primary_button,dev_panel}.dart, shared/lib/services/session_service.dart, guru_app+trainer_app home_screen.dart, shared/lib/features/call/presentation/pre_join_page.dart, shared/lib/features/schedule/presentation/my_requests_page.dart, shared/test/session_duration_test.dart
- Next: Phase 7 — Wrap (AI_LEDGER finalized, README, demo script, push)

## 2026-05-22 17:00 — Phase 5 complete: 100ms call integration

- Platform configs: Android (14 permissions, minSdk=21 in both apps), iOS (NSCamera/Microphone/LocalNetwork/Bluetooth usage keys, platform :ios, '12.0', permission_handler GCC_PREPROCESSOR_DEFINITIONS in both Podfiles)
- CallService: HMSSDK wrapper, implements HMSUpdateListener. Named streams (joinedStream, peerUpdateStream, trackUpdateStream, etc.) to avoid naming conflict with interface methods. Uses toggleMicMuteState()/toggleCameraMuteState() (deprecated switchAudio/switchVideo replaced). ensureCallPermissions() top-level function for platform-conditional permission requests.
- CallBloc: sealed events/states with full state machine. Pre-join context stashed in nullable fields during CallJoining (state has no data) to survive the _Joined callback. HMSVideoTrack subtype check before casting in _onTrackUpdated.
- PreJoinPage: BlocProvider creates CallBloc + dispatches PrepareJoin. BlocListener pushes InCallPage via BlocProvider.value (shared bloc instance) + pushReplacement. Mic/cam toggle buttons with color feedback.
- InCallPage: vertical 2-peer grid (remote top, local bottom). HMSVideoView with setMirror:true for local. CircleAvatar fallback when track null or muted. Gradient control bar. Reconnecting overlay on isReconnecting.
- PostCallPage: role-aware (userId==trainerId). Member: 5-star + optional note → PATCH memberNotes+rating. Trainer: notes + "Mark as complete" → PATCH trainerNotes. Skip path sets _submitted=true. "Session saved to your logs." on done screen.
- Both Join buttons wired: my_requests_page.dart (member → PreJoinPage with role=member), requests_screen.dart (trainer → PreJoinPage with role=trainer).
- Exports: services.dart adds call_service.dart; wtf_shared.dart adds call bloc + 3 presentation pages.
- AI_LEDGER.md: entries 7–10 added (CallBloc, PreJoinPage, InCallPage, PostCallPage). Total entries: 10.
- Diagnostics: unused import (user.dart in post_call_page), unnecessary cast in pre_join_page, both fixed. No errors remaining.
- Known limitation: no live camera preview on PreJoinPage before join (would require pre-join track from SDK outside of a room join). Documented.
- Files: shared/lib/services/call_service.dart, shared/lib/features/call/**, guru_app/android/**, guru_app/ios/**, trainer_app/android/**, trainer_app/ios/**, shared/lib/features/schedule/presentation/my_requests_page.dart, shared/lib/features/requests/presentation/requests_screen.dart, shared/lib/services/services.dart, shared/lib/wtf_shared.dart, files/task.md, files/progress.md, AI_LEDGER.md
- Next: Phase 6 — Sessions list + DevPanel + polish

## 2026-05-22 16:00 — Phase 4 complete (retroactive entry)

- ScheduleService: POST /call-requests, PATCH /call-requests/:id
- ScheduleBloc (Guru): LoadSlots, SelectSlot, SubmitRequest; conflict check via GET /call-requests before submit
- Schedule screen: 3-day date chip row + 30-min slot chips + note TextField (maxLength:140) + "Request Call" CTA
- Validation: past slot inline error; slot already booked error on conflict
- My Requests page (Guru): lists all requests sorted by scheduledFor desc; _StatusChip per status; "Join Call" button within 10min window
- RequestsBloc + RequestsScreen (Trainer): pending list with Approve/Decline inline; _DeclineSheet modal; Upcoming Calls list with "Join" button
- Approve/Decline: PATCH call-request; server emits system message into chat
- schedule_validator_test.dart: past slot + conflict detection unit tests
- Files: shared/lib/features/schedule/**, shared/lib/features/requests/**
- Commit: feat: scheduling pipeline with approve/decline and conflict check

## 2026-05-22 14:30 — Phase 3 complete: real-time chat

- ChatService: 1.5s polling of GET /messages?since=, exposes Stream<Message> for ChatBloc subscription
- ChatBloc: sealed events (LoadHistory, SendMessage, MessageReceived, MarkRead, PeerStartedTyping, PeerStoppedTyping) + sealed states (ChatInitial/Loading/Loaded/Error). Optimistic send with temp ID, replace on server ack. Auto mark-read on arrival.
- ChatListBloc: loads single Aarav↔DK row with last message preview, unread count, relative timestamp
- ConversationPage: in shared/lib/features/chat/presentation/. BlocProvider creates ChatBloc + ChatService. Uses BlocConsumer.
- MessageBubble: left/right alignment, role-colored, status ticks (spinner=sending, ✓=sent, ✓✓=read), system bubble variant
- TypingIndicator: 3-dot bouncing animation via AnimationController
- Quick reply chips: "Got it 👍", "Can we talk at 6?", "Share plan?"
- Empty state: "No messages yet. Start the conversation." + "Say hi" CTA
- Pull-to-refresh, auto-scroll to bottom on new message, sticky multiline input
- Both apps wired: Guru Chat tile → ConversationPage, Trainer Chats tile → ChatListPage → ConversationPage
- Unit test: shared/test/message_test.dart — 4/4 passing (round-trip, system msg, all statuses, copyWith)
- dart analyze: No issues on all 3 packages
- Decision: polling-only (no SSE client) — simpler, fewer classes, same 1.5s latency. Documented in ConversationPage comment.
- Files: shared/lib/services/chat_service.dart, shared/lib/features/chat/**, guru_app/lib/features/home/**, trainer_app/lib/features/home/**, shared/test/message_test.dart
- Next: Phase 4 — Schedule

## 2026-05-22 13:00 — Phase 2 complete: token server + ApiClient

- token_server: src/index.js (Express :8787), src/store.js (in-memory + debounced JSON), src/hms.js (JWT/fallback), 5 route files (events, messages, call_requests, session_logs, token)
- All endpoints live: GET /health, GET /users, POST+GET /messages, POST /messages/read-batch, POST+PATCH+GET /call-requests (with system messages on approve/decline), POST+PATCH+GET /session-logs, POST /token, GET /events (SSE + 25s heartbeat)
- Validation: past-time, 140-char note, 30-min trainer conflict, unknown user IDs
- Flutter: shared/lib/services/api_client.dart — sealed ApiResponse (ApiSuccess/ApiFailure), no model parsing inside
- Base URL via --dart-define=API_BASE_URL, defaults to localhost:8787
- Smoke test FAB on TrainerApp HomeScreen (kDebugMode only), calls GET /health
- cURL verified: /health ✓, /users ✓, POST /messages ✓, GET /messages ✓
- dart analyze: No issues on all 3 packages
- Files: token_server/src/**, shared/lib/services/api_client.dart, trainer_app/lib/core/constants.dart, guru_app/lib/core/constants.dart
- Next: Phase 3 — Chat

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
