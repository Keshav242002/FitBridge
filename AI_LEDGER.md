# AI Ledger — WTF Flutter Assessment

This file is required evidence of AI-native workflow. Every meaningful use of an AI tool during this build is logged here with prompt intent, output, and how it was used in the codebase.

**Tools used**: Claude Code (primary).

**Authenticity note**: Outputs were rarely used verbatim. Most entries describe adaptation, debugging, or guided generation. Where output was rejected, the entry explains why.

---

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
