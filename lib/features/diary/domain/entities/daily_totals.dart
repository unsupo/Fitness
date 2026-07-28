/// Summed nutrition totals for a set of `DiaryEntry`s (typically one day).
class DailyTotals {
  const DailyTotals({
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  static const zero = DailyTotals(
    calories: 0,
    proteinG: 0,
    carbsG: 0,
    fatG: 0,
  );

  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
}
