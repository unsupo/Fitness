import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/compute_daily_totals.dart';
import 'package:flutter_test/flutter_test.dart';

DiaryEntry _entry({
  required int id,
  required MealType mealType,
  required double calories,
  required double proteinG,
  required double carbsG,
  required double fatG,
}) {
  return DiaryEntry(
    id: id,
    loggedAt: DateTime(2026, 7, 21, 8, 0),
    mealType: mealType,
    foodName: 'Food $id',
    quantity: 1,
    calories: calories,
    proteinG: proteinG,
    carbsG: carbsG,
    fatG: fatG,
  );
}

void main() {
  group('computeDailyTotals', () {
    test('sums calories/protein/carbs/fat across entries', () {
      final entries = [
        _entry(
          id: 1,
          mealType: MealType.breakfast,
          calories: 300,
          proteinG: 20,
          carbsG: 30,
          fatG: 10,
        ),
        _entry(
          id: 2,
          mealType: MealType.lunch,
          calories: 450,
          proteinG: 35,
          carbsG: 40,
          fatG: 15,
        ),
        _entry(
          id: 3,
          mealType: MealType.snack,
          calories: 150,
          proteinG: 5,
          carbsG: 20,
          fatG: 5,
        ),
      ];

      final totals = computeDailyTotals(entries);

      expect(totals.calories, 900);
      expect(totals.proteinG, 60);
      expect(totals.carbsG, 90);
      expect(totals.fatG, 30);
    });

    test('empty list produces all-zero totals', () {
      final totals = computeDailyTotals(const []);

      expect(totals.calories, 0);
      expect(totals.proteinG, 0);
      expect(totals.carbsG, 0);
      expect(totals.fatG, 0);
    });
  });
}
