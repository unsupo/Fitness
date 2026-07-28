import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/daily_goals.dart';
import '../controllers/diary_providers.dart';

/// Edits the plain daily calorie/macro targets on the single `daily_goals`
/// row. Distinct from `showEditWeightGoalDialog` (analytics feature), which
/// edits the biometric/weight-projection fields on the same row.
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

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
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
                  ),
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
}
