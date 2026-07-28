import '../entities/daily_calories.dart';

/// Buckets raw `food_log`-shaped `(loggedAt, calories)` tuples into exactly 7
/// [DailyCalories], one per day of the week starting at [weekStart]
/// (inclusive). Entries outside the `[weekStart, weekStart + 7 days)` window
/// are excluded. Days with no matching entries get a total of `0`.
List<DailyCalories> groupCaloriesByDay(
  List<({DateTime loggedAt, double calories})> rawEntries,
  DateTime weekStart,
) {
  final start = DateTime(weekStart.year, weekStart.month, weekStart.day);
  final totals = List<double>.filled(7, 0);

  for (final entry in rawEntries) {
    final day = DateTime(
      entry.loggedAt.year,
      entry.loggedAt.month,
      entry.loggedAt.day,
    );
    final offset = day.difference(start).inDays;
    if (offset < 0 || offset > 6) continue;
    totals[offset] += entry.calories;
  }

  return List.generate(
    7,
    (i) => DailyCalories(
      date: start.add(Duration(days: i)),
      totalCalories: totals[i],
    ),
  );
}
