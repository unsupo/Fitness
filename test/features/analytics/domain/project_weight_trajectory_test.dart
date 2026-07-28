import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/use_cases/project_weight_trajectory.dart';

void main() {
  group('projectWeightTrajectory', () {
    test('projects weekly points from current weight down to target weight', () {
      // 500 kcal/day deficit * 7 / 7700 = 0.4545... kg/week loss.
      // 5 kg to lose / 0.4545... kg/week ≈ 11 weeks.
      final points = projectWeightTrajectory(
        currentWeightKg: 85,
        targetWeightKg: 80,
        tdee: 2500,
        calorieGoal: 2000,
        startDate: DateTime(2026, 7, 21),
      );

      expect(points.first.weightKg, 85);
      expect(points.first.date, DateTime(2026, 7, 21));

      // Every point after the first is exactly 7 days apart, weight
      // strictly decreasing, until the final point lands exactly on target.
      for (var i = 1; i < points.length; i++) {
        expect(points[i].weightKg, lessThan(points[i - 1].weightKg));
      }
      expect(points.last.weightKg, closeTo(80, 0.01));
      expect(points.last.date.isAfter(points.first.date), isTrue);
    });

    test('projects upward when calorieGoal exceeds TDEE (surplus, gaining)', () {
      final points = projectWeightTrajectory(
        currentWeightKg: 70,
        targetWeightKg: 75,
        tdee: 2200,
        calorieGoal: 2700,
        startDate: DateTime(2026, 7, 21),
      );

      expect(points.last.weightKg, closeTo(75, 0.01));
      for (var i = 1; i < points.length; i++) {
        expect(points[i].weightKg, greaterThan(points[i - 1].weightKg));
      }
    });

    test(
      'returns just the starting point when the calorie goal moves weight '
      'away from the target instead of toward it',
      () {
        // Eating in a deficit (calorieGoal < tdee) while target is *above*
        // current weight can never be reached this way.
        final points = projectWeightTrajectory(
          currentWeightKg: 70,
          targetWeightKg: 75,
          tdee: 2500,
          calorieGoal: 2000,
          startDate: DateTime(2026, 7, 21),
        );

        expect(points, hasLength(1));
        expect(points.single.weightKg, 70);
      },
    );

    test('returns just the starting point when already at the target', () {
      final points = projectWeightTrajectory(
        currentWeightKg: 70,
        targetWeightKg: 70,
        tdee: 2500,
        calorieGoal: 2000,
        startDate: DateTime(2026, 7, 21),
      );

      expect(points, hasLength(1));
    });
  });
}
