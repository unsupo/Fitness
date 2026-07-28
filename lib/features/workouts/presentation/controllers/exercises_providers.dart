import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_set.dart';
import 'workout_repository_provider.dart';

/// The full machine library — used by both the Exercises tab list and the
/// exercise detail page's title lookup.
final machinesProvider = FutureProvider<List<Machine>>((ref) {
  return ref.watch(workoutRepositoryProvider).getMachines();
});

/// One machine's full set history (repository order — oldest first).
final setsForMachineProvider = FutureProvider.family<List<WorkoutSet>, int>((
  ref,
  machineId,
) {
  return ref.watch(workoutRepositoryProvider).getSetsForMachine(machineId);
});
