import '../entities/daily_calories.dart';

/// Buckets raw `food_log`-shaped tuples into exactly 7 [DailyCalories], one per
/// day of the week starting at [weekStart] (inclusive).
List<DailyCalories> groupCaloriesByDay(
  List<({DateTime loggedAt, double calories, double proteinG, double carbsG, double fatG})> rawEntries,
  DateTime weekStart,
) {
  final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final totals = List<double>.filled(7, 0);
  final proteins = List<double>.filled(7, 0);
  final carbs = List<double>.filled(7, 0);
  final fats = List<double>.filled(7, 0);

  for (final entry in rawEntries) {
    final day = DateTime(
      entry.loggedAt.year,
      entry.loggedAt.month,
      entry.loggedAt.day,
    );
    final offset = day.difference(start).inDays;
    if (offset < 0 || offset > 6) continue;
    totals[offset] += entry.calories;
    proteins[offset] += entry.proteinG;
    carbs[offset] += entry.carbsG;
    fats[offset] += entry.fatG;
  }

  return List.generate(
    7,
    (i) => DailyCalories(
      date: start.add(Duration(days: i)),
      totalCalories: totals[i],
      proteinG: proteins[i],
      carbsG: carbs[i],
      fatG: fats[i],
    ),
  );
}
