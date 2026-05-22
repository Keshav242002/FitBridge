# DEMO_SCRIPT.md — 3-Minute Walkthrough

**Target runtime:** 3 minutes  
**Setup before recording:** Token server running, both emulators side by side (Trainer on left, Guru/Member on right), DevPanel open on both apps.

---

## Before you hit record

1. `cd token_server && npm start` — confirm `hmsMode=jwt` (or `hmsMode=fallback`) in the terminal.
2. Launch Trainer App on Android emulator (left screen).
3. Launch Guru App on a second Android emulator or iOS simulator (right screen).
4. In both apps, open the DevPanel (⋮ button, debug builds only) and **enable "Allow joining calls anytime"** — this bypasses the 10-minute window check so you don't have to time the demo to a scheduled slot.

---

## Section 1 — Setup & Login (15 seconds)

**Narrate:** *"Two Flutter apps, one shared Node server, no cloud backend."*

- [Trainer App] Show login screen pre-filled with `aarav@wtf.local`. Enter any password and tap **Login**. Home screen appears (4 tiles: Members, Chats, Requests, Sessions).
- [Guru App] Show onboarding slides → Profile Setup (name prefilled "DK", trainer pre-assigned to Aarav) → tap **Get Started**. Home screen appears (3 cards).

---

## Section 2 — Real-time Chat (45 seconds)

**Narrate:** *"Chat is polling-based at 1.5s — no cloud, no WebSocket, just a local HTTP server."*

- [Guru App] Tap **Chat with Trainer** → **Say hi** CTA on empty state.
- Type **"Hi Coach 👋"** and tap send. Show the sent tick (✓).
- [Trainer App] Within ~1.5s, the Chats tile shows an unread badge. Tap **Chats** → open the conversation. Message appears with double tick (✓✓ read).
- [Trainer App] Tap a quick reply chip **"Got it 👍"** and send.
- [Guru App] Reply arrives, status updates to read. Show the typing indicator by starting to type in Trainer and showing the dots on Guru.

---

## Section 3 — Schedule & Approve (40 seconds)

**Narrate:** *"Scheduling with conflict detection and a full approve/decline workflow."*

- [Guru App] From home, tap **Schedule Call**.
  - Select **Today** date chip.
  - Tap the **6:00 PM** time slot.
  - Type note: **"Macros review"** (under 140 chars).
  - Tap **Request Call**. Toast: *"Call requested. Waiting for trainer approval."*
- [Trainer App] Tap **Requests** tile. The pending request appears (DK · Today 6:00 PM · "Macros review").
  - Tap **Approve**. 
- [Guru App] A system message appears in chat: *"Call approved for [today's date] 6:00 PM."* Switch to **My Requests** — status pill turns green (Approved).

---

## Section 4 — Join Call & In-Call Controls (60 seconds)

**Narrate:** *"100ms WebRTC — real room join, mute/video/flip controls, reconnect overlay."*

- [Guru App] Tap **My Requests** → tap **Join Call** on the approved entry. Pre-Join screen: *"Ready to join? Check mic and camera."* Toggle mic off, then on. Tap **Join**.
- [Trainer App] Tap **Requests** → **Upcoming Calls** tab → tap **Join Call**. Pre-Join screen shows for Aarav. Tap **Join**.
- Both apps enter the In-Call screen. Show 2-peer grid (remote top, local bottom with mirror).
- [Trainer App] Toggle **mute** (mic icon goes red). Show on Guru side that the audio indicator updates.
- [Trainer App] Toggle **video off**. Guru side shows a CircleAvatar fallback with Aarav's initial.
- [Trainer App] Tap **flip camera** — local feed switches to rear camera.
- Show the **reconnecting overlay** by briefly toggling airplane mode on one emulator (optional — skip if risky).

---

## Section 5 — End Call & Session Log (20 seconds)

**Narrate:** *"Session log auto-written on leave. Member rates, trainer adds notes."*

- [Trainer App] Tap the **red end button**. Both apps navigate to Post-Call screen.
- [Guru App] Rate **5 stars**, add note **"Great session!"**, tap **Done**. Toast: *"Session saved to your logs."*
- [Trainer App] Add trainer notes **"DK hit macros. Increase protein target next week."**, tap **Mark as complete**.
- [Guru App] Navigate to **My Sessions**. Latest entry at the top: today's date, duration (e.g. "1m 23s"), 5 gold stars.
- [Trainer App] Navigate to **Sessions**. Same entry visible. Tap to open detail modal — both sets of notes visible.

---

## Closing (5 seconds)

*"Built in 6 hours. BLoC throughout, zero cloud, full 100ms integration, AI-native workflow documented in AI_LEDGER.md."*

Stop recording.

---

## Troubleshooting the demo

| Issue | Fix |
|-------|-----|
| Apps can't reach server | Confirm `npm start` is running; check `--dart-define=API_BASE_URL` matches emulator type |
| 100ms token returns 503 | Fill in `HMS_APP_ACCESS_KEY` / `HMS_APP_SECRET` in `.env`, or set `HMS_FALLBACK_TOKEN` |
| Join Call button disabled | Enable "Allow joining calls anytime" in DevPanel (⋮ button) |
| Camera/mic not working | Grant permissions on the emulator via Settings → Apps → Permissions |
| Fallback token expired | Regenerate from 100ms dashboard; paste into `.env` as `HMS_FALLBACK_TOKEN` |
