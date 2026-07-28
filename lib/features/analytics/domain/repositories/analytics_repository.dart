import '../entities/daily_calories.dart';
import '../entities/macro_breakdown.dart';
import '../entities/user_profile.dart';
import '../entities/weight_entry.dart';

/// Abstract seam for the analytics/trends feature. Supabase is the only
/// implementation today (`SupabaseAnalyticsRepository`), but presentation
/// code only ever depends on this interface.
abstract class AnalyticsRepository {
  Future<List<DailyCalories>> getWeeklyCalories(DateTime weekStart);

  Future<MacroBreakdown> getMacroBreakdown(
    DateTime rangeStart,
    DateTime rangeEnd,
  );

  Future<List<WeightEntry>> getWeightHistory();

  Future<double> getCalorieGoal();

  Future<void> logWeight(double weightKg, String goalType);

  /// Bulk-inserts entries parsed from a CSV export (see
  /// `parseWeightExportCsv`) — every entry shares [goalType] since the
  /// export has no per-row goal information.
  Future<void> importWeightEntries(
    List<({DateTime loggedAt, double weightKg})> entries, {
    required String goalType,
  });

  Future<void> updateWeightEntry(WeightEntry entry);

  Future<void> deleteWeightEntry(int id);

  Future<UserProfile> getUserProfile();

  Future<void> updateUserProfile(UserProfile profile);
}
