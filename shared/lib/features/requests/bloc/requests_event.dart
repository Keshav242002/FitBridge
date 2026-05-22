import 'package:equatable/equatable.dart';

sealed class RequestsEvent extends Equatable {
  const RequestsEvent();
}

final class LoadRequests extends RequestsEvent {
  const LoadRequests();

  @override
  List<Object?> get props => [];
}

final class ApproveRequest extends RequestsEvent {
  const ApproveRequest(this.id);
  final String id;

  @override
  List<Object?> get props => [id];
}

final class DeclineRequest extends RequestsEvent {
  const DeclineRequest({required this.id, required this.reason});
  final String id;
  final String reason;

  @override
  List<Object?> get props => [id, reason];
}
