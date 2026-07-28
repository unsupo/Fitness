import 'package:arndt_fitness/features/workouts/data/data_sources/workouts_remote_data_source.dart';
import 'package:arndt_fitness/features/workouts/data/models/machine_model.dart';
import 'package:arndt_fitness/features/workouts/data/models/workout_session_model.dart';
import 'package:arndt_fitness/features/workouts/data/models/workout_set_model.dart';
import 'package:arndt_fitness/features/workouts/domain/entities/machine.dart';
import 'package:arndt_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/domain/repositories/workout_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase adapter implementation of [WorkoutRepository] — the concrete
/// backend the app defaults to. Delegates to [WorkoutsRemoteDataSource] and
/// maps raw JSON/models to domain entities. No aggregation logic lives
/// here — `groupSetsByMachine`/`summarizeSession`/`computePersonalRecord`
/// live in domain and are called by presentation, not by this repository.
class SupabaseWorkoutRepository implements WorkoutRepository {
  SupabaseWorkoutRepository(SupabaseClient client)
    : _dataSource = WorkoutsRemoteDataSource(client);

  final WorkoutsRemoteDataSource _dataSource;

  @override
  Future<List<Machine>> getMachines() async {
    final rows = await _dataSource.fetchMachines();
    return rows.map((row) => MachineModel.fromJson(row).toEntity()).toList();
  }

  @override
  Future<WorkoutSession?> getLastSession() async {
    final row = await _dataSource.fetchLastSession();
    if (row == null) return null;
    return WorkoutSessionModel.fromJson(row).toEntity();
  }

  @override
  Future<List<WorkoutSession>> getSessionHistory() async {
    final rows = await _dataSource.fetchSessionHistory();
    return rows
        .map((row) => WorkoutSessionModel.fromJson(row).toEntity())
        .toList();
  }

  @override
  Future<List<WorkoutSet>> getSetsForSession(int sessionId) async {
    final rows = await _dataSource.fetchSetsForSession(sessionId);
    return rows.map((row) => WorkoutSetModel.fromJson(row).toEntity()).toList();
  }

  @override
  Future<List<WorkoutSet>> getSetsForMachine(int machineId) async {
    final rows = await _dataSource.fetchSetsForMachine(machineId);
    return rows.map((row) => WorkoutSetModel.fromJson(row).toEntity()).toList();
  }

  @override
  Future<WorkoutSession> startSession(DateTime sessionDate) async {
    final row = await _dataSource.insertSession(sessionDate);
    return WorkoutSessionModel.fromJson(row).toEntity();
  }

  @override
  Future<WorkoutSet> logSet(WorkoutSet set) async {
    final json = WorkoutSetModel.fromEntity(set).toInsertJson();
    final id = await _dataSource.insertSet(json);

    // set.id is ignored on insert; the rest of the row is exactly what was
    // sent (no server-computed columns besides id), so build the returned
    // entity from the input plus the real generated id rather than
    // re-fetching with a join.
    return WorkoutSet(
      id: id,
      loggedAt: set.loggedAt,
      machineId: set.machineId,
      machineName: set.machineName,
      sessionId: set.sessionId,
      setNumber: set.setNumber,
      machineOrder: set.machineOrder,
      weight: set.weight,
      reps: set.reps,
      unit: set.unit,
      incline: set.incline,
      speed: set.speed,
      durationMinutes: set.durationMinutes,
      seatPosition: set.seatPosition,
      restSeconds: set.restSeconds,
      notes: set.notes,
    );
  }

  @override
  Future<void> updateSet(WorkoutSet set) async {
    final json = WorkoutSetModel.fromEntity(set).toInsertJson();
    await _dataSource.updateSet(set.id, json);
  }

  @override
  Future<void> deleteSet(int id) => _dataSource.deleteSet(id);
}
