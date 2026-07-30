/// Calculates the daily calorie goal required to achieve a specific weekly weight change rate.
///
/// [weeklyRateKg] is the target weekly weight change in kilograms. 
/// Negative values indicate weight loss, positive values indicate weight gain.
double calorieGoalForWeeklyRate({
  required double tdee,
  required double weeklyRateKg,
}) {
  return tdee + (weeklyRateKg * 7700 / 7);
}

/// Calculates the expected weekly weight change rate for a given daily calorie goal.
/// 
/// Returns the rate in kilograms. Negative values indicate weight loss, 
/// positive values indicate weight gain.
double weeklyRateForCalorieGoal({
  required double tdee,
  required double calorieGoal,
}) {
  return (calorieGoal - tdee) * 7 / 7700;
}
