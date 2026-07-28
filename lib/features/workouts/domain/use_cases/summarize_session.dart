import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/domain/use_cases/group_sets_by_machine.dart';

/// Comma-joins the distinct machine names logged in [sets], in first-seen
/// order (e.g. "Chest Press, Squat, Treadmill"). Used by the History list
/// row and the Log tab's "last workout" summary. Empty input returns `''`.
String summarizeSession(List<WorkoutSet> sets) {
  final groups = groupSetsByMachine(sets);
  return groups.map((group) => group.machineName).join(', ');
}
