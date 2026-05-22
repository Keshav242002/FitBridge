import 'package:equatable/equatable.dart';
import '../../../models/call_request.dart';

sealed class MyRequestsState extends Equatable {
  const MyRequestsState();
  @override
  List<Object?> get props => [];
}

final class MyRequestsLoading extends MyRequestsState {
  const MyRequestsLoading();
}

final class MyRequestsLoaded extends MyRequestsState {
  const MyRequestsLoaded(this.requests);
  final List<CallRequest> requests;
  @override
  List<Object?> get props => [requests];
}

final class MyRequestsError extends MyRequestsState {
  const MyRequestsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
