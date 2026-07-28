import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

import '../../../../core/di/backend.dart';
import '../../domain/entities/daily_calories.dart';
import '../../domain/entities/macro_breakdown.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/repositories/analytics_repository.dart';

/// Params for [macroBreakdownProvider] — a small record wrapper so it can be
/// used as a `FutureProvider.family` key.
typedef MacroRangeParams = ({DateTime start, DateTime end});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>(
  (ref) => ref.watch(backendProvider).createAnalyticsRepository(),
);

/// The Monday (or whatever the caller passes) currently shown by the Weekly
/// Calories section — shifted by the `<` / `>` chevrons on the Trends page.
final selectedWeekStartProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  return today.subtract(Duration(days: today.weekday - 1));
});

final weeklyCaloriesProvider = FutureProvider.family<List<DailyCalories>, DateTime>(
  (ref, weekStart) {
    return ref.watch(analyticsRepositoryProvider).getWeeklyCalories(weekStart);
  },
);

final macroBreakdownProvider =
    FutureProvider.family<MacroBreakdown, MacroRangeParams>((ref, params) {
  return ref
      .watch(analyticsRepositoryProvider)
      .getMacroBreakdown(params.start, params.end);
});

final weightHistoryProvider = FutureProvider<List<WeightEntry>>((ref) {
  return ref.watch(analyticsRepositoryProvider).getWeightHistory();
});

final calorieGoalProvider = FutureProvider<double>((ref) {
  return ref.watch(analyticsRepositoryProvider).getCalorieGoal();
});

/// Which of the three Trends segmented-control tabs is selected: 0 = Weekly
/// (calories chart only), 1 = Progress (macro + weight), 2 = Trends (all
/// three — the default, matching the mockup).
final selectedTrendsTabProvider = StateProvider<int>((ref) => 2);

final userProfileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(analyticsRepositoryProvider).getUserProfile();
});
