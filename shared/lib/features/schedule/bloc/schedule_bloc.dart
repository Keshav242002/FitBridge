import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/call_request.dart';
import '../../../services/api_client.dart';
import '../../../services/schedule_service.dart';
import '../../../utils/schedule_validator.dart';
import 'schedule_event.dart';
import 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  ScheduleBloc({
    required this.service,
    required this.memberId,
    required this.trainerId,
  }) : super(ScheduleForm(selectedDate: _today())) {
    on<SelectDate>(_onSelectDate);
    on<SelectSlot>(_onSelectSlot);
    on<UpdateNote>(_onUpdateNote);
    on<SubmitRequest>(_onSubmit);
  }

  final ScheduleService service;
  final String memberId;
  final String trainerId;

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  void _onSelectDate(SelectDate e, Emitter<ScheduleState> emit) {
    final s = state as ScheduleForm;
    emit(s.copyWith(selectedDate: e.date, selectedSlot: null, error: null));
  }

  void _onSelectSlot(SelectSlot e, Emitter<ScheduleState> emit) {
    final s = state as ScheduleForm;
    final slot = _toDateTime(s.selectedDate, e.slot);
    final err = ScheduleValidator.validateSlot(slot);
    emit(s.copyWith(selectedSlot: err == null ? e.slot : null, error: err));
  }

  void _onUpdateNote(UpdateNote e, Emitter<ScheduleState> emit) {
    final s = state as ScheduleForm;
    emit(s.copyWith(note: e.note));
  }

  Future<void> _onSubmit(SubmitRequest e, Emitter<ScheduleState> emit) async {
    final s = state as ScheduleForm;
    if (s.selectedSlot == null) {
      emit(s.copyWith(error: 'Please select a date and time'));
      return;
    }
    final slot = _toDateTime(s.selectedDate, s.selectedSlot!);
    final err = ScheduleValidator.validateSlot(slot);
    if (err != null) {
      emit(s.copyWith(error: err));
      return;
    }
    emit(s.copyWith(isSubmitting: true, error: null));

    final res = await service.createRequest(
      memberId: memberId,
      trainerId: trainerId,
      scheduledFor: slot,
      note: s.note,
    );

    switch (res) {
      case ApiSuccess(:final body):
        try {
          final cr = CallRequest.fromJson(body as Map<String, dynamic>);
          emit(ScheduleSubmitted(cr));
        } catch (_) {
          emit(s.copyWith(isSubmitting: false, error: 'Unexpected server response'));
        }
      case ApiFailure(:final message):
        emit(s.copyWith(isSubmitting: false, error: message));
    }
  }

  static DateTime _toDateTime(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
