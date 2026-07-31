import 'package:arndt_fitness/features/workouts/domain/use_cases/calculate_one_rep_max.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('calculateOneRepMax', () {
    test('returns 0.0 for 0 reps', () {
      expect(calculateOneRepMax(weight: 100, reps: 0), equals(0.0));
    });

    test('returns weight verbatim for 1 rep', () {
      expect(calculateOneRepMax(weight: 100, reps: 1), equals(100.0));
    });

    test('calculates correct 1RM using Epley formula for multiple reps', () {
      // 100 * (1 + 10 / 30) = 100 * 1.3333 = 133.333...
      expect(calculateOneRepMax(weight: 100, reps: 10), closeTo(133.33, 0.01));
    });
  });
}
