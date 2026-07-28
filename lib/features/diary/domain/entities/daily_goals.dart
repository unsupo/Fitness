/// Single-row daily nutrition targets — mirrors the `daily_goals` table.
class DailyGoals {
  const DailyGoals({
    required this.calorieGoal,
    required this.proteinGoalG,
    required this.carbsGoalG,
    required this.fatGoalG,
  });

  final double calorieGoal;
  final double proteinGoalG;
  final double carbsGoalG;
  final double fatGoalG;
}
