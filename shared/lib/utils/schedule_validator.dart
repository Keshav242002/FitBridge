class ScheduleValidator {
  static bool isPastSlot(DateTime slot) => slot.isBefore(DateTime.now());

  static String? validateSlot(DateTime? slot) {
    if (slot == null) return 'Please select a date and time';
    if (isPastSlot(slot)) return 'Cannot book a past time slot';
    return null;
  }
}
