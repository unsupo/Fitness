import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import 'workout_repository_provider.dart';

/// All machines in the library, for the Log tab's "Add Exercise" picker.
final machinesProvider = FutureProvider<List<Machine>>((ref) {
  return ref.watch(workoutRepositoryProvider).getMachines();
});

/// The most recently completed session, for the Log tab's idle-state
/// "last workout" summary card. Null when there's no workout history yet.
final lastSessionProvider = FutureProvider<WorkoutSession?>((ref) {
  return ref.watch(workoutRepositoryProvider).getLastSession();
});

/// Sets logged for a given session — used both for the idle-state "last
/// workout" summary and the active session's in-progress exercise list.
/// `ref.invalidate(sessionSetsProvider(sessionId))` after logging a new set
/// so the UI refetches and shows it immediately.
final sessionSetsProvider = FutureProvider.family<List<WorkoutSet>, int>((
  ref,
  sessionId,
) {
  return ref.watch(workoutRepositoryProvider).getSetsForSession(sessionId);
});
