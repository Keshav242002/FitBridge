import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class RoomMeta extends Equatable {
  const RoomMeta({
    required this.id,
    required this.callRequestId,
    required this.hmsRoomId,
    required this.hmsRoleMember,
    required this.hmsRoleTrainer,
  });

  final String id;
  final String callRequestId;
  final String hmsRoomId;
  final String hmsRoleMember;
  final String hmsRoleTrainer;

  factory RoomMeta.fromJson(Map<String, dynamic> json) => RoomMeta(
        id: json['id'] as String,
        callRequestId: json['callRequestId'] as String,
        hmsRoomId: json['hmsRoomId'] as String,
        hmsRoleMember: json['hmsRoleMember'] as String,
        hmsRoleTrainer: json['hmsRoleTrainer'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'callRequestId': callRequestId,
        'hmsRoomId': hmsRoomId,
        'hmsRoleMember': hmsRoleMember,
        'hmsRoleTrainer': hmsRoleTrainer,
      };

  RoomMeta copyWith({
    String? id,
    String? callRequestId,
    String? hmsRoomId,
    String? hmsRoleMember,
    String? hmsRoleTrainer,
  }) =>
      RoomMeta(
        id: id ?? this.id,
        callRequestId: callRequestId ?? this.callRequestId,
        hmsRoomId: hmsRoomId ?? this.hmsRoomId,
        hmsRoleMember: hmsRoleMember ?? this.hmsRoleMember,
        hmsRoleTrainer: hmsRoleTrainer ?? this.hmsRoleTrainer,
      );

  @override
  List<Object?> get props => [id, callRequestId, hmsRoomId, hmsRoleMember, hmsRoleTrainer];
}
