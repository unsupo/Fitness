import '../entities/machine.dart';
import '../entities/workout_session.dart';
import '../entities/workout_set.dart';

/// The Workouts feature's adapter seam — see docs/ARCHITECTURE.md. The
/// default implementation is `SupabaseWorkoutRepository`
/// (lib/features/workouts/data/repositories).
abstract class WorkoutRepository {
  Future<List<Machine>> getMachines();
  Future<WorkoutSession?> getLastSession();
  Future<List<WorkoutSession>> getSessionHistory();
  Future<List<WorkoutSet>> getSetsForSession(int sessionId);
  Future<List<WorkoutSet>> getSetsForMachine(int machineId);
  Future<WorkoutSession> startSession(DateTime sessionDate);

  /// [set].id is ignored on insert; the returned [WorkoutSet] carries the
  /// real generated id.
  Future<WorkoutSet> logSet(WorkoutSet set);
  Future<void> updateSet(WorkoutSet set);
  Future<void> deleteSet(int id);
}
