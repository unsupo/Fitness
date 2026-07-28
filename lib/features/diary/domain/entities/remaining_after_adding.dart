/// How much of each daily goal would be left after logging an additional
/// food, given today's current totals and goals. Values can go negative;
/// callers decide how to present "over budget" — this is pure arithmetic.
class RemainingAfterAdding {
  const RemainingAfterAdding({
    required this.remainingCalories,
    required this.remainingProteinG,
    required this.remainingCarbsG,
    required this.remainingFatG,
  });

  final double remainingCalories;
  final double remainingProteinG;
  final double remainingCarbsG;
  final double remainingFatG;

  bool get isOverCalorieGoal => remainingCalories < 0;
}
