import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/domain/use_cases/compute_weekly_averages.dart';

WeightEntry _entry(int id, DateTime loggedAt, double weightKg) => WeightEntry(
  id: id,
  loggedAt: loggedAt,
  weightKg: weightKg,
  goalType: 'lose',
);

void main() {
  group('computeWeeklyAverages', () {
    test('averages multiple readings within the same week into one point', () {
      final history = [
        _entry(1, DateTime(2026, 7, 12), 112.0),
        _entry(2, DateTime(2026, 7, 13), 113.0),
        _entry(3, DateTime(2026, 7, 14), 114.0),
      ];

      final weeks = computeWeeklyAverages(history);

      expect(weeks.length, 1);
      expect(weeks.single.weekStart, DateTime(2026, 7, 12));
      expect(weeks.single.avgWeightKg, closeTo(113.0, 0.001));
    });

    test('splits readings more than 7 days apart into separate weeks', () {
      final history = [
        _entry(1, DateTime(2026, 7, 1), 100.0),
        _entry(2, DateTime(2026, 7, 2), 102.0),
        _entry(3, DateTime(2026, 7, 9), 98.0), // exactly one week later
        _entry(4, DateTime(2026, 7, 20), 95.0), // a later, separate week
      ];

      final weeks = computeWeeklyAverages(history);

      expect(weeks.length, 3);
      expect(weeks[0].weekStart, DateTime(2026, 7, 1));
      expect(weeks[0].avgWeightKg, closeTo(101.0, 0.001));
      expect(weeks[1].weekStart, DateTime(2026, 7, 8));
      expect(weeks[1].avgWeightKg, closeTo(98.0, 0.001));
      expect(weeks[2].weekStart, DateTime(2026, 7, 15));
      expect(weeks[2].avgWeightKg, closeTo(95.0, 0.001));
    });

    test('a single entry produces a single point', () {
      final weeks = computeWeeklyAverages([_entry(1, DateTime(2026, 7, 1), 100.0)]);

      expect(weeks.length, 1);
      expect(weeks.single.avgWeightKg, 100.0);
    });

    test('empty history produces no points', () {
      expect(computeWeeklyAverages(const []), isEmpty);
    });

    test('does not require the input to already be sorted', () {
      final history = [
        _entry(1, DateTime(2026, 7, 14), 114.0),
        _entry(2, DateTime(2026, 7, 12), 112.0),
      ];

      final weeks = computeWeeklyAverages(history);

      expect(weeks.length, 1);
      expect(weeks.single.weekStart, DateTime(2026, 7, 12));
    });
  });
}
