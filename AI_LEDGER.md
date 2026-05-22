# AI Ledger — WTF Flutter Assessment

This file is required evidence of AI-native workflow. Every meaningful use of an AI tool during this build is logged here with prompt intent, output, and how it was used in the codebase.

**Tools used**: Claude Code (primary).

**Authenticity note**: Outputs were rarely used verbatim. Most entries describe adaptation, debugging, or guided generation. Where output was rejected, the entry explains why.

---

### Entry 11 — Phase 6: Sessions feature, DevPanel, shared widgets, polish
- **Tool**: Claude Code
- **Time**: ~2026-05-22 18:00
- **Phase**: 6
- **Intent**: Build the complete sessions feature (SessionService, SessionsBloc with filter logic, SessionsPage with skeleton/error/empty states), add 4 shared widgets (SkeletonLoader, ErrorRetry, EmptyState, PrimaryButton), build the DevPanel overlay with in-memory log viewer and "Allow joining calls anytime" toggle, wire sessions navigation in both home screens, fix 3 of 6 missing required copy strings, and write session_duration_test.dart.
- **Prompt summary**: Asked to execute all Phase 6 tasks from phase_6_sessions_polish.md: SessionsBloc with All/Last 7 days/This Month filter chips, session row with date+duration+stars, detail modal with trainer+member notes, DevPanel as debug-only `Stack` overlay with `FloatingActionButton.small`, bottom sheet showing build mode / masked env vars / last 20 log lines / "Copy logs" / "Clear logs" / "Allow joining calls anytime" toggle, unit test for SessionLog.durationSec==720, and verbatim copy string audit.
- **Output use**: Adapted. Three IDE diagnostics fixed during generation: (1) `__` double-underscore in builder lambdas flagged by `unnecessary_underscores` lint → changed to `_` (Dart 3 wildcard); (2) `activeColor` deprecated on SwitchListTile → changed to `activeThumbColor`; (3) missing closing paren in DevPanelOverlay wrapping of Scaffold → rewrote full file. Copy string audit found 3 of 6 missing: "Ready to join? Check mic and camera." (pre_join had two separate lines), "Call approved for {date} {time}." (missing), "Call request declined. Reason: {text}." (had wrong format). All 3 fixed. All 4 tests pass, `dart analyze` clean on all 3 packages.
- **Commit**: `feat: sessions list, filters, DevPanel, polish`
- **Notes**: DevPanel uses a global `bool allowJoiningCallsAnytime` so any widget in the tree (e.g. `my_requests_page.dart`) can read it without a BuildContext. The `SkeletonLoader` animation uses `withValues(alpha:)` instead of deprecated `withOpacity()`. The `DevPanelOverlay` returns `child` unchanged in non-debug builds (zero overhead in production).

### Entry 10 — Phase 5: PostCallPage role-aware rating + notes
- **Tool**: Claude Code
- **Time**: ~2026-05-22 17:00
- **Phase**: 5
- **Intent**: Generate the post-call sheet that is role-aware: member sees star rating + optional note; trainer sees notes field + "Mark as complete". Both PATCH the session log.
- **Prompt summary**: Asked for a single `PostCallPage` that detects role by comparing `endedState.userId` to `endedState.trainerId`, renders the appropriate form, and PATCHes `/session-logs/:id` with the correct fields before showing the "Session saved to your logs." confirmation screen.
- **Output use**: Used as-is. Removed an unused `user.dart` import flagged by IDE diagnostics. Used `PopScope(canPop: _submitted)` to prevent back-nav before the form is submitted or skipped.
- **Commit**: `feat: 100ms call integration`
- **Notes**: Role detection via userId==trainerId avoids threading the UserRole enum through the CallEnded state — all necessary IDs are already in the state. The "Skip" path sets `_submitted = true` without calling the API, so the session log persists with server-defaults for rating/notes.

### Entry 9 — Phase 5: InCallPage 2-peer grid + controls
- **Tool**: Claude Code
- **Time**: ~2026-05-22 16:45
- **Phase**: 5
- **Intent**: Build the in-call screen with a vertical 2-peer HMSVideoView grid, gradient control bar at the bottom, and a reconnecting overlay.
- **Prompt summary**: Asked to implement `InCallPage` consuming `CallInCall` state: remote peer top, local peer bottom. Each tile shows `HMSVideoView` when track is not null and not muted, else a `CircleAvatar` with name initial. Controls: mic toggle, video toggle, flip camera, red end-call button.
- **Output use**: Used as-is. The cross-file "Target of URI" error was a timing artifact from parallel file writes — resolved once `post_call_page.dart` existed on disk.
- **Commit**: `feat: 100ms call integration`
- **Notes**: `HMSVideoView` requires `setMirror: true` for the local track (front-camera selfie flip). Gradient overlay is `LinearGradient(bottomCenter → topCenter, black87 → transparent)` so it blends into the video without blocking the feed.

### Entry 8 — Phase 5: PreJoinPage permissions + mic/cam toggles
- **Tool**: Claude Code
- **Time**: ~2026-05-22 16:30
- **Phase**: 5
- **Intent**: Build the pre-join screen that fires `PrepareJoin` on create, requests permissions, shows mic/cam toggles, and navigates to `InCallPage` when `CallJoining` is emitted.
- **Prompt summary**: Asked for `PreJoinPage` as a `StatelessWidget` that creates `CallBloc` and dispatches `PrepareJoin` in one step, shows a spinner during `CallPreparing`, a form during `CallPreJoin`, and uses `BlocListener` to push `InCallPage` on `CallJoining` via `BlocProvider.value` so the same bloc instance is shared.
- **Output use**: Adapted. Hit a Dart type-promotion edge case: switch expression pattern `CallPreJoin() => _PreJoinBody(state: state as CallPreJoin)` triggered "unnecessary cast" because Dart promotes `state` to `CallPreJoin` after matching. Fixed to `_PreJoinBody(state: state)`.
- **Commit**: `feat: 100ms call integration`
- **Notes**: `BlocProvider.value` is critical here — it hands the existing `CallBloc` instance to `InCallPage` rather than creating a new one. Using `Navigator.pushReplacement` means the pre-join page is removed from the stack; back-nav from in-call lands back at requests.

### Entry 7 — Phase 5: CallBloc state machine + CallService stream wiring
- **Tool**: Claude Code
- **Time**: ~2026-05-22 16:00
- **Phase**: 5
- **Intent**: Build the full `CallBloc` state machine that subscribes to all `CallService` streams in its constructor, drives the call lifecycle from permission check through session log POST, and persists pre-join context across the `CallJoining` state (which has no data fields).
- **Prompt summary**: Asked for `CallBloc` with sealed events/states matching the spec: `PrepareJoin` fetches permissions then POSTs `/token`; `JoinNow` calls `callService.join()`; private `_Joined`, `_Left`, `_PeerUpdated`, `_TrackUpdated`, `_Reconnecting`, `_Reconnected`, `_SdkError` events wired from stream subscriptions; `_Left` POSTs session log and emits `CallEnded`.
- **Output use**: Adapted. The `CallJoining` state has no fields, so pre-join context (callRequestId, memberId, trainerId, userId) would be lost when `_Joined` fired. Solved by stashing those fields in nullable instance variables in `onChange()` when the state transitions to `CallJoining`, then clearing them after `_onJoined` reads them.
- **Commit**: `feat: 100ms call integration`
- **Notes**: `HMSVideoTrack` is a subtype of `HMSTrack` — checking `e.track is HMSVideoTrack` before casting is required since audio tracks also arrive via `onTrackUpdate`. The `copyWith` on `CallInCall` uses `HMSVideoTrack? Function()?` for nullable track fields so callers can explicitly null them (muted video) vs leave them unchanged (null means "don't update").

### Entry 6 — Phase 3: real-time chat end-to-end (ChatService + ChatBloc + UI)
- **Tool**: Claude Code
- **Time**: ~2026-05-22 14:30
- **Phase**: 3
- **Intent**: Generate the entire chat feature: polling ChatService, ChatBloc with sealed events/states, ChatListBloc, ConversationPage, MessageBubble, TypingIndicator, ChatListPage, and all wiring into both apps.
- **Prompt summary**: Asked to implement Phase 3 from task.md and phase_3_chat.md: thin ChatService with 1.5s polling fallback, ChatBloc (optimistic send + auto mark-read + typing state), all UI (bubbles, ticks, typing dots, quick replies, empty state), ChatListBloc for the single conversation row. Put everything in shared to avoid duplication.
- **Output use**: Adapted. Two issues found during generation: (1) `typing_indicator.dart` used `__` double-underscore in builder lambda — IDE lint flagged it, changed to `_`; (2) `conversation_page.dart` had an unused `models/message.dart` import — removed. Also added braces to the `for` loop in `dispose()` per lints. Final `dart analyze`: No issues on all 3 packages.
- **Commit**: `feat: real-time chat with status ticks and typing indicator`
- **Notes**: Chose polling-only over SSE client — api_contract.md explicitly notes "if you can avoid SSE entirely and just poll, that's even better." The `ChatService.startPolling()` tracks a `_since` cursor advancing per message so the poll window never grows stale. Optimistic send uses a `tmp_` prefixed ID that gets replaced in-place when the server ack arrives. `MarkRead` is called both on screen open (via BlocListener) and on each `MessageReceived` event for the current user.

### Entry 1 — Phase-wise plan from spec docs
- **Tool**: Claude Code
- **Time**: ~2026-05-22 10:00
- **Phase**: 0
- **Intent**: Parse all 10 spec documents and produce a structured 8-phase build plan with per-task breakdowns, rubric mapping, and cut-order strategy.
- **Prompt summary**: Provided all files in `.claude/` (CLAUDE.md, project_spec.md, architecture.md, api_contract.md, bloc_patterns.md, backend_spec.md, hms_integration.md, task.md, progress.md, ai_ledger_template.md) and asked for a comprehensive phase-wise plan stored as individual markdown files under `files/plans/`.
- **Output use**: Used as-is. Plan files written directly to `files/plans/phase_N_*.md`.
- **Commit**: `chore: initial scaffold of two apps + shared package + token server`
- **Notes**: The plan correctly identified 100ms as the highest-risk phase (25 pts) and established the cut order: bonuses → polish → scheduler edge cases → onboarding animations. Never cut chat, 100ms join, session log, AI_LEDGER.

### Entry 4 — Token server: Express routes + in-memory store + SSE fan-out
- **Tool**: Claude Code
- **Time**: ~2026-05-22 13:00
- **Phase**: 2
- **Intent**: Generate the full Node.js token server: store.js with debounced persistence, hms.js for JWT minting, 5 route files (events, messages, call_requests, session_logs, token), and the Express entry point.
- **Prompt summary**: Asked to implement all Phase 2 server tasks: in-memory store with JSON persistence, HMS JWT minting with fallback, SSE client map with heartbeat, full CRUD routes with SSE fan-out, past-time + conflict validation on call requests, system messages on approve/decline.
- **Output use**: Used as-is. Node.js syntax check (`node --check`) passed. cURL smoke test verified: /health, /users, POST /messages, GET /messages all returned correct JSON. /token correctly returns 503 when credentials not configured.
- **Commit**: `feat: token server + sealed ApiClient`
- **Notes**: SSE `emit()` is a named export alongside the router — this avoids a global singleton module issue where messages.js and call_requests.js both need to fan out events. The 30-min conflict window check uses `Math.abs` so overlaps from either direction are caught.

### Entry 5 — Dart ApiClient: sealed ApiResponse per api_contract.md
- **Tool**: Claude Code
- **Time**: ~2026-05-22 13:00
- **Phase**: 2
- **Intent**: Implement the exact ApiClient from api_contract.md spec — one HTTP class, sealed response, no model parsing inside.
- **Prompt summary**: Asked to copy and adapt the api_contract.md code verbatim into shared/lib/services/api_client.dart and wire a base URL singleton in both apps via --dart-define.
- **Output use**: Used verbatim from spec. Added smoke-test FAB to TrainerApp HomeScreen guarded by `kDebugMode`.
- **Commit**: `feat: token server + sealed ApiClient`
- **Notes**: `dart analyze` clean on all 3 packages. The singleton `apiClient` in `core/constants.dart` per-app reads `API_BASE_URL` from dart-define at compile time — no runtime lookup needed.

### Entry 3 — Auth + Onboarding BLoC scaffold for both apps
- **Tool**: Claude Code
- **Time**: ~2026-05-22 11:00
- **Phase**: 1
- **Intent**: Generate AuthService (Hive-backed), LoginBloc for Trainer, OnboardingBloc for Guru, home screens, themes, and AppBarWithRole widget for both apps.
- **Prompt summary**: Asked to execute Phase 1 from task.md: AuthService with seed/login/currentUser, LoginBloc with sealed events+states, OnboardingBloc with 3-step flow, themed home screens, role badge AppBar.
- **Output use**: Adapted. IDE diagnostics caught two issues mid-generation: (1) `login_state.dart` part file referenced `User` before its parent `login_bloc.dart` was written — resolved by writing the bloc file with imports first; (2) unused `name` variable in destructured switch pattern in `onboarding_screen.dart` — removed from pattern. Also caught that `guru_app/lib/shared/widgets/app_bar_with_role.dart` needed to be its own file separate from trainer_app.
- **Commit**: `feat: auth + onboarding flows for both apps`
- **Notes**: `dart analyze lib/` clean on all 3 packages after fixes. Sealed class switch patterns require exhaustive matching — used `case OnboardingSlide1():` style for Dart 3 compatibility. The `_RootPage` in both app.dart files reads Hive on build to decide login vs home — no async gap because `AuthService.init()` is awaited in `main()` before `runApp`.

### Entry 2 — Scaffold repo, pubspec files, and data models
- **Tool**: Claude Code
- **Time**: ~2026-05-22 10:20
- **Phase**: 0
- **Intent**: Generate the complete Phase 0 scaffold: git init, .gitignore, three Flutter projects (shared package + guru_app + trainer_app), token_server npm init, all pubspec.yaml files wired with path dependency, and 5 data models with fromJson/toJson/copyWith/Equatable.
- **Prompt summary**: Asked to execute Phase 0 from task.md step by step: flutter create, npm init, write pubspec files with correct deps (flutter_bloc, equatable, hive, hmssdk_flutter, etc.), then write all 5 models (User, Message, CallRequest, SessionLog, RoomMeta) and the tagged ring-buffer logger.
- **Output use**: Adapted. The `shared/pubspec.yaml` initially had `name: shared` — changed to `name: wtf_shared` to match the path dependency name in the app pubspecs. The `wtf_shared.dart` barrel file had an unnecessary `library` directive that `dart analyze` flagged — removed it.
- **Commit**: `chore: initial scaffold of two apps + shared package + token server`
- **Notes**: `dart analyze lib/` came back clean after the library directive fix. All three `flutter pub get` calls resolved successfully. The `wtf_shared` path dep is resolved from both apps correctly.
