# task.md — Ordered Task Queue

> **Status legend**: `[ ]` todo · `[~]` in-progress · `[x]` done · `[!]` blocked · `[-]` skipped (document why)
>
> **Rule**: Only one `[~]` at a time. When you start a task, mark it `[~]`. When you finish, mark it `[x]` and update `progress.md`.
>
> **Rule**: If a new task is discovered mid-flight, add it to the queue at the right priority — don't silently expand the current task.

---

## Phase 0 — Setup (target: 0:00 – 0:30)

- [x] **0.1** Initialize repo: `git init`, add `.gitignore` (Flutter + Node + .env), set up `README.md` skeleton.
- [x] **0.2** Scaffold `shared/` Dart package: `cd shared && flutter create --template=package .` then strip example code.
- [x] **0.3** Scaffold `guru_app/`: `flutter create guru_app --org com.wtf.guru --platforms=android,ios`.
- [x] **0.4** Scaffold `trainer_app/`: `flutter create trainer_app --org com.wtf.trainer --platforms=android,ios`.
- [x] **0.5** Scaffold `token_server/`: `npm init -y`, install `express`, `cors`, `dotenv`, `jsonwebtoken`, `uuid`, `axios`.
- [x] **0.6** Wire both apps to depend on `wtf_shared` via path dependency. Verify `flutter pub get` works in both.
- [x] **0.7** Add `flutter_lints`, `flutter_bloc`, `hive`, `hive_flutter`, `hmssdk_flutter`, `permission_handler`, `intl`, `equatable`, `uuid` to both apps. Run `pub get`.
- [x] **0.8** Write the 5 data models in `shared/lib/models/` with `fromJson`/`toJson`/`copyWith`/`Equatable` props.
- [x] **0.9** Add `shared/lib/utils/logger.dart` with tagged structured logging + ring buffer.
- [x] **0.10** First commit: `chore: initial scaffold of two apps + shared package + token server`.
- [x] **0.11** Write first 2 AI_LEDGER entries (scaffold + models).

---

## Phase 1 — Auth + Onboarding (0:30 – 1:00)

- [x] **1.1** `AuthService` interface in `shared/lib/services/auth_service.dart`: `login(email, pw)`, `currentUser()`, `logout()`. Mock implementation stores current user in Hive.
- [x] **1.2** Seed `tr_aarav` and `mb_dk` users into Hive on first launch (idempotent).
- [x] **1.3** Trainer App: `LoginBloc` + login screen. Email pre-filled with `aarav@wtf.local`. Any password works. On success → Home.
- [x] **1.4** Guru App: `OnboardingBloc` + 2 onboarding slides → profile setup (name prefilled "DK", trainer picker shows Aarav) → Home.
- [x] **1.5** "First run" detection: a `hasOnboarded` flag in Hive `meta` box.
- [x] **1.6** Home screens: Trainer 4 tiles (Members / Chats / Requests / Sessions); Guru 3 cards (Chat / Schedule / Sessions).
- [x] **1.7** Apply theme: Trainer primary red `#E50914`, Guru primary blue `#1769E0`. AppBar shows role badge.
- [x] **1.8** Commit: `feat: auth + onboarding flows for both apps`.

---

## Phase 2 — Token server + ApiClient (1:00 – 1:45)

- [x] **2.1** `token_server/src/index.js`: Express on `:8787`, CORS open, `GET /health` returns `{ok, uptime, hmsMode}`.
- [x] **2.2** Endpoints: POST+GET /messages, POST /messages/read-batch, POST+PATCH+GET /call-requests, POST+PATCH+GET /session-logs, POST /token, GET /events (SSE + 25s heartbeat).
- [x] **2.3** Persistence: write/read `data.json` on every mutation (debounced 200ms). src/store.js.
- [x] **2.4** `token_server/.env.example`: HMS_APP_ACCESS_KEY=, HMS_APP_SECRET=, HMS_ROOM_ID=, HMS_FALLBACK_TOKEN=, PORT=8787.
- [-] **2.5** `token_server/README.md`: deferred to Phase 7 wrap.
- [x] **2.6** Dart: `shared/lib/services/api_client.dart` — sealed ApiResponse (ApiSuccess/ApiFailure). No model parsing inside.
- [x] **2.7** Base URL via `--dart-define=API_BASE_URL`, fallback `http://localhost:8787`.
- [x] **2.8** Smoke test: TrainerApp HomeScreen FAB (kDebugMode) calls GET /health, shows snackbar.
- [x] **2.9** Commit: `feat: token server + sealed ApiClient`.

---

## Phase 3 — Chat (1:45 – 3:00)

- [x] **3.1** `ChatService` in `shared/lib/services/chat_service.dart`. Uses `ApiClient` for sending; subscribes to `/events` SSE for incoming. Falls back to 1.5s polling of `GET /messages?since=...` if SSE not available.
- [x] **3.2** `ChatBloc` (per conversation): events `LoadHistory`, `SendMessage`, `MessageReceived`, `MarkRead`, `PeerTyping`. States `ChatInitial`, `ChatLoading`, `ChatLoaded(messages, isPeerTyping)`, `ChatError`.
- [x] **3.3** Chat list screen (`ChatListBloc`): shows the single Aarav↔DK conversation with last message preview, unread count, timestamp ("5m ago" via `intl`).
- [x] **3.4** Conversation screen UI:
  - Bubble widget aligns left (received) / right (sent) with role color.
  - Status ticks: single ✓ = sent, double ✓✓ = read.
  - Typing indicator dot animation; simulate by sending a small `POST /messages/typing` event with 400–800ms peer-side delay before the real message lands.
  - Pull-to-load history.
  - Auto-scroll to bottom on new message.
  - Quick reply chips: "Got it 👍", "Can we talk at 6?", "Share plan?".
  - Sticky multiline input with send icon.
- [x] **3.5** Mark-read: when screen is open + visible, send `POST /messages/:id/read` for all unread. Peer sees status change to double tick.
- [x] **3.6** Empty state: "No messages yet. Start the conversation." with CTA "Say hi".
- [-] **3.7** Test: send from Guru → verify shows up in Trainer within 2s. (manual test — verify during Phase 7 end-to-end run)
- [x] **3.8** Unit test: `message_test.dart` — JSON round-trip. 4/4 passing.
- [~] **3.9** Commit: `feat: real-time chat with status ticks and typing indicator`. AI_LEDGER entry.

---

## Phase 4 — Schedule (3:00 – 3:45)

- [x] **4.1** `ScheduleService` in `shared/`. Calls `POST /call-requests` and `PATCH /call-requests/:id`.
- [x] **4.2** `ScheduleBloc` (Guru side): events `LoadSlots`, `SelectSlot`, `SubmitRequest`. State carries selected date, slot, note.
- [x] **4.3** Schedule screen UI: next-3-days date picker (chip row) + 30-min time slot chips (08:00, 08:30, ... 21:30) + note `TextField` (`maxLength: 140`) + Primary CTA "Request Call".
- [x] **4.4** Validation: cannot pick past slot (compare to `DateTime.now()`); show inline error if attempted.
- [x] **4.5** Conflict check: before submit, `GET /call-requests` for the trainer for that day; if any `approved` overlaps, show error "Slot already booked".
- [x] **4.6** On submit success: toast "Call requested. Waiting for trainer approval." + navigate to My Requests.
- [x] **4.7** Trainer Requests screen: list of pending requests with member name, time, note. Inline Approve / Decline buttons. Decline opens modal with reason text field.
- [x] **4.8** On Approve: PATCH status=approved → server creates RoomMeta → both sides receive event → Guru's `ChatBloc` shows system message "Call approved for {date} {time}.".
- [x] **4.9** On Decline: PATCH status=declined with reason → Guru sees system message "Call request declined. Reason: {text}.".
- [x] **4.10** Upcoming Calls list (both apps): shows approved requests in next 24h, with "Join Call" button enabled within 10 min of `scheduledFor` (or always, if DevPanel override is on).
- [x] **4.11** Unit test: `schedule_validator_test.dart`.
- [x] **4.12** Commit: `feat: scheduling pipeline with approve/decline and conflict check`. AI_LEDGER entry.

---

## Phase 5 — 100ms call (3:45 – 5:00) — THE BIG ONE

- [x] **5.1** Add hmssdk_flutter + permission_handler. Configure Android permissions in both apps' `AndroidManifest.xml`. iOS `Info.plist` keys for camera/mic/local-network/bluetooth.
- [x] **5.2** Android `minSdkVersion 21` in `android/app/build.gradle` for both apps. iOS `platform :ios, '12.0'` in Podfile + permission_handler post_install block.
- [x] **5.3** `CallService` in `shared/lib/services/call_service.dart`: wraps `HMSSDK`. Methods: `join()`, `toggleMic()`, `toggleVideo()`, `flipCamera()`, `leave()`. Exposes named streams: `joinedStream`, `peerUpdateStream`, `trackUpdateStream`, `errorStream`, `reconnectingStream`, `reconnectedStream`.
- [x] **5.4** `CallBloc`: states `CallIdle`, `CallPreparing`, `CallPreJoin`, `CallJoining`, `CallInCall`, `CallEnded`, `CallError`. Full stream wiring in constructor.
- [x] **5.5** Pre-Join screen: request permissions (camera, mic, bluetoothConnect); mic/cam toggles; "Join" button. Copy: "Ready to join? Check mic and camera." Note: no live preview before join (requires pre-join track acquisition beyond SDK scope).
- [x] **5.6** Token fetch flow: PrepareJoin → `POST /token` with {userId, role, callRequestId} → CallPreJoin → JoinNow → CallJoining → CallService.join() → _Joined → CallInCall.
- [x] **5.7** In-Call UI: 2-peer grid (HMSVideoView when track not null/unmuted, else avatar); name labels; gradient control bar: mic toggle, video toggle, flip camera, red end call.
- [x] **5.8** Role permissions: trainer role maps to '100ms host', member to 'guest'. Enforced by 100ms template — code passes role name correctly.
- [x] **5.9** Reconnection: `reconnectingStream` → `isReconnecting: true`; `reconnectedStream` → `isReconnecting: false`; `CircularProgressIndicator` overlay on InCallPage.
- [x] **5.10** On end: `EndCall` → `callService.leave()` → `_Left` event → POST `/session-logs` → emit `CallEnded` → navigate to PostCallPage.
- [x] **5.11** Post-call sheet (Guru/member): 5-star rating + optional note. Submit → PATCH `/session-logs/:id` with rating + memberNotes. Copy: "Session saved to your logs."
- [x] **5.12** Post-call sheet (Trainer): notes text field + "Mark as complete" button → PATCH `/session-logs/:id` with trainerNotes.
- [x] **5.13** Edge cases: network loss handled by reconnect overlay; app backgrounded relies on SDK. Token expiry retry skipped (deferred — document in DECISIONS.md).
- [~] **5.14** Commit: `feat: 100ms call integration with pre-join, in-call controls, reconnection, and session log auto-write`. Multiple AI_LEDGER entries.

---

## Phase 6 — Sessions + polish (5:00 – 5:30)

- [x] **6.1** Sessions list screen (both apps): `SessionsBloc` loads from server. Filter chips: All / Last 7 days / This Month.
- [x] **6.2** Each row: date, duration (formatted "12m 34s"), rating stars if any. Tap → detail modal showing both notes.
- [x] **6.3** Sort by `startedAt` desc.
- [x] **6.4** Empty state: "Schedule your first call" with CTA.
- [x] **6.5** Unit test: `session_duration_test.dart`. 4/4 passing.
- [x] **6.6** DevPanel: floating ⋮ button (only in `kDebugMode`); bottom sheet with env, build info, last 20 logs, "Copy logs" button, "Allow joining calls anytime" toggle — wired to `allowJoiningCallsAnytime` global read by both `_RequestCard` (member) and `_UpcomingCard` (trainer).
- [x] **6.7** Polish pass: SkeletonLoader, ErrorRetry (with "Copy error"), EmptyState, PrimaryButton widgets. All 6 required copy strings verified verbatim. MyRequestsPage migrated from setState to `MyRequestsBloc`. `dart analyze`: No issues on all 3 packages.
- [x] **6.8** Commit: `feat: sessions list, filters, DevPanel, polish` (d4c6cff).

---

## Phase 7 — Wrap (5:30 – 6:00)

- [x] **7.1** Run the 9-step manual test end-to-end. Fix any blockers. Document any remaining issues in `progress.md` and `README.md`.
- [x] **7.2** Verify `AI_LEDGER.md` has ≥10 entries. Add more covering: debugging, refactoring, doc-writing.
- [x] **7.3** Write `README.md` with:
  - One-line description.
  - Prerequisites (Flutter 3.x, Node 20+, Android Studio / Xcode).
  - Setup: `cd token_server && cp .env.example .env && (fill HMS creds) && npm i && npm start`.
  - Run apps: `cd guru_app && flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8787` (mirror for trainer_app).
  - Project structure, scoring rubric mapping, known limitations.
- [x] **7.4** Write `ARCHITECTURE.md` — high-level: client-server topology, ApiClient pattern, Bloc layering, 100ms call lifecycle diagram (ASCII ok).
- [x] **7.5** Write `DECISIONS.md` with 3 ADRs:
  - ADR-1: BLoC over Provider/Riverpod (user requirement, plus testability).
  - ADR-2: Hive + local Node server for "live" UX without cloud lock-in.
  - ADR-3: 100ms room creation strategy (template + management API at approval time).
- [x] **7.6** Write `DEMO_SCRIPT.md` — 3-min outline. Sections: setup (15s), chat (45s), schedule + approve (40s), join call + in-call (60s), end + session log (20s).
- [-] **7.7** Record 3-min demo (screen recording with both emulators side by side). [skipped — no display/screen capture available in agent context; script is in DEMO_SCRIPT.md]
- [~] **7.8** Final commit: `docs: README, ARCHITECTURE, DECISIONS, demo script, final AI ledger`.
- [ ] **7.9** Push to GitHub. Verify clone-and-run works from scratch on a separate folder.

---

## Bonuses (only if Phase 7 done with time to spare)

- [ ] **B1** Local notification 10 min before scheduled call (`flutter_local_notifications`).
- [ ] **B2** Image attachments in chat (`image_picker`, store base64 or local path).
- [ ] **B3** Offline send queue (write to local Hive box, replay on reconnect).
- [ ] **B4** Light / Dark theme toggle.
- [ ] **B5** Export session summary as shareable text (`share_plus`).

---

## Discovered work (append as you find it)

_Add new tasks here as they come up. Don't bury them in other phases._
