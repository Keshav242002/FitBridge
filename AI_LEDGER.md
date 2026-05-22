# AI Ledger — WTF Flutter Assessment

This file is required evidence of AI-native workflow. Every meaningful use of an AI tool during this build is logged here with prompt intent, output, and how it was used in the codebase.

**Tools used**: Claude Code (primary).

**Authenticity note**: Outputs were rarely used verbatim. Most entries describe adaptation, debugging, or guided generation. Where output was rejected, the entry explains why.

---

### Entry 1 — Phase-wise plan from spec docs
- **Tool**: Claude Code
- **Time**: ~2026-05-22 10:00
- **Phase**: 0
- **Intent**: Parse all 10 spec documents and produce a structured 8-phase build plan with per-task breakdowns, rubric mapping, and cut-order strategy.
- **Prompt summary**: Provided all files in `.claude/` (CLAUDE.md, project_spec.md, architecture.md, api_contract.md, bloc_patterns.md, backend_spec.md, hms_integration.md, task.md, progress.md, ai_ledger_template.md) and asked for a comprehensive phase-wise plan stored as individual markdown files under `files/plans/`.
- **Output use**: Used as-is. Plan files written directly to `files/plans/phase_N_*.md`.
- **Commit**: `chore: initial scaffold of two apps + shared package + token server`
- **Notes**: The plan correctly identified 100ms as the highest-risk phase (25 pts) and established the cut order: bonuses → polish → scheduler edge cases → onboarding animations. Never cut chat, 100ms join, session log, AI_LEDGER.

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
