import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../analytics/domain/entities/user_profile.dart';
import '../../../analytics/domain/use_cases/height_unit.dart';
import '../../../analytics/domain/use_cases/weight_unit.dart';
import '../../../analytics/presentation/controllers/analytics_providers.dart';
import '../../../analytics/presentation/widgets/edit_weight_goal_dialog.dart';
import '../../../diary/domain/entities/daily_goals.dart';
import '../../../diary/presentation/controllers/diary_providers.dart';
import '../../../diary/presentation/widgets/edit_daily_goals_dialog.dart';
import '../../../workouts/presentation/controllers/overload_providers.dart';

const _activityLabels = {
  'sedentary': 'Sedentary',
  'light': 'Light activity',
  'moderate': 'Moderate activity',
  'active': 'Active',
  'extra_active': 'Extra active',
};

/// The Profile tab: the one real settings hub in the app. Composes two
/// pieces of the single `daily_goals` row — plain calorie/macro targets
/// (edited here for the first time; previously had no UI anywhere) and the
/// biometric/weight-goal profile (previously only reachable via a gear icon
/// on the Trends page, still available there too).
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Nourish'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: const [
            _DailyGoalsSection(),
            SizedBox(height: 16),
            _BiometricProfileSection(),
            SizedBox(height: 16),
            _TrainingPreferencesSection(),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalsSection extends ConsumerWidget {
  const _DailyGoalsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Daily Goals',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              goalsAsync.maybeWhen(
                data: (goals) => IconButton(
                  key: const Key('edit-daily-goals-button'),
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  tooltip: 'Edit daily goals',
                  onPressed: () => showEditDailyGoalsDialog(context, ref, goals),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          goalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Error: $error'),
            data: (goals) => _DailyGoalsBody(goals: goals),
          ),
        ],
      ),
    );
  }
}

class _DailyGoalsBody extends StatelessWidget {
  const _DailyGoalsBody({required this.goals});

  final DailyGoals goals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatRow(label: 'Calories', value: '${goals.calorieGoal.round()} cal'),
        _StatRow(label: 'Protein', value: '${goals.proteinGoalG.round()} g'),
        _StatRow(label: 'Carbs', value: '${goals.carbsGoalG.round()} g'),
        _StatRow(label: 'Fat', value: '${goals.fatGoalG.round()} g'),
      ],
    );
  }
}

class _BiometricProfileSection extends ConsumerWidget {
  const _BiometricProfileSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              profileAsync.maybeWhen(
                data: (profile) => IconButton(
                  key: const Key('edit-profile-button'),
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  tooltip: 'Edit profile',
                  onPressed: () =>
                      showEditWeightGoalDialog(context, ref, profile),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Text('Error: $error'),
            data: (profile) {
              if (!profile.isCompleteForTdee) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add your sex, age, height, and activity level to '
                      'estimate your daily energy needs and project a '
                      'weight goal.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () =>
                          showEditWeightGoalDialog(context, ref, profile),
                      child: const Text('Set up profile'),
                    ),
                  ],
                );
              }
              return _BiometricProfileBody(profile: profile);
            },
          ),
        ],
      ),
    );
  }
}

class _BiometricProfileBody extends StatelessWidget {
  const _BiometricProfileBody({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final unit = weightUnitFor(profile.unitSystem);
    final heightLabel = profile.unitSystem == 'us'
        ? () {
            final feetInches = cmToFeetInches(profile.heightCm!);
            return '${feetInches.feet}\' '
                '${formatNumberForDisplay(feetInches.inches)}"';
          }()
        : '${formatNumberForDisplay(profile.heightCm!)} cm';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatRow(
          label: 'Sex',
          value: profile.sex == 'female' ? 'Female' : 'Male',
        ),
        _StatRow(label: 'Age', value: '${profile.age}'),
        _StatRow(label: 'Height', value: heightLabel),
        _StatRow(
          label: 'Activity level',
          value: _activityLabels[profile.activityLevel] ?? profile.activityLevel!,
        ),
        _StatRow(
          label: 'Target weight',
          value: profile.targetWeightKg == null
              ? 'Not set'
              : '${formatNumberForDisplay(displayWeight(profile.targetWeightKg!, unit: unit))} $unit',
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _TrainingPreferencesSection extends ConsumerWidget {
  const _TrainingPreferencesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focus = ref.watch(trainingFocusProvider);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Training Preferences',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: const Key('training-focus-dropdown'),
            initialValue: focus,
            decoration: const InputDecoration(
              labelText: 'Training Focus',
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: const [
              DropdownMenuItem(value: 'hypertrophy', child: Text('Hypertrophy (Muscle Growth)')),
              DropdownMenuItem(value: 'strength', child: Text('Strength Training')),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(trainingFocusProvider.notifier).setFocus(value);
              }
            },
          ),
        ],
      ),
    );
  }
}
