import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/compute_daily_totals.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/use_cases/compute_recipe_totals.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dialog to select meal type and quantity/servings before logging a recipe,
/// showing a live macro preview and a collapsible ingredient list.
class LogRecipeDialog extends ConsumerStatefulWidget {
  const LogRecipeDialog({super.key, required this.recipe});

  final Recipe recipe;

  @override
  ConsumerState<LogRecipeDialog> createState() => _LogRecipeDialogState();
}

class _LogRecipeDialogState extends ConsumerState<LogRecipeDialog> {
  final _quantityController = TextEditingController(text: '1');
  MealType _selectedMeal = MealType.snack;
  double _loggedQuantity = 1.0;

  @override
  void initState() {
    super.initState();
    _quantityController.addListener(() {
      setState(() {
        _loggedQuantity = double.tryParse(_quantityController.text) ?? 1.0;
      });
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recipe = widget.recipe;
    final perServing = recipePerServing(recipe);

    final selectedDate = ref.watch(selectedDateProvider);
    final entriesAsync = ref.watch(diaryEntriesProvider(selectedDate));
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return AlertDialog(
      title: Text('Log ${recipe.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Whole recipe: ${recipeTotals(recipe).calories.round()} kcal | ${recipe.servings.round()} servings',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Servings to log',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<MealType>(
                    initialValue: _selectedMeal,
                    decoration: const InputDecoration(
                      labelText: 'Meal',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (final meal in MealType.values)
                        DropdownMenuItem(
                          value: meal,
                          child: Text(meal.name[0].toUpperCase() + meal.name.substring(1)),
                        ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedMeal = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Collapsible ingredient list
            ExpansionTile(
              title: Text('Ingredients (${recipe.ingredients.length})'),
              subtitle: const Text('Tap to expand', style: TextStyle(fontSize: 12)),
              children: [
                for (final ing in recipe.ingredients)
                  ListTile(
                    dense: true,
                    title: Text(ing.foodName),
                    subtitle: Text(
                      '${(ing.calories * _loggedQuantity / recipe.servings).round()} kcal | '
                      '${ing.quantity.amount * _loggedQuantity / recipe.servings} ${ing.quantity.unit}',
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            goalsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (err, stack) => const SizedBox.shrink(),
              data: (goals) => entriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
                data: (entries) {
                  final currentTotals = computeDailyTotals(entries);

                  final addedCalories = perServing.calories * _loggedQuantity;
                  final addedProtein = perServing.proteinG * _loggedQuantity;
                  final addedCarbs = perServing.carbsG * _loggedQuantity;
                  final addedFat = perServing.fatG * _loggedQuantity;

                  final projectedCalories = currentTotals.calories + addedCalories;
                  final projectedProtein = currentTotals.proteinG + addedProtein;
                  final projectedCarbs = currentTotals.carbsG + addedCarbs;
                  final projectedFat = currentTotals.fatG + addedFat;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Projected Daily Totals',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _ProjectedRow(
                        label: 'Calories',
                        current: currentTotals.calories,
                        projected: projectedCalories,
                        target: goals.calorieGoal.toDouble(),
                        unit: ' kcal',
                      ),
                      const SizedBox(height: 8),
                      _ProjectedRow(
                        label: 'Protein',
                        current: currentTotals.proteinG,
                        projected: projectedProtein,
                        target: goals.proteinGoalG.toDouble(),
                        unit: 'g',
                      ),
                      const SizedBox(height: 8),
                      _ProjectedRow(
                        label: 'Carbs',
                        current: currentTotals.carbsG,
                        projected: projectedCarbs,
                        target: goals.carbsGoalG.toDouble(),
                        unit: 'g',
                      ),
                      const SizedBox(height: 8),
                      _ProjectedRow(
                        label: 'Fat',
                        current: currentTotals.fatG,
                        projected: projectedFat,
                        target: goals.fatGoalG.toDouble(),
                        unit: 'g',
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            await ref.read(recipeRepositoryProvider).logRecipeToDiary(
              recipe.id,
              _selectedMeal,
              portionQuantity: _loggedQuantity,
            );

            ref.invalidate(recipesListProvider);
            ref.invalidate(diaryEntriesProvider(selectedDate));

            if (context.mounted) {
              Navigator.pop(context);
            }
          },
          child: const Text('Log'),
        ),
      ],
    );
  }
}

class _ProjectedRow extends StatelessWidget {
  const _ProjectedRow({
    required this.label,
    required this.current,
    required this.projected,
    required this.target,
    required this.unit,
  });

  final String label;
  final double current;
  final double projected;
  final double target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text(
              '${current.round()} → ${projected.round()} / ${target.round()}$unit',
              style: TextStyle(
                fontSize: 12,
                color: projected > target ? Colors.red : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: target > 0 ? (projected / target).clamp(0.0, 1.0) : 0.0,
            backgroundColor: AppColors.background,
            color: projected > target ? Colors.red : AppColors.accentOrange,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

/// Helper function to show log recipe dialog.
void showLogRecipeDialog(BuildContext context, Recipe recipe) {
  showDialog<void>(
    context: context,
    builder: (context) => LogRecipeDialog(recipe: recipe),
  );
}
