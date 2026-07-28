import 'package:arndt_fitness/features/analytics/domain/entities/daily_calories.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/macro_breakdown.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/domain/repositories/analytics_repository.dart';

/// Canned [AnalyticsRepository] for widget tests — no real network/Supabase
/// calls. Every field is overridable so individual tests can exercise
/// specific states (e.g. an empty weight history for the empty-state test).
class FakeAnalyticsRepository implements AnalyticsRepository {
  FakeAnalyticsRepository({
    List<DailyCalories>? weeklyCalories,
    MacroBreakdown? macroBreakdown,
    List<WeightEntry>? weightHistory,
    double? calorieGoal,
    UserProfile? userProfile,
  })  : _weeklyCalories = weeklyCalories ?? _defaultWeeklyCalories,
        _macroBreakdown = macroBreakdown ?? _defaultMacroBreakdown,
        _weightHistory = List.of(weightHistory ?? _defaultWeightHistory),
        _calorieGoal = calorieGoal ?? 2200,
        userProfile = userProfile ?? const UserProfile();

  final List<DailyCalories> _weeklyCalories;
  final MacroBreakdown _macroBreakdown;
  final List<WeightEntry> _weightHistory;
  final double _calorieGoal;

  /// Records the last entry passed to `updateWeightEntry`, and the last id
  /// passed to `deleteWeightEntry`.
  WeightEntry? lastUpdatedWeightEntry;
  int? lastDeletedWeightEntryId;

  /// Mutable so tests can assert what `updateUserProfile` was called with.
  UserProfile userProfile;

  final List<({double weightKg, String goalType})> loggedWeights = [];

  static final _defaultWeeklyCalories = List.generate(
    7,
    (i) => DailyCalories(
      date: DateTime(2026, 7, 20 + i),
      totalCalories: 1800 + (i * 50),
    ),
  );

  static const _defaultMacroBreakdown = MacroBreakdown(
    proteinG: 120,
    carbsG: 200,
    fatG: 70,
  );

  static final _defaultWeightHistory = [
    WeightEntry(
      id: 1,
      loggedAt: DateTime(2026, 6, 1),
      weightKg: 82.5,
      goalType: 'lose',
    ),
    WeightEntry(
      id: 2,
      loggedAt: DateTime(2026, 7, 1),
      weightKg: 80.1,
      goalType: 'lose',
    ),
  ];

  @override
  Future<List<DailyCalories>> getWeeklyCalories(DateTime weekStart) async {
    return _weeklyCalories;
  }

  @override
  Future<MacroBreakdown> getMacroBreakdown(
    DateTime rangeStart,
    DateTime rangeEnd,
  ) async {
    return _macroBreakdown;
  }

  @override
  Future<List<WeightEntry>> getWeightHistory() async => _weightHistory;

  @override
  Future<double> getCalorieGoal() async => _calorieGoal;

  @override
  Future<void> logWeight(double weightKg, String goalType) async {
    loggedWeights.add((weightKg: weightKg, goalType: goalType));
  }

  /// Records the last batch passed to `importWeightEntries`.
  List<({DateTime loggedAt, double weightKg})>? lastImportedEntries;
  String? lastImportedGoalType;

  @override
  Future<void> importWeightEntries(
    List<({DateTime loggedAt, double weightKg})> entries, {
    required String goalType,
  }) async {
    lastImportedEntries = entries;
    lastImportedGoalType = goalType;
    var nextId = _weightHistory.isEmpty
        ? 1
        : _weightHistory.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1;
    for (final entry in entries) {
      _weightHistory.add(
        WeightEntry(
          id: nextId++,
          loggedAt: entry.loggedAt,
          weightKg: entry.weightKg,
          goalType: goalType,
        ),
      );
    }
  }

  @override
  Future<void> updateWeightEntry(WeightEntry entry) async {
    lastUpdatedWeightEntry = entry;
    final index = _weightHistory.indexWhere((e) => e.id == entry.id);
    if (index != -1) _weightHistory[index] = entry;
  }

  @override
  Future<void> deleteWeightEntry(int id) async {
    lastDeletedWeightEntryId = id;
    _weightHistory.removeWhere((e) => e.id == id);
  }

  @override
  Future<UserProfile> getUserProfile() async => userProfile;

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    userProfile = profile;
  }
}
