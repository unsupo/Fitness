/// A single day's total logged calories, used to render one bar in the
/// weekly calories chart.
class DailyCalories {
  const DailyCalories({required this.date, required this.totalCalories});

  /// The calendar day this total belongs to, truncated to midnight (no
  /// time-of-day component).
  final DateTime date;

  final double totalCalories;
}
