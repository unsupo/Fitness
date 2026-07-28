import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../controllers/log_providers.dart';
import '../controllers/workout_repository_provider.dart';
import 'log_last_workout_card.dart';

/// The Log tab's idle-state body: a "last workout" summary card and a
/// prominent "Start Workout" CTA. Styled to match the app's other primary
/// action buttons (see `edit_weight_goal_dialog.dart`'s button styling
/// pattern), using [AppColors.accentOrange].
class LogIdleView extends ConsumerWidget {
  const LogIdleView({
    super.key,
    required this.onStartWorkout,
    required this.onRepeatWorkout,
  });

  final Future<void> Function() onStartWorkout;

  /// "Repeat this workout" — starts a session pre-loaded with the given
  /// machines (see docs/features/workouts-log-redesign.md).
  final Future<void> Function(List<Machine> machines) onRepeatWorkout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await Future.wait([
            ref.refresh(machinesProvider.future),
            ref.refresh(lastSessionProvider.future),
          ]);
          ref.invalidate(sessionSetsProvider);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            LogLastWorkoutCard(onRepeat: onRepeatWorkout),
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
      ),
    );
  }
}
