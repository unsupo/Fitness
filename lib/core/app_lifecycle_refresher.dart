import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/analytics/presentation/controllers/analytics_providers.dart';
import '../features/diary/presentation/controllers/diary_providers.dart';
import '../features/recipes/presentation/controllers/recipes_providers.dart';
import '../features/workouts/presentation/controllers/exercises_providers.dart';
import '../features/workouts/presentation/controllers/history_providers.dart';
import '../features/workouts/presentation/controllers/log_providers.dart';
import '../features/workouts/presentation/controllers/workout_repository_provider.dart';

/// Invalidates the app's cached data whenever the app returns to the
/// foreground (e.g. the user switches back from another app, or unlocks
/// their phone). Riverpod's `FutureProvider`s only refetch when told to —
/// they have no way to know the underlying data changed (e.g. a row edited
/// directly in Supabase, or from another device) unless something
/// explicitly invalidates them. This plus pull-to-refresh on the Home and
/// Extras tabs are the two ways data gets refreshed without an in-app
/// write triggering it.
class AppLifecycleRefresher extends ConsumerStatefulWidget {
  const AppLifecycleRefresher({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleRefresher> createState() =>
      _AppLifecycleRefresherState();
}

class _AppLifecycleRefresherState extends ConsumerState<AppLifecycleRefresher>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Family providers invalidate every cached instance when called with
      // no argument — correct here since we don't know which date/week was
      // last viewed.
      ref.invalidate(diaryEntriesProvider);
      ref.invalidate(dailyGoalsProvider);
      ref.invalidate(weeklyCaloriesProvider);
      ref.invalidate(macroBreakdownProvider);
      ref.invalidate(weightHistoryProvider);
      ref.invalidate(calorieGoalProvider);
      ref.invalidate(userProfileProvider);
      ref.invalidate(recipesListProvider);
      ref.invalidate(machinesProvider);
      ref.invalidate(lastSessionProvider);
      ref.invalidate(sessionSetsProvider);
      ref.invalidate(sessionHistoryProvider);
      ref.invalidate(setsForSessionProvider);
      ref.invalidate(setsForMachineProvider);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
