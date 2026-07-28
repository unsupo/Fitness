import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_totals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/remaining_after_adding.dart';

/// How much of today's goal remains after also counting an item not yet
/// logged (`addedCalories`/etc), given the day's current totals.
RemainingAfterAdding computeRemainingAfterAdding({
  required DailyTotals currentTotals,
  required DailyGoals goals,
  required double addedCalories,
  required double addedProteinG,
  required double addedCarbsG,
  required double addedFatG,
}) {
  return RemainingAfterAdding(
    remainingCalories: goals.calorieGoal - currentTotals.calories - addedCalories,
    remainingProteinG:
        goals.proteinGoalG - currentTotals.proteinG - addedProteinG,
    remainingCarbsG: goals.carbsGoalG - currentTotals.carbsG - addedCarbsG,
    remainingFatG: goals.fatGoalG - currentTotals.fatG - addedFatG,
  );
}
