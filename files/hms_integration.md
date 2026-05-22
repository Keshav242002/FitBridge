# hms_integration.md — 100ms Integration Playbook

> Source: https://www.100ms.live/docs/flutter/v2/quickstart/quickstart
>
> This is the riskiest part of the build. Read this before touching any RTC code.

---

## 1. Dependencies

In **both** `guru_app/pubspec.yaml` and `trainer_app/pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  hmssdk_flutter: ^1.10.7      # check pub.dev for latest at session start
  permission_handler: ^11.0.0
```

Then `flutter pub get` in both.

---

## 2. Platform permissions

### Android — `android/app/src/main/AndroidManifest.xml`

Add inside the `<manifest>` element, before `<application>`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<uses-permission android:name="android.permission.READ_PHONE_NUMBERS" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PROJECTION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CAMERA" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MICROPHONE" />
```

### Android — `android/app/build.gradle`

```groovy
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21       // MANDATORY for hmssdk_flutter
        targetSdkVersion 34
    }
}
```

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSCameraUsageDescription</key>
<string>Guru needs camera access for video calls with your trainer.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Guru needs microphone access for voice during calls.</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Guru uses your local network for video call connectivity.</string>
<key>NSBluetoothAlwaysUsageDescription</key>
<string>Guru needs Bluetooth to connect to your audio devices.</string>
```

(Substitute "Trainer" for "Guru" in trainer_app's plist strings.)

### iOS — `ios/Podfile`

```ruby
platform :ios, '12.0'    # MANDATORY

# inside post_install do |installer| ... target.build_configurations.each
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
  '$(inherited)',
  'PERMISSION_CAMERA=1',
  'PERMISSION_MICROPHONE=1',
  'PERMISSION_BLUETOOTH=1',
]
```

---

## 3. Request runtime permissions

Wrap the join flow with a permission gate. Put this in `shared/lib/services/call_service.dart`:

```dart
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

Future<bool> ensureCallPermissions() async {
  if (Platform.isIOS) {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return cam.isGranted && mic.isGranted;
  }
  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.bluetoothConnect.request();

  return (await Permission.camera.isGranted) &&
         (await Permission.microphone.isGranted);
}
```

Call this from the Pre-Join page **before** showing the camera preview. If it returns false, show an error state with a "Open Settings" button (`openAppSettings()`).

---

## 4. The `CallService` wrapper

This is the only place `hmssdk_flutter` is imported. Everywhere else uses streams from this service.

```dart
// shared/lib/services/call_service.dart

import 'dart:async';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import '../utils/logger.dart';

class CallService implements HMSUpdateListener {
  late HMSSDK _sdk;
  bool _built = false;

  final _onJoinedCtrl = StreamController<HMSRoom>.broadcast();
  final _onPeerUpdateCtrl = StreamController<({HMSPeer peer, HMSPeerUpdate update})>.broadcast();
  final _onTrackUpdateCtrl = StreamController<({HMSPeer peer, HMSTrack track, HMSTrackUpdate update})>.broadcast();
  final _onReconnectingCtrl = StreamController<void>.broadcast();
  final _onReconnectedCtrl = StreamController<void>.broadcast();
  final _onErrorCtrl = StreamController<HMSException>.broadcast();
  final _onLeftCtrl = StreamController<void>.broadcast();

  Stream<HMSRoom> get onJoined => _onJoinedCtrl.stream;
  Stream<({HMSPeer peer, HMSPeerUpdate update})> get onPeerUpdate => _onPeerUpdateCtrl.stream;
  Stream<({HMSPeer peer, HMSTrack track, HMSTrackUpdate update})> get onTrackUpdate => _onTrackUpdateCtrl.stream;
  Stream<void> get onReconnecting => _onReconnectingCtrl.stream;
  Stream<void> get onReconnected => _onReconnectedCtrl.stream;
  Stream<HMSException> get onError => _onErrorCtrl.stream;
  Stream<void> get onLeft => _onLeftCtrl.stream;

  Future<void> _ensureBuilt() async {
    if (_built) return;
    _sdk = HMSSDK();
    await _sdk.build();   // CRITICAL — must await
    _sdk.addUpdateListener(listener: this);
    _built = true;
  }

  Future<void> join({required String token, required String userName}) async {
    Log.rtc('joining as $userName');
    await _ensureBuilt();
    await _sdk.join(config: HMSConfig(authToken: token, userName: userName));
  }

  Future<void> toggleMic() async {
    final muted = await _sdk.isAudioMute(peer: null);
    await _sdk.switchAudio(isOn: muted ?? false);
  }

  Future<void> toggleVideo() async {
    final muted = await _sdk.isVideoMute(peer: null);
    await _sdk.switchVideo(isOn: muted ?? false);
  }

  Future<void> flipCamera() async => _sdk.switchCamera();

  Future<void> leave() async {
    Log.rtc('leaving');
    await _sdk.leave();
    _onLeftCtrl.add(null);
  }

  // ===== HMSUpdateListener implementations =====
  @override void onJoin({required HMSRoom room}) { Log.rtc('onJoin room=${room.id}'); _onJoinedCtrl.add(room); }
  @override void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) { _onPeerUpdateCtrl.add((peer: peer, update: update)); }
  @override void onTrackUpdate({required HMSTrack track, required HMSTrackUpdate trackUpdate, required HMSPeer peer}) { _onTrackUpdateCtrl.add((peer: peer, track: track, update: trackUpdate)); }
  @override void onReconnecting() { Log.rtc('onReconnecting'); _onReconnectingCtrl.add(null); }
  @override void onReconnected() { Log.rtc('onReconnected'); _onReconnectedCtrl.add(null); }
  @override void onHMSError({required HMSException error}) { Log.rtc('error=${error.code} ${error.message}'); _onErrorCtrl.add(error); }
  @override void onAudioDeviceChanged({HMSAudioDevice? currentAudioDevice, List<HMSAudioDevice>? availableAudioDevice}) {}
  @override void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}
  @override void onChangeTrackStateRequest({required HMSTrackChangeRequest hmsTrackChangeRequest}) {}
  @override void onMessage({required HMSMessage message}) {}
  @override void onRemovedFromRoom({required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) { _onLeftCtrl.add(null); }
  @override void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}
  @override void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}
  @override void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}

  Future<void> dispose() async {
    await _onJoinedCtrl.close();
    await _onPeerUpdateCtrl.close();
    await _onTrackUpdateCtrl.close();
    await _onReconnectingCtrl.close();
    await _onReconnectedCtrl.close();
    await _onErrorCtrl.close();
    await _onLeftCtrl.close();
  }
}
```

> The exact method signatures (`switchAudio`, `switchVideo`, `isAudioMute`) may differ slightly by SDK version — verify against the installed version's API docs at `pub.dev/documentation/hmssdk_flutter/latest/`. If a method name has drifted, fix the wrapper, not the callers.

---

## 5. `CallBloc` skeleton

```dart
// features/call/bloc/call_bloc.dart

sealed class CallEvent extends Equatable {
  const CallEvent();
  @override List<Object?> get props => [];
}
final class PrepareJoin extends CallEvent {
  final String callRequestId;
  final String userId;
  final String userName;
  final UserRole role;
  const PrepareJoin({required this.callRequestId, required this.userId, required this.userName, required this.role});
  @override List<Object?> get props => [callRequestId, userId, userName, role];
}
final class JoinNow extends CallEvent { const JoinNow(); }
final class ToggleMic extends CallEvent { const ToggleMic(); }
final class ToggleVideo extends CallEvent { const ToggleVideo(); }
final class FlipCamera extends CallEvent { const FlipCamera(); }
final class EndCall extends CallEvent { const EndCall(); }
final class _PeerChanged extends CallEvent {
  final HMSPeer peer;
  final HMSPeerUpdate update;
  const _PeerChanged(this.peer, this.update);
  @override List<Object?> get props => [peer, update];
}
// ...similar private events for track/error/reconnect

sealed class CallState extends Equatable {
  const CallState();
  @override List<Object?> get props => [];
}
final class CallIdle extends CallState { const CallIdle(); }
final class CallPreparing extends CallState { const CallPreparing(); }
final class CallPreJoin extends CallState {
  final String token;
  final String roomId;
  const CallPreJoin({required this.token, required this.roomId});
  @override List<Object?> get props => [token, roomId];
}
final class CallJoining extends CallState { const CallJoining(); }
final class CallInCall extends CallState {
  final HMSPeer? localPeer;
  final HMSPeer? remotePeer;
  final HMSVideoTrack? localTrack;
  final HMSVideoTrack? remoteTrack;
  final bool isMicOn;
  final bool isVideoOn;
  final bool isReconnecting;
  final DateTime startedAt;
  const CallInCall({
    this.localPeer, this.remotePeer, this.localTrack, this.remoteTrack,
    required this.isMicOn, required this.isVideoOn, required this.isReconnecting,
    required this.startedAt,
  });
  CallInCall copyWith({...}) => ...;
  @override List<Object?> get props => [localPeer, remotePeer, localTrack, remoteTrack, isMicOn, isVideoOn, isReconnecting, startedAt];
}
final class CallEnded extends CallState {
  final int durationSec;
  final String sessionLogId;
  const CallEnded({required this.durationSec, required this.sessionLogId});
  @override List<Object?> get props => [durationSec, sessionLogId];
}
final class CallError extends CallState {
  final String message;
  const CallError({required this.message});
  @override List<Object?> get props => [message];
}
```

In `_onPrepareJoin`:
```dart
emit(const CallPreparing());
final res = await api.post('/token', body: {
  'userId': e.userId,
  'role': e.role == UserRole.trainer ? 'host' : 'guest',
  'callRequestId': e.callRequestId,
});
switch (res) {
  case ApiSuccess(:final body):
    final token = body['token'] as String;
    final roomId = body['hmsRoomId'] as String;
    emit(CallPreJoin(token: token, roomId: roomId));
  case ApiFailure(:final message):
    emit(CallError(message: message));
}
```

In `_onJoinNow`:
```dart
final cur = state;
if (cur is! CallPreJoin) return;
emit(const CallJoining());
await callService.join(token: cur.token, userName: userName);
// onJoined stream fires → handler dispatches a private event that emits CallInCall
```

Subscribe to all `CallService` streams in the Bloc constructor; cancel in `close()`.

---

## 6. UI: Pre-Join page

```dart
BlocConsumer<CallBloc, CallState>(
  listener: (ctx, state) {
    if (state is CallError) {
      // show snackbar
    }
  },
  builder: (ctx, state) {
    return Scaffold(
      appBar: const AppBarWithRole(),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Ready to join? Check mic and camera.', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            // local preview placeholder — for v1, skip live preview to save time,
            // show a Container with the user's initial as avatar
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ToggleChip(icon: Icons.mic, on: micOn, onTap: () => micOn = !micOn),
                _ToggleChip(icon: Icons.videocam, on: camOn, onTap: () => camOn = !camOn),
              ],
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: 'Join',
              onPressed: state is CallPreJoin ? () => ctx.read<CallBloc>().add(const JoinNow()) : null,
            ),
          ],
        ),
      ),
    );
  },
);
```

---

## 7. UI: In-Call page

The 100ms quickstart shows this pattern — adapt to two peers in a 1-column grid (top half remote, bottom half local). Critical widget:

```dart
HMSVideoView(track: track)   // never null and not muted
```

If the track is null or `isMute`, render a circular avatar with the peer's initial — same approach as the quickstart's `peerTile`.

Bottom control bar (use shared widgets):
- Mic toggle → dispatches `ToggleMic`
- Video toggle → dispatches `ToggleVideo`
- Flip camera → dispatches `FlipCamera`
- End call (red circle) → dispatches `EndCall`

Reconnect overlay: if `state.isReconnecting`, show a translucent overlay with `CircularProgressIndicator` and text "Reconnecting...".

---

## 8. Token server: minting a JWT

In `token_server/src/hms.js`:

```js
const jwt = require('jsonwebtoken');
const { v4: uuid } = require('uuid');

function signHmsToken({ userId, roomId, role }) {
  const accessKey = process.env.HMS_APP_ACCESS_KEY;
  const secret = process.env.HMS_APP_SECRET;
  if (!accessKey || !secret) {
    if (process.env.HMS_FALLBACK_TOKEN) return process.env.HMS_FALLBACK_TOKEN;
    throw new Error('HMS credentials not configured and no fallback token');
  }
  const payload = {
    access_key: accessKey,
    room_id: roomId,
    user_id: userId,
    role,
    type: 'app',
    version: 2,
    iat: Math.floor(Date.now() / 1000),
    nbf: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 24 * 60 * 60,
    jti: uuid(),
  };
  return jwt.sign(payload, secret, { algorithm: 'HS256' });
}
```

Room creation: for the timebox, use **one pre-created room from the 100ms dashboard** (`HMS_ROOM_ID` in `.env`). All calls use the same room. The reviewer just needs to see one call work — they're not going to schedule three concurrent calls. Document this in `DECISIONS.md` ADR-3.

If you have time and the management API works: create a fresh room per CallRequest approval via `POST https://api.100ms.live/v2/rooms`.

---

## 9. Things that will go wrong

| Issue | Symptom | Fix |
|-------|---------|-----|
| Forgot `await hmsSDK.build()` | `join` throws or silently no-ops | Always `await`. |
| Missing permissions | Black screen, no audio | Check Android manifest, iOS plist, request at runtime. |
| Wrong base URL on emulator | `POST /token` times out | Android emulator must use `10.0.2.2`, not `localhost`. |
| Token expired during demo | `onHMSError` with auth code | Re-mint by re-running `POST /token` and re-joining. Or refresh `.env` fallback token from dashboard. |
| Two apps joining same role | Both show same name, weird UI | Server must sign trainer as `host`, member as `guest`. Check the `role` param flow. |
| `HMSVideoView` not rendering | Black tile | Check the track is not null and `!isMute`. Use the quickstart's null-check pattern. |
| iOS simulator no video | Expected | iOS simulator doesn't have a real camera. Test on a real device for the demo. |
| Android emulator no video | Expected | Same — emulator camera is fake. The reviewer should run on a real device, document this in README. |

---

## 10. The fastest path to "it works in the demo"

If you're running low on time at Phase 5, this is the minimum to claim 100ms is integrated:

1. Server returns `HMS_FALLBACK_TOKEN` (dashboard token) for both roles.
2. Both apps join the same hardcoded room.
3. Both apps render `HMSVideoView` for each peer.
4. End-call button works.
5. Session log is written.

Skip: token refresh, reconnect overlay, role-based controls, pre-join camera preview.

This is **not** the target — go for the full thing. But know your fallback so you don't panic.
