import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_totals.dart';
import 'package:flutter/material.dart';

/// The "Daily Calories" section: consumed/goal text plus a progress bar.
class DailyCalorieCard extends StatelessWidget {
  const DailyCalorieCard({super.key, required this.totals, required this.goals});

  final DailyTotals totals;
  final DailyGoals goals;

  @override
  Widget build(BuildContext context) {
    final progress = goals.calorieGoal == 0
        ? 0.0
        : (totals.calories / goals.calorieGoal).clamp(0.0, 1.0);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Calories',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '${totals.calories.round()} / ${goals.calorieGoal.round()} cal',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.ringTrack,
              valueColor: const AlwaysStoppedAnimation(AppColors.brandGreen),
            ),
          ),
        ],
      ),
    );
  }
}
