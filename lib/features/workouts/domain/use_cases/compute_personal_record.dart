import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';

/// Returns the set with the highest `weight` from [setsForOneMachine].
///
/// Sets with a null `weight` are treated as lowest — never a PR — so a
/// cardio machine with no weight data at all (every set's `weight` is null)
/// returns `null`. Ties keep the set with the earliest `loggedAt`.
WorkoutSet? computePersonalRecord(List<WorkoutSet> setsForOneMachine) {
  WorkoutSet? best;

  for (final set in setsForOneMachine) {
    if (set.weight == null) continue;

    if (best == null) {
      best = set;
    } else if (set.weight! > best.weight!) {
      best = set;
    } else if (set.weight! == best.weight! && set.loggedAt.isBefore(best.loggedAt)) {
      best = set;
    }
  }

  return best;
}
