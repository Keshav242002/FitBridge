import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/session_log.dart';
import '../../../services/api_client.dart';
import '../../../services/session_service.dart';
import 'sessions_event.dart';
import 'sessions_state.dart';

class SessionsBloc extends Bloc<SessionsEvent, SessionsState> {
  SessionsBloc({required this.service, required this.userId})
      : super(const SessionsLoading()) {
    on<LoadSessions>(_onLoad);
    on<ChangeFilter>(_onFilter);
    add(const LoadSessions());
  }

  final SessionService service;
  final String userId;

  Future<void> _onLoad(LoadSessions _, Emitter<SessionsState> emit) async {
    emit(const SessionsLoading());
    final res = await service.getSessions(userId);
    switch (res) {
      case ApiSuccess(:final body):
        try {
          final all = (body as List)
              .map((j) => SessionLog.fromJson(j as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
          emit(SessionsLoaded(all: all, filtered: all, filter: SessionFilter.all));
        } catch (e) {
          emit(SessionsError('Could not parse sessions: $e'));
        }
      case ApiFailure(:final message):
        emit(SessionsError(message));
    }
  }

  void _onFilter(ChangeFilter event, Emitter<SessionsState> emit) {
    final current = state;
    if (current is! SessionsLoaded) return;
    emit(SessionsLoaded(
      all: current.all,
      filtered: _applyFilter(current.all, event.filter),
      filter: event.filter,
    ));
  }

  List<SessionLog> _applyFilter(List<SessionLog> all, SessionFilter filter) {
    final now = DateTime.now();
    return switch (filter) {
      SessionFilter.all => all,
      SessionFilter.last7Days => all
          .where((s) => s.startedAt.isAfter(now.subtract(const Duration(days: 7))))
          .toList(),
      SessionFilter.thisMonth => all
          .where((s) =>
              s.startedAt.year == now.year && s.startedAt.month == now.month)
          .toList(),
    };
  }
}
