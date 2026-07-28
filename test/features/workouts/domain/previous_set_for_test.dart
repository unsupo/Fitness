import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/domain/use_cases/previous_set_for.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _set({
  required int id,
  required DateTime loggedAt,
  required int sessionId,
  required int setNumber,
  double? weight,
  int? reps,
}) {
  return WorkoutSet(
    id: id,
    loggedAt: loggedAt,
    machineId: 1,
    machineName: 'Bench Press',
    sessionId: sessionId,
    setNumber: setNumber,
    weight: weight,
    reps: reps,
  );
}

void main() {
  group('previousSetFor', () {
    test('returns the same set number from the most recent prior session', () {
      final history = [
        _set(id: 1, loggedAt: DateTime(2026, 7, 1), sessionId: 10, setNumber: 1, weight: 100, reps: 10),
        _set(id: 2, loggedAt: DateTime(2026, 7, 1), sessionId: 10, setNumber: 2, weight: 105, reps: 8),
        _set(id: 3, loggedAt: DateTime(2026, 7, 10), sessionId: 11, setNumber: 1, weight: 110, reps: 10),
        _set(id: 4, loggedAt: DateTime(2026, 7, 10), sessionId: 11, setNumber: 2, weight: 115, reps: 8),
      ];

      final result = previousSetFor(history, 2, currentSessionId: 99);

      expect(result?.id, 4);
      expect(result?.weight, 115);
    });

    test(
      'falls back to the last set of the most recent prior session when it '
      'had fewer sets than requested',
      () {
        final history = [
          _set(id: 1, loggedAt: DateTime(2026, 7, 1), sessionId: 10, setNumber: 1, weight: 100, reps: 10),
          _set(id: 2, loggedAt: DateTime(2026, 7, 1), sessionId: 10, setNumber: 2, weight: 105, reps: 8),
          _set(id: 3, loggedAt: DateTime(2026, 7, 1), sessionId: 10, setNumber: 3, weight: 108, reps: 6),
          // most recent session only has 1 set
          _set(id: 4, loggedAt: DateTime(2026, 7, 10), sessionId: 11, setNumber: 1, weight: 110, reps: 10),
        ];

        final result = previousSetFor(history, 3, currentSessionId: 99);

        expect(result?.id, 4);
      },
    );

    test('ignores sets from the current in-progress session', () {
      final history = [
        _set(id: 1, loggedAt: DateTime(2026, 7, 1), sessionId: 10, setNumber: 1, weight: 100, reps: 10),
        // "current" session already has a set logged, but must not count
        // as its own previous value.
        _set(id: 2, loggedAt: DateTime(2026, 7, 20), sessionId: 99, setNumber: 1, weight: 999, reps: 1),
      ];

      final result = previousSetFor(history, 1, currentSessionId: 99);

      expect(result?.id, 1);
    });

    test('returns null when there is no prior history', () {
      expect(previousSetFor(const [], 1, currentSessionId: 99), isNull);
    });

    test(
      'returns null when the only history belongs to the current session',
      () {
        final history = [
          _set(id: 1, loggedAt: DateTime(2026, 7, 20), sessionId: 99, setNumber: 1, weight: 100, reps: 10),
        ];

        expect(previousSetFor(history, 1, currentSessionId: 99), isNull);
      },
    );
  });
}
