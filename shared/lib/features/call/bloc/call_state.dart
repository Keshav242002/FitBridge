part of 'call_bloc.dart';

sealed class CallState extends Equatable {
  const CallState();
  @override
  List<Object?> get props => [];
}

final class CallIdle extends CallState {
  const CallIdle();
}

final class CallPreparing extends CallState {
  const CallPreparing();
}

final class CallPreJoin extends CallState {
  const CallPreJoin({
    required this.token,
    required this.roomId,
    required this.callRequestId,
    required this.userId,
    required this.userName,
    required this.role,
    required this.memberId,
    required this.trainerId,
    this.isMicOn = true,
    this.isVideoOn = true,
  });

  final String token;
  final String roomId;
  final String callRequestId;
  final String userId;
  final String userName;
  final String role;
  final String memberId;
  final String trainerId;
  final bool isMicOn;
  final bool isVideoOn;

  @override
  List<Object?> get props => [
        token, roomId, callRequestId, userId, userName,
        role, memberId, trainerId, isMicOn, isVideoOn,
      ];

  CallPreJoin copyWith({bool? isMicOn, bool? isVideoOn}) => CallPreJoin(
        token: token,
        roomId: roomId,
        callRequestId: callRequestId,
        userId: userId,
        userName: userName,
        role: role,
        memberId: memberId,
        trainerId: trainerId,
        isMicOn: isMicOn ?? this.isMicOn,
        isVideoOn: isVideoOn ?? this.isVideoOn,
      );
}

final class CallJoining extends CallState {
  const CallJoining();
}

final class CallInCall extends CallState {
  const CallInCall({
    required this.callRequestId,
    required this.memberId,
    required this.trainerId,
    required this.userId,
    required this.startedAt,
    this.localPeer,
    this.remotePeer,
    this.localVideoTrack,
    this.remoteVideoTrack,
    this.isMicOn = true,
    this.isVideoOn = true,
    this.isReconnecting = false,
  });

  final String callRequestId;
  final String memberId;
  final String trainerId;
  final String userId;
  final DateTime startedAt;
  final HMSPeer? localPeer;
  final HMSPeer? remotePeer;
  final HMSVideoTrack? localVideoTrack;
  final HMSVideoTrack? remoteVideoTrack;
  final bool isMicOn;
  final bool isVideoOn;
  final bool isReconnecting;

  @override
  List<Object?> get props => [
        callRequestId, memberId, trainerId, userId, startedAt,
        localPeer, remotePeer, localVideoTrack, remoteVideoTrack,
        isMicOn, isVideoOn, isReconnecting,
      ];

  CallInCall copyWith({
    HMSPeer? localPeer,
    HMSPeer? remotePeer,
    HMSVideoTrack? Function()? localVideoTrack,
    HMSVideoTrack? Function()? remoteVideoTrack,
    bool? isMicOn,
    bool? isVideoOn,
    bool? isReconnecting,
  }) =>
      CallInCall(
        callRequestId: callRequestId,
        memberId: memberId,
        trainerId: trainerId,
        userId: userId,
        startedAt: startedAt,
        localPeer: localPeer ?? this.localPeer,
        remotePeer: remotePeer ?? this.remotePeer,
        localVideoTrack:
            localVideoTrack != null ? localVideoTrack() : this.localVideoTrack,
        remoteVideoTrack:
            remoteVideoTrack != null ? remoteVideoTrack() : this.remoteVideoTrack,
        isMicOn: isMicOn ?? this.isMicOn,
        isVideoOn: isVideoOn ?? this.isVideoOn,
        isReconnecting: isReconnecting ?? this.isReconnecting,
      );
}

final class CallEnded extends CallState {
  const CallEnded({
    required this.durationSec,
    required this.sessionLogId,
    required this.memberId,
    required this.trainerId,
    required this.userId,
    required this.callRequestId,
  });

  final int durationSec;
  final String sessionLogId;
  final String memberId;
  final String trainerId;
  final String userId;
  final String callRequestId;

  @override
  List<Object?> get props =>
      [durationSec, sessionLogId, memberId, trainerId, userId, callRequestId];
}

final class CallError extends CallState {
  const CallError({required this.message});
  final String message;
  @override
  List<Object?> get props => [message];
}
