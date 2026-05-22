import 'package:test/test.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  group('ScheduleValidator.isPastSlot', () {
    test('returns true for a slot in the past', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      expect(ScheduleValidator.isPastSlot(past), isTrue);
    });

    test('returns false for a slot in the future', () {
      final future = DateTime.now().add(const Duration(hours: 1));
      expect(ScheduleValidator.isPastSlot(future), isFalse);
    });
  });

  group('ScheduleValidator.validateSlot', () {
    test('returns error when slot is null', () {
      expect(ScheduleValidator.validateSlot(null), isNotNull);
    });

    test('returns error when slot is in the past', () {
      final past = DateTime.now().subtract(const Duration(minutes: 1));
      expect(ScheduleValidator.validateSlot(past), isNotNull);
    });

    test('returns null when slot is in the future', () {
      final future = DateTime.now().add(const Duration(hours: 2));
      expect(ScheduleValidator.validateSlot(future), isNull);
    });

    test('error message for null mentions selecting a time', () {
      final msg = ScheduleValidator.validateSlot(null);
      expect(msg!.toLowerCase(), contains('select'));
    });

    test('error message for past slot mentions past', () {
      final past = DateTime.now().subtract(const Duration(hours: 1));
      final msg = ScheduleValidator.validateSlot(past);
      expect(msg!.toLowerCase(), contains('past'));
    });
  });
}
