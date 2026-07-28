import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'exercises_tab.dart';
import 'history_tab.dart';
import 'log_tab.dart';

/// Entry point for the Workouts section, reached via the drawer
/// (`AppDrawer`) opened from the hamburger icon on Home/Trends/Profile/
/// Recipes. Mirrors Strong's own bottom tabs (Workout / History /
/// Exercises) as an internal `TabBar` rather than a 6th app-wide bottom-nav
/// tab — see docs/WORKOUTS_PLAN.md for why. Wired centrally at `/workouts`
/// in `app_router.dart`; the three tab bodies (`LogTab`, `HistoryTab`,
/// `ExercisesTab`) were each built by their own agent and own no
/// `Scaffold`/`AppBar` of their own.
class WorkoutsShellPage extends StatelessWidget {
  const WorkoutsShellPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: Navigator.of(context).canPop()
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : null,
          title: const Text('Workouts'),
          bottom: const TabBar(
            labelColor: AppColors.brandGreen,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.accentOrange,
            tabs: [
              Tab(text: 'Log'),
              Tab(text: 'History'),
              Tab(text: 'Exercises'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [LogTab(), HistoryTab(), ExercisesTab()],
        ),
      ),
    );
  }
}
