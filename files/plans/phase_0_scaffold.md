# Phase 0 — Scaffold (0:00 – 0:30)

**Goal:** Repo skeleton boots. All three processes can start.

## Tasks

| Task | Detail |
|------|--------|
| `0.1` | `git init`, `.gitignore` covering Flutter + Node + `.env` |
| `0.2` | `flutter create --template=package shared/` — strip boilerplate |
| `0.3` | `flutter create guru_app --org com.wtf.guru --platforms=android,ios` |
| `0.4` | `flutter create trainer_app --org com.wtf.trainer --platforms=android,ios` |
| `0.5` | `npm init` token_server, install `express cors dotenv jsonwebtoken uuid` |
| `0.6` | Wire both apps to `wtf_shared` via path dep; `flutter pub get` passes |
| `0.7` | Add `flutter_bloc equatable hive hive_flutter hmssdk_flutter permission_handler intl uuid flutter_lints` to both apps |
| `0.8` | Write all 5 models in `shared/lib/models/`: `User`, `Message`, `CallRequest`, `SessionLog`, `RoomMeta` — each with `fromJson/toJson/copyWith/Equatable props/@immutable` |
| `0.9` | `shared/lib/utils/logger.dart` — tagged structured logger + 20-entry ring buffer |
| `0.10` | Commit: `chore: initial scaffold` + first 2 AI_LEDGER entries |

## Deliverables
- `flutter pub get` passes in both apps
- `npm start` in token_server starts without crash
- All 5 data models compile with `fromJson`/`toJson`
- Logger available with tags: `[AUTH]`, `[CHAT]`, `[RTC]`, `[SCHEDULE]`, `[API]`, `[STORE]`

## Hard check
`flutter pub get` passes in both apps; `npm start` doesn't crash.
