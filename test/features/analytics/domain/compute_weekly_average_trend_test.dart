import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/domain/use_cases/compute_weekly_average_trend.dart';

WeightEntry _entry(int id, DateTime loggedAt, double weightKg) => WeightEntry(
  id: id,
  loggedAt: loggedAt,
  weightKg: weightKg,
  goalType: 'lose',
);

void main() {
  group('computeWeeklyAverageTrend', () {
    test('returns an empty list for empty history', () {
      expect(computeWeeklyAverageTrend(const []), isEmpty);
    });

    test(
      'averages both the weight and the index position within each 7-day '
      'bucket, so the trend line lands on the same index-based x-axis as '
      'the raw per-entry chart',
      () {
        final history = [
          // Week 0: indices 0, 1, 2 — average index 1, average weight 90.
          _entry(1, DateTime(2026, 7, 1), 91),
          _entry(2, DateTime(2026, 7, 2), 90),
          _entry(3, DateTime(2026, 7, 3), 89),
          // Week 1 (7+ days after origin): indices 3, 4 — average index
          // 3.5, average weight 87.5.
          _entry(4, DateTime(2026, 7, 8), 88),
          _entry(5, DateTime(2026, 7, 9), 87),
        ];

        final trend = computeWeeklyAverageTrend(history);

        expect(trend.length, 2);
        expect(trend[0].x, closeTo(1.0, 0.001));
        expect(trend[0].avgWeightKg, closeTo(90, 0.001));
        expect(trend[1].x, closeTo(3.5, 0.001));
        expect(trend[1].avgWeightKg, closeTo(87.5, 0.001));
      },
    );

    test('a single entry produces one point at its own index', () {
      final trend = computeWeeklyAverageTrend([
        _entry(1, DateTime(2026, 7, 1), 90),
      ]);

      expect(trend.single.x, 0);
      expect(trend.single.avgWeightKg, 90);
    });
  });
}
