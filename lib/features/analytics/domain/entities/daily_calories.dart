/// A single day's total logged calories and macros, used to render a stacked bar
/// in the weekly calories chart.
class DailyCalories {
  const DailyCalories({
    required this.date,
    required this.totalCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  /// The calendar day this total belongs to, truncated to midnight.
  final DateTime date;

  final double totalCalories;
  final double proteinG;
  final double carbsG;
  final double fatG;
}
