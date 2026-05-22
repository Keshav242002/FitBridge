import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hmssdk_flutter/hmssdk_flutter.dart';

import '../../../models/user.dart';
import '../../../services/api_client.dart';
import '../../../services/call_service.dart';

part 'call_event.dart';
part 'call_state.dart';

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

  @override
  Future<void> close() async {
    await _joinedSub.cancel();
    await _leftSub.cancel();
    await _peerSub.cancel();
    await _trackSub.cancel();
    await _reconnectingSub.cancel();
    await _reconnectedSub.cancel();
    await _errorSub.cancel();
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
        emit(CallPreJoin(
          token: map['token'] as String,
          roomId: map['hmsRoomId'] as String,
          callRequestId: e.callRequestId,
          userId: e.userId,
          userName: e.userName,
          role: e.role,
          memberId: e.memberId,
          trainerId: e.trainerId,
        ));
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
        emit(s.copyWith(remotePeer: e.peer));
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
