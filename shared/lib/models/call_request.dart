import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum CallRequestStatus { pending, approved, declined, cancelled }

@immutable
class CallRequest extends Equatable {
  const CallRequest({
    required this.id,
    required this.memberId,
    required this.trainerId,
    required this.requestedAt,
    required this.scheduledFor,
    required this.note,
    required this.status,
    this.declineReason,
  });

  final String id;
  final String memberId;
  final String trainerId;
  final DateTime requestedAt;
  final DateTime scheduledFor;
  final String note;
  final CallRequestStatus status;
  final String? declineReason;

  factory CallRequest.fromJson(Map<String, dynamic> json) => CallRequest(
        id: json['id'] as String,
        memberId: json['memberId'] as String,
        trainerId: json['trainerId'] as String,
        requestedAt: DateTime.parse(json['requestedAt'] as String),
        scheduledFor: DateTime.parse(json['scheduledFor'] as String),
        note: json['note'] as String,
        status: CallRequestStatus.values.firstWhere(
          (s) => s.name == json['status'],
          orElse: () => CallRequestStatus.pending,
        ),
        declineReason: json['declineReason'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'memberId': memberId,
        'trainerId': trainerId,
        'requestedAt': requestedAt.toIso8601String(),
        'scheduledFor': scheduledFor.toIso8601String(),
        'note': note,
        'status': status.name,
        'declineReason': declineReason,
      };

  CallRequest copyWith({
    String? id,
    String? memberId,
    String? trainerId,
    DateTime? requestedAt,
    DateTime? scheduledFor,
    String? note,
    CallRequestStatus? status,
    String? declineReason,
  }) =>
      CallRequest(
        id: id ?? this.id,
        memberId: memberId ?? this.memberId,
        trainerId: trainerId ?? this.trainerId,
        requestedAt: requestedAt ?? this.requestedAt,
        scheduledFor: scheduledFor ?? this.scheduledFor,
        note: note ?? this.note,
        status: status ?? this.status,
        declineReason: declineReason ?? this.declineReason,
      );

  @override
  List<Object?> get props =>
      [id, memberId, trainerId, requestedAt, scheduledFor, note, status, declineReason];
}
