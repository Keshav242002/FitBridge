import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../models/user.dart';
import '../../../services/api_client.dart';

part 'members_event.dart';
part 'members_state.dart';

class MembersBloc extends Bloc<MembersEvent, MembersState> {
  MembersBloc({required this.api}) : super(const MembersInitial()) {
    on<LoadMembers>(_onLoad);
  }

  final ApiClient api;

  Future<void> _onLoad(LoadMembers e, Emitter<MembersState> emit) async {
    emit(const MembersLoading());

    final res = await api.get('/users');
    switch (res) {
      case ApiSuccess(:final body):
        final list = (body as List)
            .whereType<Map<String, dynamic>>()
            .map(User.fromJson)
            .where((u) => u.role == UserRole.member)
            .toList();
        emit(MembersLoaded(members: list));
      case ApiFailure(:final message):
        emit(MembersError(message: message));
    }
  }
}
