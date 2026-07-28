import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/backend.dart';
import '../../domain/entities/machine.dart';
import '../../domain/repositories/workout_repository.dart';

/// Composition root for the Workouts feature — see docs/ARCHITECTURE.md's
/// "Composition root" section. Every Workouts presentation provider depends
/// on this, never on a concrete `SupabaseWorkoutRepository` directly.
final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => ref.watch(backendProvider).createWorkoutRepository(),
);

/// The full machine library — shared by the Log tab (add-exercise picker),
/// the Exercises tab, and the exercise detail page's title lookup. Lives
/// here rather than in one tab's own provider file so every consumer shares
/// a single cached instance instead of each tab fetching (and invalidating)
/// its own copy.
final machinesProvider = FutureProvider<List<Machine>>((ref) {
  return ref.watch(workoutRepositoryProvider).getMachines();
});
