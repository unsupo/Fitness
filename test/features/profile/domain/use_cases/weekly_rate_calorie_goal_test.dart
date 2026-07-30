import 'package:flutter_test/flutter_test.dart';
import 'package:arndt_fitness/features/profile/domain/use_cases/weekly_rate_calorie_goal.dart';

void main() {
  group('weeklyRateForCalorieGoal', () {
    test('calorie deficit gives negative weight rate (loss)', () {
      final rate = weeklyRateForCalorieGoal(tdee: 2500, calorieGoal: 1400);
      expect(rate, closeTo(-1.0, 0.001)); // (1400 - 2500) = -1100. -1100 * 7 / 7700 = -1.0
    });

    test('calorie surplus gives positive weight rate (gain)', () {
      final rate = weeklyRateForCalorieGoal(tdee: 2000, calorieGoal: 2550);
      expect(rate, closeTo(0.5, 0.001)); // (2550 - 2000) = 550. 550 * 7 / 7700 = 0.5
    });

    test('maintenance calories gives zero weight rate', () {
      final rate = weeklyRateForCalorieGoal(tdee: 2000, calorieGoal: 2000);
      expect(rate, equals(0.0));
    });
  });

  group('calorieGoalForWeeklyRate', () {
    test('negative weight rate (loss) gives calorie deficit', () {
      final goal = calorieGoalForWeeklyRate(tdee: 2500, weeklyRateKg: -1.0);
      expect(goal, equals(1400)); // 2500 + (-1.0 * 1100) = 1400
    });

    test('positive weight rate (gain) gives calorie surplus', () {
      final goal = calorieGoalForWeeklyRate(tdee: 2000, weeklyRateKg: 0.5);
      expect(goal, equals(2550)); // 2000 + (0.5 * 1100) = 2550
    });

    test('zero weight rate gives maintenance calories', () {
      final goal = calorieGoalForWeeklyRate(tdee: 2000, weeklyRateKg: 0.0);
      expect(goal, equals(2000));
    });
  });
}
