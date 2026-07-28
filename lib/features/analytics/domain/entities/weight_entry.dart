/// A single weigh-in row from `weight_log`.
class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.loggedAt,
    required this.weightKg,
    required this.goalType,
  });

  final int id;
  final DateTime loggedAt;
  final double weightKg;

  /// One of `'maintain' | 'lose' | 'gain'`.
  final String goalType;
}
