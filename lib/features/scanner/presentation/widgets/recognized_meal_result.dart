import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../diary/domain/entities/daily_goals.dart';
import '../../../diary/domain/entities/daily_totals.dart';
import '../../../diary/domain/use_cases/compute_remaining_after_adding.dart';
import '../../domain/entities/recognized_meal.dart';
import 'stat_column.dart';

/// The AI-recognition result view (mockup Image 3: hero image + macro
/// breakdown + serving stepper + save), extracted so it's unit-testable
/// given a fixed [RecognizedMeal] without needing a real `camera` plugin in
/// the test.
class RecognizedMealResult extends StatefulWidget {
  const RecognizedMealResult({
    super.key,
    required this.meal,
    required this.onSave,
    this.capturedImage,
    this.currentTotals,
    this.goals,
  });

  final RecognizedMeal meal;
  final ValueChanged<RecognizedMeal> onSave;

  /// The photo captured by the `camera` flow, if any. When absent, a plain
  /// colored placeholder is shown instead (no stock photo is fetched).
  final XFile? capturedImage;

  /// Today's totals/goals, fetched once by the parent page — static inputs
  /// only; this widget itself multiplies by its own live `_servings` state
  /// and recomputes "remaining after adding" fresh on every build. Null when
  /// unknown (e.g. the fetch failed), in which case no caution is shown.
  final DailyTotals? currentTotals;
  final DailyGoals? goals;

  @override
  State<RecognizedMealResult> createState() => _RecognizedMealResultState();
}

class _RecognizedMealResultState extends State<RecognizedMealResult> {
  static const _step = 0.5;
  static const _minServings = 0.5;

  late double _servings = widget.meal.servings;

  void _incrementServings() {
    setState(() => _servings += _step);
  }

  void _decrementServings() {
    setState(() {
      final next = _servings - _step;
      _servings = next < _minServings ? _minServings : next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal;
    final image = widget.capturedImage;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: double.infinity,
              height: 220,
              child: image != null
                  ? Image.file(File(image.path), fit: BoxFit.cover)
                  : Container(color: AppColors.ringTrack),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            meal.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            '~${meal.estimatedCalories.round()} kcal',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              StatColumn(
                label: 'Calories',
                value: meal.estimatedCalories.round().toString(),
                color: AppColors.accentOrange,
              ),
              StatColumn(
                label: 'Protein',
                value: '${meal.proteinG.round()}g',
                color: AppColors.proteinRing,
              ),
              StatColumn(
                label: 'Carbs',
                value: '${meal.carbsG.round()}g',
                color: AppColors.carbsRing,
              ),
              StatColumn(
                label: 'Fat',
                value: '${meal.fatG.round()}g',
                color: AppColors.fatRing,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _decrementServings,
              ),
              SizedBox(
                width: 48,
                child: Text(
                  _servings.toStringAsFixed(1),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _incrementServings,
              ),
            ],
          ),
          _buildRemainingCaution(meal),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.onSave(meal.copyWith(servings: _servings)),
              child: const Text('Save to Diary'),
            ),
          ),
        ],
      ),
    );
  }

  /// Recomputed on every build from the widget's own live `_servings` state
  /// — never a value passed down once, so it stays in sync with the +/-
  /// stepper without needing any `ref`/Riverpod dependency in this widget.
  Widget _buildRemainingCaution(RecognizedMeal meal) {
    final currentTotals = widget.currentTotals;
    final goals = widget.goals;
    if (currentTotals == null || goals == null) return const SizedBox.shrink();

    final remaining = computeRemainingAfterAdding(
      currentTotals: currentTotals,
      goals: goals,
      addedCalories: meal.estimatedCalories * _servings,
      addedProteinG: meal.proteinG * _servings,
      addedCarbsG: meal.carbsG * _servings,
      addedFatG: meal.fatG * _servings,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${remaining.remainingCalories.round()} kcal left today after adding this',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (remaining.isOverCalorieGoal)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'This puts you ${(-remaining.remainingCalories).round()} kcal over your daily goal.',
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}
