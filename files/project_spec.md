# project_spec.md — Full Requirements (source of truth for what to build)

> Distilled from the WTF assignment PDF. If anything here conflicts with the PDF, the PDF wins — flag it in `progress.md` and ask the user.

---

## 1. Two apps, one repo

```
wtf_flutter_test/
├─ README.md                  # one-command run instructions
├─ AI_LEDGER.md               # ≥10 entries, AI-native proof
├─ ARCHITECTURE.md            # high-level diagrams and decisions
├─ DECISIONS.md               # ADR-style records: #1 state mgmt, #2 storage, #3 RTC
├─ DEMO_SCRIPT.md             # 3-min walkthrough plan
├─ .env.example               # placeholder secrets at root (mirrors token_server/.env.example)
├─ token_server/              # Node.js Express server (token + event bus)
│  ├─ src/index.js
│  ├─ src/routes/
│  ├─ .env.example
│  ├─ package.json
│  └─ README.md
├─ shared/                    # Dart package shared by both apps
│  ├─ lib/
│  │  ├─ models/              # User, Message, CallRequest, SessionLog, RoomMeta
│  │  ├─ services/            # ApiClient, ChatService, CallService, LogService, AuthService
│  │  ├─ widgets/             # reusable UI: AppBarWithRole, ChatBubble, TimeChip, etc.
│  │  └─ utils/               # theme, validators, extensions, logger
│  └─ pubspec.yaml
├─ guru_app/                  # Member app (DK)
│  ├─ lib/
│  ├─ test/
│  └─ pubspec.yaml
└─ trainer_app/               # Trainer app (Aarav)
   ├─ lib/
   ├─ test/
   └─ pubspec.yaml
```

`shared/` is a path-dependency Dart package. Both apps depend on it via:
```yaml
dependencies:
  wtf_shared:
    path: ../shared
```

---

## 2. Data models (must implement exactly these fields, add more if needed)

### User
```dart
class User {
  final String id;
  final UserRole role;           // trainer | member
  final String name;
  final String email;
  final String? avatarUrl;
  final String? assignedTrainerId;  // only for members
}
enum UserRole { trainer, member }
```

### Message
```dart
class Message {
  final String id;
  final String chatId;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime createdAt;
  final MessageStatus status;    // sending | sent | read
}
enum MessageStatus { sending, sent, read }
```

### CallRequest
```dart
class CallRequest {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final String note;                       // ≤ 140 chars
  final CallRequestStatus status;
  final String? declineReason;
}
enum CallRequestStatus { pending, approved, declined, cancelled }
```

### SessionLog
```dart
class SessionLog {
  final String id;
  final String memberId;
  final String trainerId;
  final DateTime startedAt;
  final DateTime endedAt;
  final int durationSec;
  final int? rating;             // 1-5
  final String? trainerNotes;
  final String? memberNotes;
}
```

### RoomMeta
```dart
class RoomMeta {
  final String id;
  final String callRequestId;
  final String hmsRoomId;
  final String hmsRoleMember;    // 100ms role name e.g. "guest"
  final String hmsRoleTrainer;   // e.g. "host"
}
```

All models:
- have `fromJson` / `toJson`
- are `@immutable` with `const` constructors where possible
- are stored as JSON in Hive (`Hive.openBox('messages')` etc.) and on the token server's `data.json`

---

## 3. Seeded data (must exist on first run)

- **Trainer**: `id: "tr_aarav"`, name `"Aarav"`, email `"aarav@wtf.local"`, role `trainer`.
- **Member**: `id: "mb_dk"`, name `"DK"`, email `"dk@wtf.local"`, role `member`, `assignedTrainerId: "tr_aarav"`.

Trainer App login form is pre-filled with Aarav's email. Guru App onboarding pre-fills "DK" as the name.

---

## 4. Screens — exact list

### Guru App (Member)
1. **Onboarding** (2 slides) — shown only on first run.
2. **Profile Setup** — name (prefilled "DK"), trainer picker (only Aarav for v1).
3. **Home** — 3 cards: "Chat with Trainer", "Schedule Call", "My Sessions".
4. **Chat List** (single conversation in v1, but list layout).
5. **Conversation** — bubble UI, typing indicator, status ticks, quick replies, sticky input.
6. **Schedule Call** — calendar (next 3 days) + 30-min slot chips + note field.
7. **My Requests** — list of CallRequests with status pills.
8. **Upcoming Calls** — entries with "Join Call" button when within 10 min of `scheduledFor`.
9. **Pre-Join Device Check** — camera preview, mic/cam toggles, "Join" CTA.
10. **In-Call** — 100ms grid, mute/video/flip/end controls.
11. **Post-Call Rating Sheet** — 1–5 stars + optional note.
12. **Sessions List** — chips for All / Last 7 days / This Month; tap for detail modal.

### Trainer App
1. **Login** (mock) — email + password (any password works).
2. **Home** — 4 tiles: Members, Chats, Requests, Sessions.
3. **Members** — list (just DK for v1) → tap to view profile.
4. **Chats** — chat list → conversation screen (same UI as Guru).
5. **Requests** — pending list with inline Approve / Decline; Decline opens reason modal.
6. **Upcoming Calls** — same as Guru side, with "Join Call" CTA.
7. **Pre-Join Device Check** — same.
8. **In-Call** — same, but with trainer role permissions.
9. **Post-Call Notes Sheet** — quick notes + "Mark as complete".
10. **Sessions List** — same filters.
11. **DevPanel** (floating ⋮ overlay) — env info, last 20 structured logs.

---

## 5. UX details that get graded

### Colors
- Trainer App primary: `#E50914` (red)
- Guru App primary: `#1769E0` (blue)
- Success `#12B76A`, Warning `#F79009`, Error `#D92D20`
- Neutral greys for backgrounds.

### Typography (Material 3 base)
- H1 24, H2 20, Body 14–16, semi-bold titles, regular body.

### Motion
- 150–250ms transitions.
- Slide-in for new chat bubbles.
- Subtle scale-down on button press.

### Required components
- AppBar with role badge ("Trainer • Aarav" / "Member • DK").
- Floating "+" FAB on chat list (in v1 it's a no-op or opens existing conversation).
- Sticky multiline input bar with send icon.
- Time chips in scheduler (30-min blocks).
- CTA hierarchy: Primary (filled), Secondary (outline), Tertiary (text-only).
- Skeleton loaders, empty states with illustration + CTA, error states with retry.

### Required copy (use verbatim)
- Empty chat: **"No messages yet. Start the conversation."**
- Request sent: **"Call requested. Waiting for trainer approval."**
- Approved: **"Call approved for {date} {time}."**
- Declined: **"Call request declined. Reason: {text}."**
- Pre-join: **"Ready to join? Check mic and camera."**
- Post-call: **"Session saved to your logs."**

---

## 6. The 9-step manual test (this is how the reviewer grades you)

Build to make this script pass:

1. Launch Trainer App, login as Aarav (seeded).
2. Launch Guru App, onboarding DK → assigned to Aarav.
3. DK sends "Hi Coach 👋" → Trainer sees unread badge, opens chat, replies.
4. DK schedules a call for "today 6:00 PM", note: "Macros review".
5. Trainer approves; DK sees system message in chat + entry in Upcoming Calls.
6. At +1 min (simulate "now" by allowing override), both tap **Join Call** → device check → connect.
7. Trainer toggles mute / video / flip; Member sees the changes smoothly.
8. End call → SessionLog written. DK rates 5★ + note; Trainer adds notes.
9. Open Sessions list → latest entry on top with rating + duration.

For step 6, since real-time-clock testing is painful, add a **debug toggle** in DevPanel: "Allow joining calls anytime" — bypasses the 10-min window check.

---

## 7. Quality gates (from the rubric)

| Gate | Notes |
|------|-------|
| Architecture & code quality (20pts) | Layers, naming, lint-clean, null-safety on |
| Chat UX & reliability (15pts) | Statuses, typing indicator, history, animations |
| Scheduler & workflow (10pts) | Conflict checks, past-time validation, clear UX |
| 100ms calls (25pts) | Real join/leave, role enforcement, reconnection, device toggles |
| Session logs & ratings (10pts) | Completeness, filters work |
| AI-native proof (10pts) | AI_LEDGER depth, real usage shown |
| Polish & DX (10pts) | Error states, DevPanel, README, demo video |

100ms is the biggest single bucket — do not under-invest there.

---

## 8. Automated tests (minimum)

Three unit tests required, more if time permits:

1. **`message_test.dart`** — `Message.fromJson(toJson(m)) == m` round-trip.
2. **`schedule_validator_test.dart`** — `validate(pastTime)` returns error; `validate(futureTime)` returns ok.
3. **`session_duration_test.dart`** — `SessionLog(startedAt: t, endedAt: t + 12m)` has `durationSec == 720`.

Plus a smoke widget test per app that boots the root and verifies the home screen renders.

---

## 9. Performance targets

- Cold start ≤ 2.5s on emulator (release mode).
- Chat send → render on peer ≤ 400ms (with the 1.5s poll, hit ~1.5s worst case; document as known compromise).
- RTC join ≤ 4s on a real network.
- 60fps scrolling on chat list (use `ListView.builder`, avoid expensive builds).

---

## 10. Observability

- Structured logger in `shared/utils/logger.dart`. Tags: `[AUTH]`, `[CHAT]`, `[RTC]`, `[SCHEDULE]`, `[API]`, `[STORE]`.
- DevPanel floating button (only visible in debug builds) opens a bottom sheet showing:
  - App build info (version, build mode)
  - Env vars (masked: `HMS_KEY_PREFIX=...****`)
  - Last 20 log lines from the in-memory ring buffer.
  - Buttons: "Copy logs", "Clear logs", "Allow joining calls anytime" toggle.

---

## 11. Security

- `.env.example` at repo root and in `token_server/`. Real `.env` is gitignored.
- 100ms management secrets only on the token server. Flutter never sees them.
- Tokens are short-lived; the server signs them per request.
- Mask secrets in logs (`abc123****`).

---

## 12. Bonuses (only if ahead of schedule, in priority order)

1. Local notifications scheduled for "10 min before call" reminders.
2. Image attachments in chat (image_picker + thumbnail bubble).
3. Offline send queue (write to local box, flush when server back).
4. Light / Dark theme toggle.
5. Export session summary as shareable text.

Anything not done → document in `progress.md` and `README.md` under "Known limitations".
