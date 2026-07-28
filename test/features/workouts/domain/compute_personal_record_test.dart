import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/domain/use_cases/compute_personal_record.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _set({
  required int id,
  required double? weight,
  required DateTime loggedAt,
  int setNumber = 1,
}) {
  return WorkoutSet(
    id: id,
    loggedAt: loggedAt,
    machineId: 1,
    machineName: 'Bench Press',
    sessionId: 1,
    setNumber: setNumber,
    weight: weight,
  );
}

void main() {
  test('returns the set with the highest weight', () {
    final sets = [
      _set(id: 1, weight: 100, loggedAt: DateTime(2026, 1, 1)),
      _set(id: 2, weight: 135, loggedAt: DateTime(2026, 1, 5)),
      _set(id: 3, weight: 115, loggedAt: DateTime(2026, 1, 10)),
    ];

    final pr = computePersonalRecord(sets);

    expect(pr?.id, 2);
  });

  test('treats null weight as lowest — never a PR', () {
    final sets = [
      _set(id: 1, weight: null, loggedAt: DateTime(2026, 1, 1)),
      _set(id: 2, weight: 50, loggedAt: DateTime(2026, 1, 2)),
      _set(id: 3, weight: null, loggedAt: DateTime(2026, 1, 3)),
    ];

    final pr = computePersonalRecord(sets);

    expect(pr?.id, 2);
  });

  test('cardio machine with no weight data at all returns null', () {
    final sets = [
      _set(id: 1, weight: null, loggedAt: DateTime(2026, 1, 1)),
      _set(id: 2, weight: null, loggedAt: DateTime(2026, 1, 2)),
    ];

    expect(computePersonalRecord(sets), isNull);
  });

  test('ties keep the earliest loggedAt', () {
    final sets = [
      _set(id: 1, weight: 135, loggedAt: DateTime(2026, 1, 10)),
      _set(id: 2, weight: 135, loggedAt: DateTime(2026, 1, 3)),
      _set(id: 3, weight: 135, loggedAt: DateTime(2026, 1, 20)),
    ];

    final pr = computePersonalRecord(sets);

    expect(pr?.id, 2);
  });

  test('empty list returns null', () {
    expect(computePersonalRecord(const []), isNull);
  });
}
