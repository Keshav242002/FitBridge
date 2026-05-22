import 'package:equatable/equatable.dart';
import '../../../models/call_request.dart';

sealed class RequestsState extends Equatable {
  const RequestsState();
}

final class RequestsLoading extends RequestsState {
  const RequestsLoading();

  @override
  List<Object?> get props => [];
}

final class RequestsLoaded extends RequestsState {
  const RequestsLoaded(this.requests);
  final List<CallRequest> requests;

  @override
  List<Object?> get props => [requests];
}

final class RequestsError extends RequestsState {
  const RequestsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
