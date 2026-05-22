import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../models/call_request.dart';

sealed class ScheduleState extends Equatable {
  const ScheduleState();
}

final class ScheduleForm extends ScheduleState {
  const ScheduleForm({
    required this.selectedDate,
    this.selectedSlot,
    this.note = '',
    this.error,
    this.isSubmitting = false,
  });

  final DateTime selectedDate;
  final TimeOfDay? selectedSlot;
  final String note;
  final String? error;
  final bool isSubmitting;

  ScheduleForm copyWith({
    DateTime? selectedDate,
    Object? selectedSlot = _sentinel,
    String? note,
    Object? error = _sentinel,
    bool? isSubmitting,
  }) =>
      ScheduleForm(
        selectedDate: selectedDate ?? this.selectedDate,
        selectedSlot: selectedSlot == _sentinel ? this.selectedSlot : selectedSlot as TimeOfDay?,
        note: note ?? this.note,
        error: error == _sentinel ? this.error : error as String?,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );

  @override
  List<Object?> get props => [selectedDate, selectedSlot, note, error, isSubmitting];
}

final class ScheduleSubmitted extends ScheduleState {
  const ScheduleSubmitted(this.request);
  final CallRequest request;

  @override
  List<Object?> get props => [request];
}

// Sentinel for nullable copyWith fields
const Object _sentinel = Object();
