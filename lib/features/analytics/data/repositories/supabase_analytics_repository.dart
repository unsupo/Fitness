import '../../../../core/network/supabase_json.dart';
import '../../domain/entities/daily_calories.dart';
import '../../domain/entities/macro_breakdown.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/use_cases/compute_macro_breakdown.dart';
import '../../domain/use_cases/group_calories_by_day.dart';
import '../data_sources/analytics_remote_data_source.dart';
import '../models/user_profile_model.dart';
import '../models/weight_entry_model.dart';

/// Supabase-backed [AnalyticsRepository]. Delegates raw fetches to
/// [AnalyticsRemoteDataSource] and shapes the results using the pure domain
/// use cases — no aggregation logic lives here.
class SupabaseAnalyticsRepository implements AnalyticsRepository {
  SupabaseAnalyticsRepository(this._dataSource);

  final AnalyticsRemoteDataSource _dataSource;

  @override
  Future<List<DailyCalories>> getWeeklyCalories(DateTime weekStart) async {
    final rangeEnd = weekStart.add(const Duration(days: 7));
    final rows = await _dataSource.fetchFoodLogEntries(
      rangeStart: weekStart,
      rangeEnd: rangeEnd,
    );
    final entries = rows.map(_toCalorieEntry).toList();
    return groupCaloriesByDay(entries, weekStart);
  }

  @override
  Future<MacroBreakdown> getMacroBreakdown(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    final rows = await _dataSource.fetchFoodLogEntries(
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
    );
    final entries = rows.map(_toMacroEntry).toList();
    return computeMacroBreakdown(entries);
  }

  @override
  Future<List<WeightEntry>> getWeightHistory() async {
    final rows = await _dataSource.fetchAllWeightLogRows();
    return rows.map(WeightEntryModel.fromJson).toList();
  }

  @override
  Future<double> getCalorieGoal() => _dataSource.fetchCalorieGoal();

  @override
  Future<void> logWeight(double weightKg, String goalType) =>
      _dataSource.insertWeightLog(weightKg, goalType);

  @override
  Future<void> importWeightEntries(
    List<({DateTime loggedAt, double weightKg})> entries, {
    required String goalType,
  }) {
    final rows = [
      for (final entry in entries)
        {
          'logged_at': entry.loggedAt.toUtc().toIso8601String(),
          'weight_kg': entry.weightKg,
          'goal_type': goalType,
        },
    ];
    return _dataSource.bulkInsertWeightLog(rows);
  }

  @override
  Future<void> updateWeightEntry(WeightEntry entry) => _dataSource.updateWeightLog(
    id: entry.id,
    weightKg: entry.weightKg,
    goalType: entry.goalType,
    loggedAt: entry.loggedAt,
  );

  @override
  Future<void> deleteWeightEntry(int id) => _dataSource.deleteWeightLog(id);

  @override
  Future<UserProfile> getUserProfile() async {
    final row = await _dataSource.fetchUserProfile();
    return UserProfileModel.fromJson(row);
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) =>
      _dataSource.updateUserProfile(UserProfileModel.toUpdateJson(profile));

  ({DateTime loggedAt, double calories}) _toCalorieEntry(
    Map<String, dynamic> row,
  ) {
    return (
      loggedAt: DateTime.parse(row['logged_at'] as String).toLocal(),
      calories: parseSupabaseNum(row['calories']),
    );
  }

  ({double proteinG, double carbsG, double fatG}) _toMacroEntry(
    Map<String, dynamic> row,
  ) {
    return (
      proteinG: parseSupabaseNum(row['protein_g']),
      carbsG: parseSupabaseNum(row['carbs_g']),
      fatG: parseSupabaseNum(row['fat_g']),
    );
  }
}
