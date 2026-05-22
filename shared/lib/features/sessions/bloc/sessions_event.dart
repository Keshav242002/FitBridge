import 'package:equatable/equatable.dart';

enum SessionFilter { all, last7Days, thisMonth }

sealed class SessionsEvent extends Equatable {
  const SessionsEvent();
  @override
  List<Object?> get props => [];
}

final class LoadSessions extends SessionsEvent {
  const LoadSessions();
}

final class ChangeFilter extends SessionsEvent {
  const ChangeFilter(this.filter);
  final SessionFilter filter;
  @override
  List<Object?> get props => [filter];
}
