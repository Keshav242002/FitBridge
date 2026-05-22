import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/call_request.dart';
import '../../../services/api_client.dart';
import '../../../services/schedule_service.dart';
import 'requests_event.dart';
import 'requests_state.dart';

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  RequestsBloc({required this.service, required this.trainerId})
      : super(const RequestsLoading()) {
    on<LoadRequests>(_onLoad);
    on<ApproveRequest>(_onApprove);
    on<DeclineRequest>(_onDecline);
    add(const LoadRequests());
  }

  final ScheduleService service;
  final String trainerId;

  Future<void> _onLoad(LoadRequests e, Emitter<RequestsState> emit) async {
    emit(const RequestsLoading());
    final res = await service.getRequests(trainerId);
    switch (res) {
      case ApiSuccess(:final body):
        try {
          final list = (body as List)
              .map((j) => CallRequest.fromJson(j as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => a.scheduledFor.compareTo(b.scheduledFor));
          emit(RequestsLoaded(list));
        } catch (e) {
          emit(RequestsError('Could not parse requests: $e'));
        }
      case ApiFailure(:final message):
        emit(RequestsError(message));
    }
  }

  Future<void> _onApprove(ApproveRequest e, Emitter<RequestsState> emit) async {
    final res = await service.approveRequest(e.id);
    switch (res) {
      case ApiSuccess():
        add(const LoadRequests());
      case ApiFailure(:final message):
        emit(RequestsError(message));
    }
  }

  Future<void> _onDecline(DeclineRequest e, Emitter<RequestsState> emit) async {
    final res = await service.declineRequest(e.id, reason: e.reason);
    switch (res) {
      case ApiSuccess():
        add(const LoadRequests());
      case ApiFailure(:final message):
        emit(RequestsError(message));
    }
  }
}
