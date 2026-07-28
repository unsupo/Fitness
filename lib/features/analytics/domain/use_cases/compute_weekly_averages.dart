import '../entities/weight_entry.dart';

/// Buckets [history] into 7-day windows starting from the earliest entry
/// (the "starting point" of the tracked journey) and averages `weightKg`
/// within each populated bucket. Weeks with no readings are simply absent
/// — never zero-filled — since there's nothing real to plot there. Used to
/// show one smoothed point per week on the weight-goal projection graph,
/// distinct from the raw per-entry history chart shown elsewhere.
List<({DateTime weekStart, double avgWeightKg})> computeWeeklyAverages(
  List<WeightEntry> history,
) {
  if (history.isEmpty) return [];

  final sorted = [...history]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  final origin = sorted.first.loggedAt;

  final buckets = <int, List<double>>{};
  for (final entry in sorted) {
    final weekIndex = entry.loggedAt.difference(origin).inDays ~/ 7;
    buckets.putIfAbsent(weekIndex, () => []).add(entry.weightKg);
  }

  final weekIndices = buckets.keys.toList()..sort();
  return [
    for (final index in weekIndices)
      (
        weekStart: origin.add(Duration(days: 7 * index)),
        avgWeightKg:
            buckets[index]!.reduce((a, b) => a + b) / buckets[index]!.length,
      ),
  ];
}
