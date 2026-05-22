part of 'call_bloc.dart';

sealed class CallEvent extends Equatable {
  const CallEvent();
  @override
  List<Object?> get props => [];
}

final class PrepareJoin extends CallEvent {
  const PrepareJoin({
    required this.callRequestId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.memberId,
    required this.trainerId,
  });

  final String callRequestId;
  final String userId;
  final String userName;
  final String role;
  final String memberId;
  final String trainerId;

  @override
  List<Object?> get props =>
      [callRequestId, userId, userName, role, memberId, trainerId];
}

final class JoinNow extends CallEvent {
  const JoinNow();
}

final class ToggleMic extends CallEvent {
  const ToggleMic();
}

final class ToggleVideo extends CallEvent {
  const ToggleVideo();
}

final class FlipCamera extends CallEvent {
  const FlipCamera();
}

final class EndCall extends CallEvent {
  const EndCall();
}

// Private stream-driven events — extend CallEvent (inherits Equatable via base)
final class _PeerUpdated extends CallEvent {
  const _PeerUpdated(this.peer, this.update);
  final HMSPeer peer;
  final HMSPeerUpdate update;
  @override
  List<Object?> get props => [peer, update];
}

final class _TrackUpdated extends CallEvent {
  const _TrackUpdated(this.peer, this.track, this.update);
  final HMSPeer peer;
  final HMSTrack track;
  final HMSTrackUpdate update;
  @override
  List<Object?> get props => [peer, track, update];
}

final class _Joined extends CallEvent {
  const _Joined();
}

final class _Left extends CallEvent {
  const _Left();
}

final class _Reconnecting extends CallEvent {
  const _Reconnecting();
}

final class _Reconnected extends CallEvent {
  const _Reconnected();
}

final class _SdkError extends CallEvent {
  const _SdkError(this.error);
  final HMSException error;
  @override
  List<Object?> get props => [error];
}
