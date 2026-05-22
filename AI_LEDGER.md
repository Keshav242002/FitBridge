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

### Entry 2 — Scaffold repo, pubspec files, and data models
- **Tool**: Claude Code
- **Time**: ~2026-05-22 10:20
- **Phase**: 0
- **Intent**: Generate the complete Phase 0 scaffold: git init, .gitignore, three Flutter projects (shared package + guru_app + trainer_app), token_server npm init, all pubspec.yaml files wired with path dependency, and 5 data models with fromJson/toJson/copyWith/Equatable.
- **Prompt summary**: Asked to execute Phase 0 from task.md step by step: flutter create, npm init, write pubspec files with correct deps (flutter_bloc, equatable, hive, hmssdk_flutter, etc.), then write all 5 models (User, Message, CallRequest, SessionLog, RoomMeta) and the tagged ring-buffer logger.
- **Output use**: Adapted. The `shared/pubspec.yaml` initially had `name: shared` — changed to `name: wtf_shared` to match the path dependency name in the app pubspecs. The `wtf_shared.dart` barrel file had an unnecessary `library` directive that `dart analyze` flagged — removed it.
- **Commit**: `chore: initial scaffold of two apps + shared package + token server`
- **Notes**: `dart analyze lib/` came back clean after the library directive fix. All three `flutter pub get` calls resolved successfully. The `wtf_shared` path dep is resolved from both apps correctly.
