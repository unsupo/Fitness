import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around [SupabaseClient] — one method per query. Returns raw
/// decoded JSON; mapping to domain entities happens in the model/repository
/// layer, not here.
class WorkoutsRemoteDataSource {
  WorkoutsRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// `workout_sets` rows joined with the machine's name, for [WorkoutSet]
  /// mapping (`machineName` is denormalized from this join).
  static const _setSelect = '*, machines(name)';

  Future<List<Map<String, dynamic>>> fetchMachines() async {
    final rows = await _client
        .from(SupabaseTables.machines)
        .select()
        .order('name', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>?> fetchLastSession() async {
    return _client
        .from(SupabaseTables.workoutSessions)
        .select()
        .order('session_date', ascending: false)
        .limit(1)
        .maybeSingle();
  }

  /// Most recent first — always pass `ascending:` explicitly (see
  /// docs/FUTURE_IMPROVEMENTS.md Round 9: an implicit ascending default bit
  /// this app before).
  Future<List<Map<String, dynamic>>> fetchSessionHistory() async {
    final rows = await _client
        .from(SupabaseTables.workoutSessions)
        .select()
        .order('session_date', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchSetsForSession(int sessionId) async {
    final rows = await _client
        .from(SupabaseTables.workoutSets)
        .select(_setSelect)
        .eq('session_id', sessionId)
        .order('set_number', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<List<Map<String, dynamic>>> fetchSetsForMachine(int machineId) async {
    final rows = await _client
        .from(SupabaseTables.workoutSets)
        .select(_setSelect)
        .eq('machine_id', machineId)
        .order('logged_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows);
  }

  /// Inserts a `workout_sessions` row and returns the created row (real
  /// generated `id` read back from the insert response).
  Future<Map<String, dynamic>> insertSession(DateTime sessionDate) async {
    return await _client
        .from(SupabaseTables.workoutSessions)
        .insert({'session_date': _dateOnly(sessionDate)})
        .select()
        .single();
  }

  /// Inserts a `workout_sets` row and returns its generated `id` (read back
  /// from the insert response, never assumed/hardcoded).
  Future<int> insertSet(Map<String, dynamic> json) async {
    final row = await _client
        .from(SupabaseTables.workoutSets)
        .insert(json)
        .select('id')
        .single();
    return row['id'] as int;
  }

  Future<void> updateSet(int id, Map<String, dynamic> json) async {
    await _client.from(SupabaseTables.workoutSets).update(json).eq('id', id);
  }

  Future<void> deleteSet(int id) async {
    await _client.from(SupabaseTables.workoutSets).delete().eq('id', id);
  }

  /// Formats a [DateTime] as a `yyyy-MM-dd` string for Postgres `date`
  /// columns (no time component).
  String _dateOnly(DateTime date) => date.toIso8601String().split('T').first;
}
