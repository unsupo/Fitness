import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_json.dart';
import '../../../../core/network/supabase_tables.dart';
import '../models/weight_entry_model.dart';

/// Thin wrapper around [SupabaseClient] for the analytics feature — one
/// method per query, no aggregation logic. Aggregation (grouping by day,
/// summing macros) happens in the domain use cases, not here.
class AnalyticsRemoteDataSource {
  AnalyticsRemoteDataSource(this._client);

  final SupabaseClient _client;

  /// Raw `food_log` rows (`logged_at`, `calories`, `protein_g`, `carbs_g`,
  /// `fat_g` only) within `[rangeStart, rangeEnd)`. Used for both the
  /// weekly-calories and macro-breakdown queries — callers aggregate
  /// client-side.
  Future<List<Map<String, dynamic>>> fetchFoodLogEntries({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    // rangeStart/rangeEnd are local calendar boundaries — convert to UTC
    // before querying a timestamptz column, same fix as
    // lib/features/diary/domain/use_cases/utc_day_range.dart. Skipping this
    // shifts the window by the local UTC offset and misattributes entries
    // logged near midnight to the wrong day (this is what caused the Weekly
    // Calories chart to show a bar for a day that hadn't happened yet).
    final rows = await _client
        .from(SupabaseTables.foodLog)
        .select('logged_at, calories, protein_g, carbs_g, fat_g')
        .gte('logged_at', rangeStart.toUtc().toIso8601String())
        .lt('logged_at', rangeEnd.toUtc().toIso8601String());
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<List<Map<String, dynamic>>> fetchAllWeightLogRows() async {
    // postgrest-dart's .order() defaults to descending — every caller of
    // getWeightHistory() (the raw chart's index-based x-axis, "Current
    // Weight" = history.last, the goal projection's weekly averaging)
    // assumes ascending (oldest first), so this must be explicit.
    final rows = await _client
        .from(SupabaseTables.weightLog)
        .select()
        .order('logged_at', ascending: true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  /// The single `daily_goals` row's `calorie_goal`.
  Future<double> fetchCalorieGoal() async {
    final row = await _client
        .from(SupabaseTables.dailyGoals)
        .select('calorie_goal')
        .single();
    return parseSupabaseNum(row['calorie_goal']);
  }

  Future<void> insertWeightLog(double weightKg, String goalType) async {
    await _client
        .from(SupabaseTables.weightLog)
        .insert(WeightEntryModel.toInsertJson(
          weightKg: weightKg,
          goalType: goalType,
        ));
  }

  Future<void> updateWeightLog({
    required int id,
    required double weightKg,
    required String goalType,
    required DateTime loggedAt,
  }) async {
    await _client
        .from(SupabaseTables.weightLog)
        .update({
          'weight_kg': weightKg,
          'goal_type': goalType,
          'logged_at': loggedAt.toUtc().toIso8601String(),
        })
        .eq('id', id);
  }

  Future<void> deleteWeightLog(int id) async {
    await _client.from(SupabaseTables.weightLog).delete().eq('id', id);
  }

  /// A single bulk insert (PostgREST natively accepts a list of rows) —
  /// used by CSV import so N readings become one round trip, not N.
  Future<void> bulkInsertWeightLog(List<Map<String, dynamic>> rows) async {
    await _client.from(SupabaseTables.weightLog).insert(rows);
  }

  /// The single `daily_goals` row's profile/target-weight columns.
  Future<Map<String, dynamic>> fetchUserProfile() async {
    return await _client
        .from(SupabaseTables.dailyGoals)
        .select('target_weight_kg, sex, age, height_cm, activity_level, unit_system')
        .single();
  }

  Future<void> updateUserProfile(Map<String, dynamic> fields) async {
    final row = await _client.from(SupabaseTables.dailyGoals).select('id').single();
    await _client
        .from(SupabaseTables.dailyGoals)
        .update(fields)
        .eq('id', row['id']);
  }
}
