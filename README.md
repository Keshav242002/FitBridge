# WTF Flutter Assessment — Trainer & Member Fitness Apps

Two Flutter apps (Trainer + Member/Guru) that communicate via a local Node.js event-bus/token server to deliver real-time chat, call scheduling, 100ms video calls, and session logging — all without a cloud backend.

---

## Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.x (stable channel) |
| Dart | 3.x (bundled with Flutter) |
| Node.js | 20+ |
| npm | 9+ |
| Android Studio | Hedgehog+ (for Android emulator) |
| Xcode | 15+ (for iOS simulator, macOS only) |

---

## Quick Start

### 1 — Token server (run first)

```bash
cd token_server
cp .env.example .env
# Open .env and fill in your 100ms credentials (see token_server/.env.example for fields)
npm install
npm start
```

Server listens on `http://localhost:8787`. You should see:

```
[SERVER] WTF token server running on :8787  (hmsMode=jwt)
```

### 2 — Guru App (Member — DK)

```bash
cd guru_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

> On iOS Simulator use `http://localhost:8787`.  
> On a real device on the same Wi-Fi, use the host machine's LAN IP, e.g. `http://192.168.1.x:8787`.

### 3 — Trainer App (Aarav)

```bash
cd trainer_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787
```

Run both simultaneously — the token server is the shared message bus.

---

## Seeded credentials

| App | Email | Password |
|-----|-------|----------|
| Trainer App | `aarav@wtf.local` | any |
| Guru App | *(onboarding sets name to "DK" automatically)* | — |

---

## Project structure

```
wtf/
├── README.md
├── AI_LEDGER.md          # AI-native workflow evidence (≥10 entries)
├── ARCHITECTURE.md       # Topology, Bloc layering, call lifecycle
├── DECISIONS.md          # ADR-1 BLoC, ADR-2 storage, ADR-3 100ms room
├── DEMO_SCRIPT.md        # 3-min walkthrough outline
├── .env.example          # Root-level placeholder (mirrors token_server/.env.example)
├── token_server/         # Node.js Express — token mint + event bus
│   ├── src/
│   │   ├── index.js
│   │   ├── store.js
│   │   ├── hms.js
│   │   └── routes/       # token, messages, call_requests, session_logs, events
│   ├── .env.example
│   └── package.json
├── shared/               # Dart package shared by both apps
│   ├── lib/
│   │   ├── models/       # User, Message, CallRequest, SessionLog, RoomMeta
│   │   ├── services/     # ApiClient, AuthService, ChatService, CallService, SessionService, ScheduleService
│   │   ├── features/     # chat/, schedule/, call/, sessions/ (Bloc + presentation)
│   │   ├── widgets/      # AppBarWithRole, SkeletonLoader, ErrorRetry, EmptyState, PrimaryButton, DevPanel
│   │   └── utils/        # logger, theme, validators
│   └── test/             # message_test, schedule_validator_test, session_duration_test
├── guru_app/             # Member app (DK)
│   └── lib/
│       ├── main.dart
│       ├── app.dart
│       ├── core/         # theme, constants, DI
│       └── features/     # auth/onboarding, home
└── trainer_app/          # Trainer app (Aarav)
    └── lib/
        ├── main.dart
        ├── app.dart
        ├── core/
        └── features/     # auth/login, home
```

---

## Rubric scoring map

| Category | Points | Where it lives |
|----------|-------:|----------------|
| Architecture & code quality | 20 | `shared/`, BLoC only, `dart analyze` clean, null-safety on |
| Chat UX & reliability | 15 | `shared/lib/features/chat/`, `token_server/src/routes/messages.js` |
| Scheduler & workflow | 10 | `shared/lib/features/schedule/`, `call_requests.js`, conflict check |
| 100ms calls | 25 | `shared/lib/services/call_service.dart`, `features/call/`, `token_server/src/routes/token.js` |
| Session logs & ratings | 10 | `shared/lib/features/sessions/`, `session_logs.js` |
| AI-native proof | 10 | `AI_LEDGER.md` — 14 entries covering all phases |
| Polish & DX | 10 | DevPanel, skeleton/error/empty states, README, demo script |

---

## Running tests

```bash
cd shared
flutter test
```

Unit tests: `message_test.dart`, `schedule_validator_test.dart`, `session_duration_test.dart` — all passing.

---

## Known limitations

| # | Limitation | Workaround / Plan |
|---|------------|-------------------|
| 1 | Chat latency ~500ms | Polling at 500ms; SSE client not implemented. Acceptable for demo. |
| 2 | 100ms fallback token expires in 2h | Regenerate `HMS_FALLBACK_TOKEN` from the 100ms dashboard if the demo runs long. |
| 3 | Token expiry retry capped at 1 | On second token expiry mid-call, user must rejoin. Documented in DECISIONS.md ADR-3. |
| 4 | Single conversation (Aarav ↔ DK) | v1 supports one trainer–member pair. ChatList UI is list-ready for multi-pair expansion. |
| 5 | Bonuses not implemented | Local notifications, image attachments, offline send queue, dark mode, session export all cut to meet timebox. |
| 6 | Real device requires manual LAN IP | Pass `--dart-define=API_BASE_URL=http://<host-lan-ip>:8787` when running on a physical device. |

