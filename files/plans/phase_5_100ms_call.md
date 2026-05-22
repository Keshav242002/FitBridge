# Phase 5 — 100ms Call (3:45 – 5:00) ← Highest-value bucket (25 pts)

**Goal:** Both apps join the same 100ms room, see each other's video, controls work, session log auto-written on end.

## Platform Setup

| Task | Detail |
|------|--------|
| `5.1` | Android `AndroidManifest.xml`: INTERNET, CAMERA, RECORD_AUDIO, MODIFY_AUDIO_SETTINGS, BLUETOOTH family, FOREGROUND_SERVICE family |
| `5.2` | Android `build.gradle`: `minSdkVersion 21`, `compileSdk 34` |
| `5.3` | iOS `Info.plist`: NSCamera, NSMicrophone, NSLocalNetwork, NSBluetooth usage strings |
| `5.4` | iOS `Podfile`: `platform :ios, '12.0'` + `permission_handler` post_install preprocessor flags |

## Service + Bloc

| Task | Detail |
|------|--------|
| `5.5` | `shared/lib/services/call_service.dart`: wraps `HMSSDK`. Exposes streams `onJoined / onPeerUpdate / onTrackUpdate / onError / onReconnecting / onReconnected`. Always `await _sdk.build()` BEFORE adding listener |
| `5.6` | `ensureCallPermissions()`: requests camera + mic (+ bluetoothConnect on Android) before join |
| `5.7` | `CallBloc`: full state machine below |

## CallBloc State Machine
```
CallIdle → CallPreparing → CallPreJoin(token, roomId) → CallJoining → CallInCall(...) → CallEnded(durationSec, sessionLogId)
                                                                                       ↘ CallError(message)
```

States:
- `CallIdle`
- `CallPreparing` — fetching token
- `CallPreJoin(token, roomId)` — token ready, waiting for user to tap Join
- `CallJoining` — SDK joining
- `CallInCall(localPeer, remotePeer, localTrack, remoteTrack, isMicOn, isVideoOn, isReconnecting, startedAt)`
- `CallEnded(durationSec, sessionLogId)`
- `CallError(message)`

## Token Fetch + Join Flow

| Task | Detail |
|------|--------|
| `5.8` | "Join Call" tap → `PrepareJoin` event → `ApiClient.post('/token', {userId, role:'host'/'guest', callRequestId})` → on `ApiSuccess` emit `CallPreJoin(token, roomId)` |
| `5.9` | Pre-Join screen: copy **"Ready to join? Check mic and camera."**, mic/cam toggles, "Join" button (enabled only in `CallPreJoin` state) |

## In-Call UI

| Task | Detail |
|------|--------|
| `5.10` | In-Call page: 2-peer grid — `HMSVideoView(track)` for each; if track is null/muted show circular avatar with peer initial |
| `5.11` | Controls: mic toggle, video toggle, flip camera, red end-call button |
| `5.12` | Reconnect overlay: translucent `CircularProgressIndicator` + "Reconnecting..." if `isReconnecting` |
| `5.13` | Role enforcement: trainer = `host`, member = `guest` (set in 100ms template) |

## End Flow

| Task | Detail |
|------|--------|
| `5.14` | End call → capture `endedAt`, compute `durationSec = endedAt - startedAt`, `POST /session-logs` → navigate to post-call sheet |
| `5.15` | Post-call sheet (Guru): 5-star rating + optional note → `PATCH /session-logs/:id` with rating + memberNotes. Copy: **"Session saved to your logs."** |
| `5.16` | Post-call sheet (Trainer): notes field + "Mark as complete" → PATCH with trainerNotes |
| `5.17` | Edge: token expiry → catch `onHMSError`, re-fetch token once, retry join |
| `5.18` | Commit: `feat: 100ms call integration` + multiple AI_LEDGER entries |

## Critical SDK Gotchas
- `await hmsSDK.build()` MUST be called before `addUpdateListener` — if forgotten, `onJoin` never fires
- Permissions MUST be granted before `join` or you join muted with no video
- Use `HMSVideoView(track: track)` only when track is not null and not muted
- Android emulator / iOS simulator don't have real cameras — document in README

## Minimum Viable Demo (fallback if time runs short)
1. Server returns `HMS_FALLBACK_TOKEN` for both roles
2. Both apps join same hardcoded room
3. Both render `HMSVideoView` for each peer
4. End-call button works
5. Session log is written

## Required UI Copy
- Pre-join: **"Ready to join? Check mic and camera."**
- Post-call: **"Session saved to your logs."**
