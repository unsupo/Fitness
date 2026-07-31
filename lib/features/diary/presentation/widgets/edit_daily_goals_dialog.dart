import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../analytics/domain/use_cases/compute_weekly_averages.dart';
import '../../../analytics/domain/use_cases/estimate_tdee.dart';
import '../../../analytics/domain/use_cases/weight_unit.dart';
import '../../../analytics/presentation/controllers/analytics_providers.dart';
import '../../domain/entities/daily_goals.dart';
import '../../domain/use_cases/macro_calorie_split.dart';
import '../../../profile/domain/use_cases/weekly_rate_calorie_goal.dart';
import '../controllers/diary_providers.dart';
import 'adjustable_macro_pie_chart.dart';

/// Edits the plain daily calorie/macro targets on the single `daily_goals`
/// row. Distinct from `showEditWeightGoalDialog` (analytics feature), which
/// edits the biometric/weight-projection fields on the same row.
/// Includes the bidirectional weekly-loss <=> calorie-goal calculator.
Future<void> showEditDailyGoalsDialog(
  BuildContext context,
  WidgetRef ref,
  DailyGoals current,
) {
  String display(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();

  final calorieController = TextEditingController(
    text: display(current.calorieGoal),
  );
  var error = '';

  // Store whether we initialized the slider value to prevent resetting on every state rebuild
  var sliderInitialized = false;
  var sliderVal = 0.0;

  // The macro pie's own state — grams, kept in sync with calorieController
  // (see _rescaleMacrosToCalories below) so the pie's total always equals
  // the calorie goal, not just whatever the macros happen to sum to.
  var proteinG = current.proteinGoalG;
  var carbsG = current.carbsGoalG;
  var fatG = current.fatGoalG;

  /// Rescales the macro split proportionally so its kcal total matches
  /// [newCalorieGoal] exactly, preserving the current percentage split —
  /// called whenever the calorie goal changes (typed or via the weekly-rate
  /// slider), so the pie chart never drifts out of sync with its own total.
  void rescaleMacrosToCalories(double newCalorieGoal) {
    final split = macroCalorieSplitFromGrams(
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
    );
    if (split.totalKcal <= 0) return;
    final scale = newCalorieGoal / split.totalKcal;
    final rescaled = macroGramsFromCalorieSplit(
      MacroCalorieSplit(
        proteinKcal: split.proteinKcal * scale,
        carbsKcal: split.carbsKcal * scale,
        fatKcal: split.fatKcal * scale,
      ),
    );
    proteinG = rescaled.proteinG;
    carbsG = rescaled.carbsG;
    fatG = rescaled.fatG;
  }

  void setMacroGrams({
    required double protein,
    required double carbs,
    required double fat,
  }) {
    proteinG = protein;
    carbsG = carbs;
    fatG = fat;
  }

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

              final hasTdeeInputs =
                  profile != null && profile.isCompleteForTdee;
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
                tdee = estimateTdee(
                  profile: profile,
                  weightKg: currentWeightKg,
                );

                unit = weightUnitFor(profile.unitSystem);
                if (profile.unitSystem == 'us') {
                  sliderMin = -3.0;
                  sliderMax = 3.0;
                  sliderDivisions = 24;
                }

                if (!sliderInitialized) {
                  final initialCalories =
                      double.tryParse(calorieController.text) ??
                      current.calorieGoal;
                  final initialRateKg = weeklyRateForCalorieGoal(
                    tdee: tdee,
                    calorieGoal: initialCalories,
                  );
                  final initialRateDisplay = unit == 'lb'
                      ? kgToLb(initialRateKg)
                      : initialRateKg;
                  // Round to nearest 0.25 and clamp
                  sliderVal = ((initialRateDisplay / 0.25).round() * 0.25)
                      .clamp(sliderMin, sliderMax);
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
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                        ),
                        onChanged: (text) {
                          final val = double.tryParse(text);
                          if (val == null || val <= 0) return;
                          setState(() {
                            rescaleMacrosToCalories(val);
                            if (canCalculate && tdee != null) {
                              final rateKg = weeklyRateForCalorieGoal(
                                tdee: tdee,
                                calorieGoal: val,
                              );
                              final rateDisplay = unit == 'lb'
                                  ? kgToLb(rateKg)
                                  : rateKg;
                              sliderVal = ((rateDisplay / 0.25).round() * 0.25)
                                  .clamp(sliderMin, sliderMax);
                            }
                          });
                        },
                      ),
                      if (canCalculate && tdee != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Estimated TDEE: ${tdee.round()} kcal',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Weekly Rate',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            Text(
                              sliderVal == 0.0
                                  ? 'Maintain weight'
                                  : sliderVal < 0
                                  ? 'Lose ${sliderVal.abs().toStringAsFixed(2)} $unit/week'
                                  : 'Gain ${sliderVal.toStringAsFixed(2)} $unit/week',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
                              final newCal = calorieGoalForWeeklyRate(
                                tdee: tdee!,
                                weeklyRateKg: rateKg,
                              );
                              calorieController.text = newCal
                                  .round()
                                  .toString();
                              rescaleMacrosToCalories(newCal);
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
                            style: TextStyle(
                              color: Colors.amber.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      const Text(
                        'Macro split',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Text(
                        'Drag the ring to adjust — the pie always totals '
                        'your calorie goal.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: AdjustableMacroPieChart(
                          key: const Key('macro-pie-chart'),
                          proteinG: proteinG,
                          carbsG: carbsG,
                          fatG: fatG,
                          onChanged:
                              ({
                                required double proteinG,
                                required double carbsG,
                                required double fatG,
                              }) {
                                setState(() {
                                  // The callback's params shadow the outer
                                  // proteinG/carbsG/fatG on purpose (matches
                                  // the widget's own parameter names) — assign
                                  // through the dialog-scoped setter fields.
                                  setMacroGrams(
                                    protein: proteinG,
                                    carbs: carbsG,
                                    fat: fatG,
                                  );
                                });
                              },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _MacroLegendRow(
                        key: const Key('goals-protein-legend'),
                        color: AppColors.proteinRing,
                        label: 'Protein',
                        grams: proteinG,
                      ),
                      _MacroLegendRow(
                        key: const Key('goals-carbs-legend'),
                        color: AppColors.carbsRing,
                        label: 'Carbs',
                        grams: carbsG,
                      ),
                      _MacroLegendRow(
                        key: const Key('goals-fat-legend'),
                        color: AppColors.fatRing,
                        label: 'Fat',
                        grams: fatG,
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

                      if (calories == null || calories <= 0) {
                        setState(
                          () => error = 'Enter a valid number of calories.',
                        );
                        return;
                      }

                      final protein = proteinG;
                      final carbs = carbsG;
                      final fat = fatG;

                      await ref
                          .read(diaryRepositoryProvider)
                          .updateDailyGoals(
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
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.brandGreen,
                    ),
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

/// One row of the macro pie's legend — a color dot, label, and live gram
/// value, updated as the pie is dragged.
class _MacroLegendRow extends StatelessWidget {
  const _MacroLegendRow({
    super.key,
    required this.color,
    required this.label,
    required this.grams,
  });

  final Color color;
  final String label;
  final double grams;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            '${grams.round()}g',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
