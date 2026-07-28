import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';

/// One machine's sets within a session (or across a machine's whole
/// history), as produced by [groupSetsByMachine]. Used by both the History
/// detail page and the Log tab's in-progress list.
class MachineSetGroup {
  const MachineSetGroup({
    required this.machineId,
    required this.machineName,
    required this.sets,
  });

  final int machineId;
  final String machineName;
  final List<WorkoutSet> sets;
}

/// Groups a flat list of [WorkoutSet] into one [MachineSetGroup] per
/// `machineId`, each holding that machine's sets sorted by `setNumber`.
///
/// Groups themselves preserve first-seen order: a machine's position in the
/// result is determined by its `machineOrder` where present (from that
/// machine's first-occurring set), falling back to the machine's first-seen
/// index in [sets] when `machineOrder` is null.
List<MachineSetGroup> groupSetsByMachine(List<WorkoutSet> sets) {
  final setsByMachine = <int, List<WorkoutSet>>{};
  final machineNames = <int, String>{};
  final orderKeys = <int, num>{};

  for (var i = 0; i < sets.length; i++) {
    final set = sets[i];
    setsByMachine.putIfAbsent(set.machineId, () => []).add(set);
    machineNames.putIfAbsent(set.machineId, () => set.machineName);
    orderKeys.putIfAbsent(set.machineId, () => set.machineOrder ?? i);
  }

  final machineIds = setsByMachine.keys.toList()
    ..sort((a, b) => orderKeys[a]!.compareTo(orderKeys[b]!));

  return [
    for (final machineId in machineIds)
      MachineSetGroup(
        machineId: machineId,
        machineName: machineNames[machineId]!,
        sets: setsByMachine[machineId]!
          ..sort((a, b) => a.setNumber.compareTo(b.setNumber)),
      ),
  ];
}
