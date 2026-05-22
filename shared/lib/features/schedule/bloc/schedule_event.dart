import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

sealed class ScheduleEvent extends Equatable {
  const ScheduleEvent();
}

final class SelectDate extends ScheduleEvent {
  const SelectDate(this.date);
  final DateTime date;

  @override
  List<Object?> get props => [date];
}

final class SelectSlot extends ScheduleEvent {
  const SelectSlot(this.slot);
  final TimeOfDay slot;

  @override
  List<Object?> get props => [slot];
}

final class UpdateNote extends ScheduleEvent {
  const UpdateNote(this.note);
  final String note;

  @override
  List<Object?> get props => [note];
}

final class SubmitRequest extends ScheduleEvent {
  const SubmitRequest();

  @override
  List<Object?> get props => [];
}
