import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import 'log_last_workout_card.dart';

/// The Log tab's idle-state body: a "last workout" summary card and a
/// prominent "Start Workout" CTA. Styled to match the app's other primary
/// action buttons (see `edit_weight_goal_dialog.dart`'s button styling
/// pattern), using [AppColors.accentOrange].
class LogIdleView extends StatelessWidget {
  const LogIdleView({super.key, required this.onStartWorkout});

  final Future<void> Function() onStartWorkout;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const LogLastWorkoutCard(),
          const SizedBox(height: 24),
          FilledButton(
            key: const Key('start-workout-button'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            onPressed: onStartWorkout,
            child: const Text('Start Workout'),
          ),
        ],
      ),
    );
  }
}
