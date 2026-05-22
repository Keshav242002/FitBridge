# Phase 4 — Scheduler (3:00 – 3:45)

**Goal:** DK requests a call → Aarav approves → both apps reflect status → system message in chat.

## Tasks

| Task | Detail |
|------|--------|
| `4.1` | `shared/lib/services/schedule_service.dart`: `POST /call-requests`, `PATCH /call-requests/:id`, `GET /call-requests?userId` via `ApiClient` |
| `4.2` | `ScheduleBloc` (Guru): events `LoadSlots / SelectSlot / SubmitRequest`. State carries selected date, slot, note |
| `4.3` | Schedule screen: next-3-day chips + 30-min time slot chips (08:00–21:30) + note `TextField(maxLength: 140)` + Primary CTA "Request Call" |
| `4.4` | Validation: past slot → inline error. Note > 140 chars → blocked at input level |
| `4.5` | Client-side conflict check: `GET /call-requests` for trainer, error "Slot already booked" if `approved` request overlaps |
| `4.6` | On submit success: toast **"Call requested. Waiting for trainer approval."** → navigate to My Requests |
| `4.7` | Trainer Requests screen: pending list with member name, time, note. Inline Approve / Decline buttons. Decline → reason modal |
| `4.8` | On Approve → PATCH → server creates `RoomMeta` + system chat message → Guru's `ChatBloc` shows **"Call approved for {date} {time}."** |
| `4.9` | On Decline → system message **"Call request declined. Reason: {text}."** |
| `4.10` | Upcoming Calls (both apps): "Join Call" enabled within 10 min of `scheduledFor` (or always if DevPanel "Allow joining calls anytime" toggle is on) |
| `4.11` | Unit test: `schedule_validator_test.dart` — `validate(past)` returns error; `validate(future)` returns ok |
| `4.12` | Commit: `feat: scheduling pipeline with approve/decline and conflict check` + AI_LEDGER entry |

## Required UI Copy
- Request sent: **"Call requested. Waiting for trainer approval."**
- Approved: **"Call approved for {date} {time}."**
- Declined: **"Call request declined. Reason: {text}."**

## Schedule Screen Layout
- Chip row: today / tomorrow / day after tomorrow
- 30-min slot chips: 08:00, 08:30, 09:00 ... 21:30
- Note TextField (maxLength: 140, shows character counter)
- Primary CTA: "Request Call"

## Conflict Logic
- Server returns 409 if trainer already has `approved` request within 30-min window
- Client pre-checks via GET before submitting to give immediate feedback
