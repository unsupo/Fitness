/// kcal per kg of body fat — the standard energy-balance approximation used
/// to convert a daily calorie deficit/surplus into an expected rate of
/// weight change. This is a directional estimate, not a guarantee.
const _kcalPerKg = 7700;

/// Weeks capped to avoid an absurdly long/huge projection when the weekly
/// rate is tiny relative to the distance to target (2 years).
const _maxWeeks = 104;

/// Projects weekly `(date, weightKg)` points from [currentWeightKg] toward
/// [targetWeightKg], assuming [calorieGoal] is eaten every day against an
/// estimated [tdee] (see `estimateTdee`). Always includes [startDate] at
/// [currentWeightKg] as the first point.
///
/// If eating at [calorieGoal] would move weight *away* from
/// [targetWeightKg] (or already at the target), returns just that single
/// starting point — there's nothing to project.
List<({DateTime date, double weightKg})> projectWeightTrajectory({
  required double currentWeightKg,
  required double targetWeightKg,
  required double tdee,
  required double calorieGoal,
  required DateTime startDate,
}) {
  final start = (date: startDate, weightKg: currentWeightKg);

  final totalChangeNeeded = currentWeightKg - targetWeightKg;
  if (totalChangeNeeded == 0) return [start];

  final dailyDeficit = tdee - calorieGoal;
  final weeklyChangeKg = dailyDeficit * 7 / _kcalPerKg;
  if (weeklyChangeKg == 0) return [start];

  final movingTowardTarget =
      (totalChangeNeeded > 0 && weeklyChangeKg > 0) ||
      (totalChangeNeeded < 0 && weeklyChangeKg < 0);
  if (!movingTowardTarget) return [start];

  final weeksNeeded = (totalChangeNeeded / weeklyChangeKg).abs();
  final fullWeeks = weeksNeeded.floor().clamp(0, _maxWeeks);

  final points = [start];
  for (var week = 1; week <= fullWeeks; week++) {
    points.add((
      date: startDate.add(Duration(days: 7 * week)),
      weightKg: currentWeightKg - weeklyChangeKg * week,
    ));
  }

  if (weeksNeeded > fullWeeks && fullWeeks < _maxWeeks) {
    points.add((
      date: startDate.add(Duration(days: (weeksNeeded * 7).round())),
      weightKg: targetWeightKg,
    ));
  }

  return points;
}
