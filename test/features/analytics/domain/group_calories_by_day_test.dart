import 'package:arndt_fitness/features/analytics/domain/use_cases/group_calories_by_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('groupCaloriesByDay', () {
    test(
      'buckets entries into 7 days, sums same-day totals, excludes '
      'out-of-range entries, and zero-fills empty days',
      () {
        final weekStart = DateTime(2026, 7, 20); // Monday

        final rawEntries = <({DateTime loggedAt, double calories})>[
          // Day 0 (Mon Jul 20): two entries, should sum to 700.
          (loggedAt: DateTime(2026, 7, 20, 8), calories: 300),
          (loggedAt: DateTime(2026, 7, 20, 19), calories: 400),
          // Day 2 (Wed Jul 22): one entry.
          (loggedAt: DateTime(2026, 7, 22, 12), calories: 550),
          // Day 6 (Sun Jul 26): one entry, last day of the week window.
          (loggedAt: DateTime(2026, 7, 26, 9), calories: 200),
          // Out of range: the following Monday, must be excluded.
          (loggedAt: DateTime(2026, 7, 27, 8), calories: 999),
          // Out of range: the day before weekStart, must be excluded.
          (loggedAt: DateTime(2026, 7, 19, 23), calories: 111),
        ];

        final result = groupCaloriesByDay(rawEntries, weekStart);

        expect(result, hasLength(7));

        // Date order, one entry per day of the week starting at weekStart.
        for (var i = 0; i < 7; i++) {
          expect(result[i].date, DateTime(2026, 7, 20 + i));
        }

        expect(result[0].totalCalories, 700);
        expect(result[1].totalCalories, 0); // Tue: no entries.
        expect(result[2].totalCalories, 550);
        expect(result[3].totalCalories, 0);
        expect(result[4].totalCalories, 0);
        expect(result[5].totalCalories, 0);
        expect(result[6].totalCalories, 200);
      },
    );
  });
}
