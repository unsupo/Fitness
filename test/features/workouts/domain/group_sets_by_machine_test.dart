import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/domain/use_cases/group_sets_by_machine.dart';
import 'package:flutter_test/flutter_test.dart';

WorkoutSet _set({
  required int id,
  required int machineId,
  required String machineName,
  required int setNumber,
  int? machineOrder,
}) {
  return WorkoutSet(
    id: id,
    loggedAt: DateTime(2026, 7, 1, 9, setNumber),
    machineId: machineId,
    machineName: machineName,
    sessionId: 1,
    setNumber: setNumber,
    machineOrder: machineOrder,
  );
}

void main() {
  test(
    'groups interleaved sets by machine, sets sorted by setNumber, '
    'groups in first-seen machine order',
    () {
      // Input interleaved by setNumber across 2 machines, and machine A's
      // own sets are out of setNumber order within the input too.
      final sets = [
        _set(id: 1, machineId: 1, machineName: 'Bench Press', setNumber: 2),
        _set(id: 2, machineId: 2, machineName: 'Squat', setNumber: 1),
        _set(id: 3, machineId: 1, machineName: 'Bench Press', setNumber: 1),
        _set(id: 4, machineId: 2, machineName: 'Squat', setNumber: 2),
      ];

      final groups = groupSetsByMachine(sets);

      expect(groups, hasLength(2));

      // First-seen order: machine 1 (Bench Press) appeared first in input.
      expect(groups[0].machineId, 1);
      expect(groups[0].machineName, 'Bench Press');
      expect(groups[0].sets.map((s) => s.setNumber), [1, 2]);
      expect(groups[0].sets.map((s) => s.id), [3, 1]);

      expect(groups[1].machineId, 2);
      expect(groups[1].machineName, 'Squat');
      expect(groups[1].sets.map((s) => s.setNumber), [1, 2]);
      expect(groups[1].sets.map((s) => s.id), [2, 4]);
    },
  );

  test('uses machineOrder to order groups when present, overriding input order', () {
    final sets = [
      _set(id: 1, machineId: 2, machineName: 'Squat', setNumber: 1, machineOrder: 1),
      _set(id: 2, machineId: 1, machineName: 'Bench Press', setNumber: 1, machineOrder: 0),
    ];

    final groups = groupSetsByMachine(sets);

    expect(groups.map((g) => g.machineId), [1, 2]);
  });

  test('empty input returns empty list', () {
    expect(groupSetsByMachine(const []), isEmpty);
  });
}
