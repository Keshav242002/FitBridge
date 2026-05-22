import 'package:flutter_test/flutter_test.dart';
import 'package:wtf_shared/wtf_shared.dart';

void main() {
  group('SessionLog duration', () {
    final t = DateTime(2026, 5, 22, 10, 0, 0);

    test('durationSec matches startedAt → endedAt gap', () {
      final log = SessionLog(
        id: 'test-1',
        memberId: 'dk',
        trainerId: 'aarav',
        callRequestId: 'cr-1',
        startedAt: t,
        endedAt: t.add(const Duration(minutes: 12)),
        durationSec: 720,
      );
      expect(log.durationSec, 720);
      expect(
        log.endedAt.difference(log.startedAt).inSeconds,
        log.durationSec,
      );
    });

    test('durationSec 0 for zero-length call', () {
      final log = SessionLog(
        id: 'test-2',
        memberId: 'dk',
        trainerId: 'aarav',
        callRequestId: 'cr-2',
        startedAt: t,
        endedAt: t,
        durationSec: 0,
      );
      expect(log.durationSec, 0);
    });

    test('rating and notes are nullable', () {
      final log = SessionLog(
        id: 'test-3',
        memberId: 'dk',
        trainerId: 'aarav',
        callRequestId: 'cr-3',
        startedAt: t,
        endedAt: t.add(const Duration(minutes: 30)),
        durationSec: 1800,
        rating: 5,
        memberNotes: 'Great session!',
      );
      expect(log.rating, 5);
      expect(log.trainerNotes, isNull);
    });

    test('copyWith updates durationSec', () {
      final log = SessionLog(
        id: 'test-4',
        memberId: 'dk',
        trainerId: 'aarav',
        callRequestId: 'cr-4',
        startedAt: t,
        endedAt: t.add(const Duration(minutes: 5)),
        durationSec: 300,
      );
      final updated = log.copyWith(durationSec: 720);
      expect(updated.durationSec, 720);
      expect(updated.id, log.id);
    });
  });
}
