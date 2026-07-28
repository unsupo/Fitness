import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout_set.dart';
import 'workout_repository_provider.dart';

/// One machine's full set history (repository order — oldest first).
final setsForMachineProvider = FutureProvider.family<List<WorkoutSet>, int>((
  ref,
  machineId,
) {
  return ref.watch(workoutRepositoryProvider).getSetsForMachine(machineId);
});
