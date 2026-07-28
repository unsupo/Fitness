import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import 'workout_repository_provider.dart';

/// Past sessions, newest first — already ordered that way by the data layer
/// (see docs/features/workouts-history.md), so no re-sorting here.
final sessionHistoryProvider = FutureProvider<List<WorkoutSession>>((ref) {
  return ref.watch(workoutRepositoryProvider).getSessionHistory();
});

/// All sets logged in one session, used by both the History list row's
/// summary text and the session detail page's grouped-by-machine body.
final setsForSessionProvider = FutureProvider.family<List<WorkoutSet>, int>((
  ref,
  sessionId,
) {
  return ref.watch(workoutRepositoryProvider).getSetsForSession(sessionId);
});
