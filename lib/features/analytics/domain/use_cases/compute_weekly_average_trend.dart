import '../entities/weight_entry.dart';

/// Buckets [history] into the same 7-day windows as `computeWeeklyAverages`,
/// but returns each bucket's average *index position* alongside its average
/// weight — not just a calendar date — so the resulting trend line can be
/// plotted on the weight-history chart's index-based x-axis (one point per
/// raw entry), overlaid on top of the noisy day-to-day readings.
///
/// Assumes [history] is already sorted oldest-first, matching how the chart
/// itself plots entry `i` at x = `i`.
List<({double x, double avgWeightKg})> computeWeeklyAverageTrend(
  List<WeightEntry> history,
) {
  if (history.isEmpty) return [];

  final origin = history.first.loggedAt;
  final buckets = <int, List<int>>{};
  for (var i = 0; i < history.length; i++) {
    final weekIndex = history[i].loggedAt.difference(origin).inDays ~/ 7;
    buckets.putIfAbsent(weekIndex, () => []).add(i);
  }

  final weekIndices = buckets.keys.toList()..sort();
  return [
    for (final weekIndex in weekIndices)
      (
        x: buckets[weekIndex]!.reduce((a, b) => a + b) /
            buckets[weekIndex]!.length,
        avgWeightKg:
            buckets[weekIndex]!
                .map((i) => history[i].weightKg)
                .reduce((a, b) => a + b) /
            buckets[weekIndex]!.length,
      ),
  ];
}
