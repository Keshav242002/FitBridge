import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

import '../../../models/user.dart';
import '../../../services/api_client.dart';
import '../../../services/call_service.dart';
import '../../../utils/logger.dart';

part 'call_event.dart';
part 'call_state.dart';

/// Global reference to the active CallBloc so lifecycle observers can reach it.
CallBloc? activeCallBloc;

class CallBloc extends Bloc<CallEvent, CallState> {
  CallBloc({required this.api, required this.callService})
      : super(const CallIdle()) {
    on<PrepareJoin>(_onPrepareJoin);
    on<JoinNow>(_onJoinNow);
    on<ToggleMic>(_onToggleMic);
    on<ToggleVideo>(_onToggleVideo);
    on<FlipCamera>(_onFlipCamera);
    on<EndCall>(_onEndCall);
    on<_Joined>(_onJoined);
    on<_Left>(_onLeft);
    on<_PeerUpdated>(_onPeerUpdated);
    on<_TrackUpdated>(_onTrackUpdated);
    on<_Reconnecting>(_onReconnecting);
    on<_Reconnected>(_onReconnected);
    on<_SdkError>(_onSdkError);
    on<_AuthExpired>(_onAuthExpired);
    on<_PreviewTrackReceived>(_onPreviewTrack);
    on<_AudioDeviceChanged>(_onAudioDeviceChanged);
    on<AppBackgrounded>(_onAppBackgrounded);
    on<AppForegrounded>(_onAppForegrounded);

    _joinedSub = callService.joinedStream.listen((_) => add(const _Joined()));
    _leftSub = callService.leftStream.listen((_) => add(const _Left()));
    _peerSub = callService.peerUpdateStream
        .listen((e) => add(_PeerUpdated(e.peer, e.update)));
    _trackSub = callService.trackUpdateStream
        .listen((e) => add(_TrackUpdated(e.peer, e.track, e.update)));
    _reconnectingSub =
        callService.reconnectingStream.listen((_) => add(const _Reconnecting()));
    _reconnectedSub =
        callService.reconnectedStream.listen((_) => add(const _Reconnected()));
    _errorSub =
        callService.errorStream.listen((e) => add(_SdkError(e)));
    _authExpiredSub =
        callService.authExpiredStream.listen((_) => add(const _AuthExpired()));
    _previewTrackSub =
        callService.previewTrackStream.listen((t) => add(_PreviewTrackReceived(t)));
    _audioDeviceSub =
        callService.audioDeviceStream.listen((e) => add(_AudioDeviceChanged(e.current, e.available)));

    activeCallBloc = this;
  }

  final ApiClient api;
  final CallService callService;

  late final StreamSubscription<void> _joinedSub;
  late final StreamSubscription<void> _leftSub;
  late final StreamSubscription<({HMSPeer peer, HMSPeerUpdate update})> _peerSub;
  late final StreamSubscription<
      ({HMSPeer peer, HMSTrack track, HMSTrackUpdate update})> _trackSub;
  late final StreamSubscription<void> _reconnectingSub;
  late final StreamSubscription<void> _reconnectedSub;
  late final StreamSubscription<HMSException> _errorSub;
  late final StreamSubscription<void> _authExpiredSub;
  late final StreamSubscription<HMSVideoTrack?> _previewTrackSub;
  late final StreamSubscription<({HMSAudioDevice? current, List<HMSAudioDevice>? available})> _audioDeviceSub;

  int _authRetryCount = 0;

  @override
  Future<void> close() async {
    if (activeCallBloc == this) activeCallBloc = null;
    await _joinedSub.cancel();
    await _leftSub.cancel();
    await _peerSub.cancel();
    await _trackSub.cancel();
    await _reconnectingSub.cancel();
    await _reconnectedSub.cancel();
    await _errorSub.cancel();
    await _authExpiredSub.cancel();
    await _previewTrackSub.cancel();
    await _audioDeviceSub.cancel();
    await callService.dispose();
    return super.close();
  }

  Future<void> _onPrepareJoin(PrepareJoin e, Emitter<CallState> emit) async {
    emit(const CallPreparing());

    final granted = await ensureCallPermissions();
    if (!granted) {
      emit(const CallError(message: 'Camera and microphone permissions are required.'));
      return;
    }

    final hmsRole = e.role == UserRole.trainer.name ? 'host' : 'guest';
    final res = await api.post('/token', body: {
      'userId': e.userId,
      'role': hmsRole,
      'callRequestId': e.callRequestId,
    });

    switch (res) {
      case ApiSuccess(:final body):
        final map = body as Map<String, dynamic>;
        final token = map['token'] as String;
        emit(CallPreJoin(
          token: token,
          roomId: map['hmsRoomId'] as String,
          callRequestId: e.callRequestId,
          userId: e.userId,
          userName: e.userName,
          role: e.role,
          memberId: e.memberId,
          trainerId: e.trainerId,
        ));
        // Start camera preview
        try {
          await callService.startPreview(token: token, userName: e.userName);
        } catch (err) {
          Log.rtc('preview failed: $err');
          // Preview failure is non-fatal — user can still join
        }
      case ApiFailure(:final message):
        emit(CallError(message: message));
    }
  }

  Future<void> _onJoinNow(JoinNow e, Emitter<CallState> emit) async {
    final s = state;
    if (s is! CallPreJoin) return;
    emit(const CallJoining());
    await callService.join(token: s.token, userName: s.userName);
    // _Joined event will be fired by stream listener on onJoin callback
  }

  void _onJoined(_Joined e, Emitter<CallState> emit) {
    final s = state;
    // Pull context from the last known pre-join state
    if (s is! CallJoining) return;
    // We stash the context in the bloc field during PrepareJoin
    emit(CallInCall(
      callRequestId: _pendingCallRequestId!,
      memberId: _pendingMemberId!,
      trainerId: _pendingTrainerId!,
      userId: _pendingUserId!,
      startedAt: DateTime.now(),
    ));
    _clearPending();
  }

  Future<void> _onLeft(_Left e, Emitter<CallState> emit) async {
    final s = state;
    if (s is! CallInCall) return;

    final endedAt = DateTime.now();
    final durationSec = endedAt.difference(s.startedAt).inSeconds;

    final res = await api.post('/session-logs', body: {
      'memberId': s.memberId,
      'trainerId': s.trainerId,
      'callRequestId': s.callRequestId,
      'startedAt': s.startedAt.toIso8601String(),
      'endedAt': endedAt.toIso8601String(),
      'durationSec': durationSec,
    });

    switch (res) {
      case ApiSuccess(:final body):
        final sessionLogId =
            (body as Map<String, dynamic>)['id'] as String? ?? '';
        emit(CallEnded(
          durationSec: durationSec,
          sessionLogId: sessionLogId,
          memberId: s.memberId,
          trainerId: s.trainerId,
          userId: s.userId,
          callRequestId: s.callRequestId,
        ));
      case ApiFailure(:final message):
        emit(CallError(message: message));
    }
  }

  void _onToggleMic(ToggleMic e, Emitter<CallState> emit) {
    final s = state;
    if (s is CallPreJoin) {
      callService.toggleMic();
      emit(s.copyWith(isMicOn: !s.isMicOn));
    } else if (s is CallInCall) {
      callService.toggleMic();
      emit(s.copyWith(isMicOn: !s.isMicOn));
    }
  }

  void _onToggleVideo(ToggleVideo e, Emitter<CallState> emit) {
    final s = state;
    if (s is CallPreJoin) {
      callService.toggleVideo();
      emit(s.copyWith(isVideoOn: !s.isVideoOn));
    } else if (s is CallInCall) {
      callService.toggleVideo();
      emit(s.copyWith(isVideoOn: !s.isVideoOn));
    }
  }

  Future<void> _onFlipCamera(FlipCamera e, Emitter<CallState> emit) async {
    await callService.flipCamera();
  }

  Future<void> _onEndCall(EndCall e, Emitter<CallState> emit) async {
    final s = state;
    if (s is! CallInCall) return;
    await callService.leave();
    // _Left event fires via stream listener
  }

  void _onPeerUpdated(_PeerUpdated e, Emitter<CallState> emit) {
    final s = state;
    if (s is! CallInCall) return;

    if (e.peer.isLocal) {
      emit(s.copyWith(localPeer: e.peer));
    } else {
      if (e.update == HMSPeerUpdate.peerLeft) {
        emit(s.copyWith(
          remotePeer: e.peer,
          peerJustLeft: true,
          peerLeftName: () => e.peer.name,
        ));
      } else {
        emit(s.copyWith(remotePeer: e.peer));
      }
    }
  }

  void _onTrackUpdated(_TrackUpdated e, Emitter<CallState> emit) {
    final s = state;
    if (s is! CallInCall) return;
    if (e.track is! HMSVideoTrack) return;

    final videoTrack = e.track as HMSVideoTrack;
    final isMuted = videoTrack.isMute;

    if (e.peer.isLocal) {
      emit(s.copyWith(
        localVideoTrack: () => isMuted ? null : videoTrack,
      ));
    } else {
      emit(s.copyWith(
        remoteVideoTrack: () => isMuted ? null : videoTrack,
      ));
    }
  }

  void _onReconnecting(_Reconnecting e, Emitter<CallState> emit) {
    final s = state;
    if (s is CallInCall) emit(s.copyWith(isReconnecting: true));
  }

  void _onReconnected(_Reconnected e, Emitter<CallState> emit) {
    final s = state;
    if (s is CallInCall) emit(s.copyWith(isReconnecting: false));
  }

  void _onSdkError(_SdkError e, Emitter<CallState> emit) {
    emit(CallError(message: e.error.message ?? 'Call error'));
  }

  Future<void> _onAuthExpired(_AuthExpired e, Emitter<CallState> emit) async {
    final s = state;
    if (s is! CallInCall) return;

    _authRetryCount++;
    if (_authRetryCount > 1) {
      emit(const CallError(message: 'Authentication expired. Please rejoin the call.'));
      return;
    }

    Log.rtc('auth expired, attempting token refresh (attempt $_authRetryCount)');

    final hmsRole = s.userId == s.trainerId ? 'host' : 'guest';
    final res = await api.post('/token', body: {
      'userId': s.userId,
      'role': hmsRole,
      'callRequestId': s.callRequestId,
    });

    switch (res) {
      case ApiSuccess(:final body):
        final token = (body as Map<String, dynamic>)['token'] as String;
        final userName = s.localPeer?.name ?? s.userId;
        try {
          await callService.join(token: token, userName: userName);
          Log.rtc('token refresh successful, rejoined');
        } catch (err) {
          Log.rtc('rejoin after refresh failed: $err');
          emit(const CallError(message: 'Failed to reconnect after token refresh.'));
        }
      case ApiFailure(:final message):
        emit(CallError(message: 'Token refresh failed: $message'));
    }
  }

  void _onPreviewTrack(_PreviewTrackReceived e, Emitter<CallState> emit) {
    final s = state;
    if (s is CallPreJoin) {
      emit(s.copyWith(previewTrack: () => e.track));
    }
  }

  void _onAudioDeviceChanged(_AudioDeviceChanged e, Emitter<CallState> emit) {
    final s = state;
    if (s is CallInCall && e.current != null) {
      emit(s.copyWith(
        audioDeviceName: () => e.current?.name,
      ));
    }
  }

  void _onAppBackgrounded(AppBackgrounded e, Emitter<CallState> emit) {
    final s = state;
    if (s is CallInCall && s.isVideoOn) {
      callService.toggleVideo();
      emit(s.copyWith(isVideoOn: false, wasBackgrounded: true));
      Log.rtc('app backgrounded — video muted');
    }
  }

  void _onAppForegrounded(AppForegrounded e, Emitter<CallState> emit) {
    final s = state;
    if (s is CallInCall && s.wasBackgrounded) {
      callService.toggleVideo();
      emit(s.copyWith(isVideoOn: true, wasBackgrounded: false));
      Log.rtc('app foregrounded — video restored');
    }
  }

  // Stash fields to carry context from CallPreJoin → CallJoining → _Joined
  String? _pendingCallRequestId;
  String? _pendingMemberId;
  String? _pendingTrainerId;
  String? _pendingUserId;

  @override
  void onChange(Change<CallState> change) {
    super.onChange(change);
    if (change.nextState is CallJoining) {
      final prev = change.currentState;
      if (prev is CallPreJoin) {
        _pendingCallRequestId = prev.callRequestId;
        _pendingMemberId = prev.memberId;
        _pendingTrainerId = prev.trainerId;
        _pendingUserId = prev.userId;
      }
    }
  }

  void _clearPending() {
    _pendingCallRequestId = null;
    _pendingMemberId = null;
    _pendingTrainerId = null;
    _pendingUserId = null;
  }
}
