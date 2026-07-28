import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/domain/use_cases/summarize_session.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _set({
  required int id,
  required int machineId,
  required String machineName,
  required int setNumber,
}) {
  return WorkoutSet(
    id: id,
    loggedAt: DateTime(2026, 7, 1, 9, setNumber),
    machineId: machineId,
    machineName: machineName,
    sessionId: 1,
    setNumber: setNumber,
  );
}

void main() {
  test(
    'comma-joins distinct machine names in first-seen order, ignoring repeats',
    () {
      final sets = [
        _set(id: 1, machineId: 1, machineName: 'Chest Press', setNumber: 1),
        _set(id: 2, machineId: 2, machineName: 'Squat', setNumber: 1),
        _set(id: 3, machineId: 1, machineName: 'Chest Press', setNumber: 2),
        _set(id: 4, machineId: 3, machineName: 'Treadmill', setNumber: 1),
        _set(id: 5, machineId: 2, machineName: 'Squat', setNumber: 2),
      ];

      expect(summarizeSession(sets), 'Chest Press, Squat, Treadmill');
    },
  );

  test('empty list returns empty string', () {
    expect(summarizeSession(const []), '');
  });
}
