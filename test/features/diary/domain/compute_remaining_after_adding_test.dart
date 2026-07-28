import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_totals.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/compute_remaining_after_adding.dart';

void main() {
  const goals = DailyGoals(
    calorieGoal: 2000,
    proteinGoalG: 150,
    carbsGoalG: 200,
    fatGoalG: 65,
  );

  group('computeRemainingAfterAdding', () {
    test('subtracts current totals and the item being added from goals', () {
      const currentTotals = DailyTotals(
        calories: 1200,
        proteinG: 80,
        carbsG: 120,
        fatG: 40,
      );

      final remaining = computeRemainingAfterAdding(
        currentTotals: currentTotals,
        goals: goals,
        addedCalories: 300,
        addedProteinG: 20,
        addedCarbsG: 30,
        addedFatG: 10,
      );

      expect(remaining.remainingCalories, 500);
      expect(remaining.remainingProteinG, 50);
      expect(remaining.remainingCarbsG, 50);
      expect(remaining.remainingFatG, 15);
      expect(remaining.isOverCalorieGoal, isFalse);
    });

    test('isOverCalorieGoal is true once remaining calories go negative', () {
      const currentTotals = DailyTotals(
        calories: 1900,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      );

      final remaining = computeRemainingAfterAdding(
        currentTotals: currentTotals,
        goals: goals,
        addedCalories: 200,
        addedProteinG: 0,
        addedCarbsG: 0,
        addedFatG: 0,
      );

      expect(remaining.remainingCalories, -100);
      expect(remaining.isOverCalorieGoal, isTrue);
    });

    test('exactly at goal is not over', () {
      const currentTotals = DailyTotals(
        calories: 1800,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      );

      final remaining = computeRemainingAfterAdding(
        currentTotals: currentTotals,
        goals: goals,
        addedCalories: 200,
        addedProteinG: 0,
        addedCarbsG: 0,
        addedFatG: 0,
      );

      expect(remaining.remainingCalories, 0);
      expect(remaining.isOverCalorieGoal, isFalse);
    });
  });
}
