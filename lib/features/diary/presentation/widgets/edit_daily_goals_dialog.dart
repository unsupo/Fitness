import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../analytics/domain/use_cases/compute_weekly_averages.dart';
import '../../../analytics/domain/use_cases/estimate_tdee.dart';
import '../../../analytics/domain/use_cases/weight_unit.dart';
import '../../../analytics/presentation/controllers/analytics_providers.dart';
import '../../domain/entities/daily_goals.dart';
import '../../../profile/domain/use_cases/weekly_rate_calorie_goal.dart';
import '../controllers/diary_providers.dart';

/// Edits the plain daily calorie/macro targets on the single `daily_goals`
/// row. Distinct from `showEditWeightGoalDialog` (analytics feature), which
/// edits the biometric/weight-projection fields on the same row.
/// Includes the bidirectional weekly-loss <=> calorie-goal calculator.
Future<void> showEditDailyGoalsDialog(
  BuildContext context,
  WidgetRef ref,
  DailyGoals current,
) {
  String display(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  final calorieController = TextEditingController(text: display(current.calorieGoal));
  final proteinController = TextEditingController(text: display(current.proteinGoalG));
  final carbsController = TextEditingController(text: display(current.carbsGoalG));
  final fatController = TextEditingController(text: display(current.fatGoalG));
  var error = '';

  // Store whether we initialized the slider value to prevent resetting on every state rebuild
  var sliderInitialized = false;
  var sliderVal = 0.0;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Consumer(
        builder: (context, ref, _) {
          final profileAsync = ref.watch(userProfileProvider);
          final weightHistoryAsync = ref.watch(weightHistoryProvider);

          return StatefulBuilder(
            builder: (dialogContext, setState) {
              final profile = profileAsync.asData?.value;
              final history = weightHistoryAsync.asData?.value;

              final hasTdeeInputs = profile != null && profile.isCompleteForTdee;
              final hasWeightHistory = history != null && history.isNotEmpty;
              final canCalculate = hasTdeeInputs && hasWeightHistory;

              double? tdee;
              double sliderMin = -1.5;
              double sliderMax = 1.5;
              int sliderDivisions = 12;
              String unit = 'kg';

              if (canCalculate) {
                final weeklyAverages = computeWeeklyAverages(history);
                final currentWeightKg = weeklyAverages.isNotEmpty 
                    ? weeklyAverages.last.avgWeightKg 
                    : history.last.weightKg;
                tdee = estimateTdee(profile: profile, weightKg: currentWeightKg);

                unit = weightUnitFor(profile.unitSystem);
                if (profile.unitSystem == 'us') {
                  sliderMin = -3.0;
                  sliderMax = 3.0;
                  sliderDivisions = 24;
                }

                if (!sliderInitialized) {
                  final initialCalories = double.tryParse(calorieController.text) ?? current.calorieGoal;
                  final initialRateKg = weeklyRateForCalorieGoal(tdee: tdee, calorieGoal: initialCalories);
                  final initialRateDisplay = unit == 'lb' ? kgToLb(initialRateKg) : initialRateKg;
                  // Round to nearest 0.25 and clamp
                  sliderVal = ((initialRateDisplay / 0.25).round() * 0.25).clamp(sliderMin, sliderMax);
                  sliderInitialized = true;
                }
              }

              return AlertDialog(
                title: const Text('Daily goals'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        key: const Key('goals-calorie-field'),
                        controller: calorieController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Calories'),
                        onChanged: (text) {
                          if (canCalculate && tdee != null) {
                            final val = double.tryParse(text);
                            if (val != null && val > 0) {
                              final rateKg = weeklyRateForCalorieGoal(tdee: tdee, calorieGoal: val);
                              final rateDisplay = unit == 'lb' ? kgToLb(rateKg) : rateKg;
                              setState(() {
                                sliderVal = ((rateDisplay / 0.25).round() * 0.25).clamp(sliderMin, sliderMax);
                              });
                            }
                          }
                        },
                      ),
                      if (canCalculate && tdee != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Estimated TDEE: ${tdee.round()} kcal',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Weekly Rate', style: TextStyle(color: AppColors.textSecondary)),
                            Text(
                              sliderVal == 0.0
                                  ? 'Maintain weight'
                                  : sliderVal < 0
                                      ? 'Lose ${sliderVal.abs().toStringAsFixed(2)} $unit/week'
                                      : 'Gain ${sliderVal.toStringAsFixed(2)} $unit/week',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          key: const Key('weekly-rate-slider'),
                          value: sliderVal,
                          min: sliderMin,
                          max: sliderMax,
                          divisions: sliderDivisions,
                          onChanged: (val) {
                            setState(() {
                              sliderVal = val;
                              final rateKg = unit == 'lb' ? lbToKg(val) : val;
                              final newCal = calorieGoalForWeeklyRate(tdee: tdee!, weeklyRateKg: rateKg);
                              calorieController.text = newCal.round().toString();
                            });
                          },
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Text(
                            !hasTdeeInputs
                                ? 'Add sex, age, height, and activity level to your profile to enable the weekly rate calculator.'
                                : 'Log your weight to enable the weekly rate calculator.',
                            style: TextStyle(color: Colors.amber.shade900, fontSize: 12),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('goals-protein-field'),
                        controller: proteinController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Protein (g)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('goals-carbs-field'),
                        controller: carbsController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Carbs (g)'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        key: const Key('goals-fat-field'),
                        controller: fatController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(labelText: 'Fat (g)'),
                      ),
                      if (error.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(error, style: const TextStyle(color: Colors.red)),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      final calories = double.tryParse(calorieController.text);
                      final protein = double.tryParse(proteinController.text);
                      final carbs = double.tryParse(carbsController.text);
                      final fat = double.tryParse(fatController.text);

                      if (calories == null ||
                          protein == null ||
                          carbs == null ||
                          fat == null ||
                          calories <= 0) {
                        setState(() => error = 'Enter valid numbers for every field.');
                        return;
                      }

                      await ref.read(diaryRepositoryProvider).updateDailyGoals(
                        DailyGoals(
                          calorieGoal: calories,
                          proteinGoalG: protein,
                          carbsGoalG: carbs,
                          fatGoalG: fat,
                        ),
                      );
                      ref.invalidate(dailyGoalsProvider);
                      // Invalidate calorieGoalProvider (analytics feature) as well so they are in sync
                      ref.invalidate(calorieGoalProvider);
                      if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                    },
                    style: TextButton.styleFrom(foregroundColor: AppColors.brandGreen),
                    child: const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    },
  );
}
