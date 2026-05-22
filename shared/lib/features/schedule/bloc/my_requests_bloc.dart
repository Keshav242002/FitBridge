import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/call_request.dart';
import '../../../services/api_client.dart';
import '../../../services/schedule_service.dart';
import 'my_requests_event.dart';
import 'my_requests_state.dart';

class MyRequestsBloc extends Bloc<MyRequestsEvent, MyRequestsState> {
  MyRequestsBloc({required this.service, required this.userId})
      : super(const MyRequestsLoading()) {
    on<LoadMyRequests>(_onLoad);
    add(const LoadMyRequests());
  }

  final ScheduleService service;
  final String userId;

  Future<void> _onLoad(LoadMyRequests _, Emitter<MyRequestsState> emit) async {
    emit(const MyRequestsLoading());
    final res = await service.getRequests(userId);
    switch (res) {
      case ApiSuccess(:final body):
        try {
          final list = (body as List)
              .map((j) => CallRequest.fromJson(j as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.scheduledFor.compareTo(a.scheduledFor));
          emit(MyRequestsLoaded(list));
        } catch (e) {
          emit(MyRequestsError('Could not parse requests: $e'));
        }
      case ApiFailure(:final message):
        emit(MyRequestsError(message));
    }
  }
}
