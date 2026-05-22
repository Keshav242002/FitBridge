import 'package:equatable/equatable.dart';
import '../../../models/session_log.dart';
import 'sessions_event.dart';

sealed class SessionsState extends Equatable {
  const SessionsState();
  @override
  List<Object?> get props => [];
}

final class SessionsLoading extends SessionsState {
  const SessionsLoading();
}

final class SessionsLoaded extends SessionsState {
  const SessionsLoaded({
    required this.all,
    required this.filtered,
    required this.filter,
  });

  final List<SessionLog> all;
  final List<SessionLog> filtered;
  final SessionFilter filter;

  @override
  List<Object?> get props => [all, filtered, filter];
}

final class SessionsError extends SessionsState {
  const SessionsError(this.message);
  final String message;
  @override
  List<Object?> get props => [message];
}
