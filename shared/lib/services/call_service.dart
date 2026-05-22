import 'dart:async';
import 'dart:io';

import 'package:hmssdk_flutter/hmssdk_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../utils/logger.dart';

Future<bool> ensureCallPermissions() async {
  if (Platform.isIOS) {
    final cam = await Permission.camera.request();
    final mic = await Permission.microphone.request();
    return cam.isGranted && mic.isGranted;
  }
  await Permission.camera.request();
  await Permission.microphone.request();
  await Permission.bluetoothConnect.request();
  return (await Permission.camera.isGranted) && (await Permission.microphone.isGranted);
}

class CallService implements HMSUpdateListener, HMSPreviewListener {
  late HMSSDK _sdk;
  bool _built = false;
  bool _previewing = false;

  final _joinedCtrl = StreamController<HMSRoom>.broadcast();
  final _peerUpdateCtrl =
      StreamController<({HMSPeer peer, HMSPeerUpdate update})>.broadcast();
  final _trackUpdateCtrl =
      StreamController<({HMSPeer peer, HMSTrack track, HMSTrackUpdate update})>.broadcast();
  final _reconnectingCtrl = StreamController<void>.broadcast();
  final _reconnectedCtrl = StreamController<void>.broadcast();
  final _errorCtrl = StreamController<HMSException>.broadcast();
  final _leftCtrl = StreamController<void>.broadcast();
  final _authExpiredCtrl = StreamController<void>.broadcast();
  final _previewTrackCtrl = StreamController<HMSVideoTrack?>.broadcast();
  final _audioDeviceCtrl =
      StreamController<({HMSAudioDevice? current, List<HMSAudioDevice>? available})>.broadcast();

  Stream<HMSRoom> get joinedStream => _joinedCtrl.stream;
  Stream<({HMSPeer peer, HMSPeerUpdate update})> get peerUpdateStream =>
      _peerUpdateCtrl.stream;
  Stream<({HMSPeer peer, HMSTrack track, HMSTrackUpdate update})> get trackUpdateStream =>
      _trackUpdateCtrl.stream;
  Stream<void> get reconnectingStream => _reconnectingCtrl.stream;
  Stream<void> get reconnectedStream => _reconnectedCtrl.stream;
  Stream<HMSException> get errorStream => _errorCtrl.stream;
  Stream<void> get leftStream => _leftCtrl.stream;
  Stream<void> get authExpiredStream => _authExpiredCtrl.stream;
  Stream<HMSVideoTrack?> get previewTrackStream => _previewTrackCtrl.stream;
  Stream<({HMSAudioDevice? current, List<HMSAudioDevice>? available})> get audioDeviceStream =>
      _audioDeviceCtrl.stream;

  Future<void> _ensureBuilt() async {
    if (_built) return;
    _sdk = HMSSDK();
    await _sdk.build();
    _built = true;
  }

  // ===== Preview API =====

  Future<void> startPreview({required String token, required String userName}) async {
    Log.rtc('starting preview as $userName');
    await _ensureBuilt();
    _previewing = true;
    _sdk.addPreviewListener(listener: this);
    await _sdk.preview(config: HMSConfig(authToken: token, userName: userName));
  }

  Future<void> stopPreview() async {
    if (!_previewing) return;
    Log.rtc('stopping preview');
    _previewing = false;
    _sdk.removePreviewListener(listener: this);
    _previewTrackCtrl.add(null);
  }

  // ===== HMSPreviewListener =====

  @override
  void onPreview({required HMSRoom room, required List<HMSTrack> localTracks}) {
    Log.rtc('onPreview localTracks=${localTracks.length}');
    for (final track in localTracks) {
      if (track is HMSVideoTrack) {
        _previewTrackCtrl.add(track);
        return;
      }
    }
    _previewTrackCtrl.add(null);
  }

  @override
  void onPeerUpdate({required HMSPeer peer, required HMSPeerUpdate update}) {
    _peerUpdateCtrl.add((peer: peer, update: update));
  }

  @override
  void onAudioDeviceChanged(
      {HMSAudioDevice? currentAudioDevice,
      List<HMSAudioDevice>? availableAudioDevice}) {
    Log.rtc('audioDeviceChanged: $currentAudioDevice');
    _audioDeviceCtrl.add((current: currentAudioDevice, available: availableAudioDevice));
  }

  @override
  void onRoomUpdate({required HMSRoom room, required HMSRoomUpdate update}) {}

  // ===== Join / Leave / Controls =====

  Future<void> join({required String token, required String userName}) async {
    Log.rtc('joining as $userName');
    if (_previewing) {
      _previewing = false;
      _sdk.removePreviewListener(listener: this);
    }
    await _ensureBuilt();
    _sdk.addUpdateListener(listener: this);
    await _sdk.join(config: HMSConfig(authToken: token, userName: userName));
  }

  Future<void> toggleMic() async => _sdk.toggleMicMuteState();

  Future<void> toggleVideo() async => _sdk.toggleCameraMuteState();

  Future<void> flipCamera() async => _sdk.switchCamera();

  Future<void> leave() async {
    Log.rtc('leaving');
    await _sdk.leave();
    _leftCtrl.add(null);
  }

  Future<void> dispose() async {
    if (_built) {
      _sdk.removeUpdateListener(listener: this);
    }
    await _joinedCtrl.close();
    await _peerUpdateCtrl.close();
    await _trackUpdateCtrl.close();
    await _reconnectingCtrl.close();
    await _reconnectedCtrl.close();
    await _errorCtrl.close();
    await _leftCtrl.close();
    await _authExpiredCtrl.close();
    await _previewTrackCtrl.close();
    await _audioDeviceCtrl.close();
  }

  // ===== HMSUpdateListener =====

  @override
  void onJoin({required HMSRoom room}) {
    Log.rtc('onJoin room=${room.id}');
    _joinedCtrl.add(room);
  }

  @override
  void onPeerListUpdate(
      {required List<HMSPeer> addedPeers, required List<HMSPeer> removedPeers}) {}

  @override
  void onTrackUpdate(
      {required HMSTrack track,
      required HMSTrackUpdate trackUpdate,
      required HMSPeer peer}) {
    _trackUpdateCtrl.add((peer: peer, track: track, update: trackUpdate));
  }

  @override
  void onReconnecting() {
    Log.rtc('onReconnecting');
    _reconnectingCtrl.add(null);
  }

  @override
  void onReconnected() {
    Log.rtc('onReconnected');
    _reconnectedCtrl.add(null);
  }

  @override
  void onHMSError({required HMSException error}) {
    Log.rtc('error code=${error.code?.errorCode} ${error.message}');
    if (_isAuthError(error)) {
      _authExpiredCtrl.add(null);
    } else {
      _errorCtrl.add(error);
    }
  }

  bool _isAuthError(HMSException e) {
    final code = e.code?.errorCode;
    return code == 1003 || code == 4005;
  }

  @override
  void onRemovedFromRoom(
      {required HMSPeerRemovedFromPeer hmsPeerRemovedFromPeer}) {
    Log.rtc('removedFromRoom');
    _leftCtrl.add(null);
  }

  @override
  void onSessionStoreAvailable({HMSSessionStore? hmsSessionStore}) {}

  @override
  void onChangeTrackStateRequest(
      {required HMSTrackChangeRequest hmsTrackChangeRequest}) {}

  @override
  void onMessage({required HMSMessage message}) {}

  @override
  void onRoleChangeRequest({required HMSRoleChangeRequest roleChangeRequest}) {}

  @override
  void onUpdateSpeakers({required List<HMSSpeaker> updateSpeakers}) {}
}
