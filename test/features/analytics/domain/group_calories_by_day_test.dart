import 'package:arndt_fitness/features/analytics/domain/use_cases/group_calories_by_day.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('groupCaloriesByDay', () {
    test(
      'buckets entries into 7 days, sums same-day totals, excludes '
      'out-of-range entries, and zero-fills empty days',
      () {
        final weekStart = DateTime(2026, 7, 20); // Monday

        final rawEntries = <({DateTime loggedAt, double calories, double proteinG, double carbsG, double fatG})>[
          // Day 0 (Mon Jul 20): two entries, should sum to 700.
          (loggedAt: DateTime(2026, 7, 20, 8), calories: 300, proteinG: 20, carbsG: 30, fatG: 10),
          (loggedAt: DateTime(2026, 7, 20, 19), calories: 400, proteinG: 30, carbsG: 40, fatG: 10),
          // Day 2 (Wed Jul 22): one entry.
          (loggedAt: DateTime(2026, 7, 22, 12), calories: 550, proteinG: 40, carbsG: 50, fatG: 15),
          // Day 6 (Sun Jul 26): one entry, last day of the week window.
          (loggedAt: DateTime(2026, 7, 26, 9), calories: 200, proteinG: 15, carbsG: 20, fatG: 5),
          // Out of range: the following Monday, must be excluded.
          (loggedAt: DateTime(2026, 7, 27, 8), calories: 999, proteinG: 10, carbsG: 20, fatG: 30),
          // Out of range: the day before weekStart, must be excluded.
          (loggedAt: DateTime(2026, 7, 19, 23), calories: 111, proteinG: 5, carbsG: 10, fatG: 5),
        ];

        final result = groupCaloriesByDay(rawEntries, weekStart);

        expect(result, hasLength(7));

        // Date order, one entry per day of the week starting at weekStart.
        for (var i = 0; i < 7; i++) {
          expect(result[i].date, DateTime(2026, 7, 20 + i));
        }

        expect(result[0].totalCalories, 700);
        expect(result[0].proteinG, 50);
        expect(result[0].carbsG, 70);
        expect(result[0].fatG, 20);

        expect(result[1].totalCalories, 0); // Tue: no entries.
        expect(result[2].totalCalories, 550);
        expect(result[2].proteinG, 40);
        expect(result[2].carbsG, 50);
        expect(result[2].fatG, 15);

        expect(result[6].totalCalories, 200);
        expect(result[6].proteinG, 15);
      },
    );
  });
}
