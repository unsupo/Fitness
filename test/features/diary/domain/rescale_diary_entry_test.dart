import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/rescale_diary_entry.dart';

void main() {
  test('rescales calories/macros proportionally when quantity changes', () {
    final entry = DiaryEntry(
      id: 1,
      loggedAt: DateTime(2026, 7, 21, 8, 0),
      mealType: MealType.breakfast,
      foodName: 'BBQ Pringles',
      quantity: const LoggedQuantity(amount: 0.5, unit: 'serving'),
      calories: 75,
      proteinG: 0.5,
      carbsG: 7.5,
      fatG: 4.5,
      foodId: 3,
    );

    final rescaled = rescaleDiaryEntry(entry, newQuantity: const LoggedQuantity(amount: 1.0, unit: 'serving'));

    expect(rescaled.quantity.amount, 1.0);
    expect(rescaled.quantity.unit, 'serving');
    expect(rescaled.calories, 150);
    expect(rescaled.proteinG, 1.0);
    expect(rescaled.carbsG, 15.0);
    expect(rescaled.fatG, 9.0);
    // Everything else stays the same.
    expect(rescaled.id, 1);
    expect(rescaled.foodName, 'BBQ Pringles');
    expect(rescaled.mealType, MealType.breakfast);
    expect(rescaled.foodId, 3);
  });

  test('works for recipe-based entries the same way (ratio, no food lookup)', () {
    final entry = DiaryEntry(
      id: 2,
      loggedAt: DateTime(2026, 7, 21, 18, 51),
      mealType: MealType.snack,
      foodName: 'Protein Snack Plate',
      quantity: const LoggedQuantity(amount: 1.0, unit: 'serving'),
      calories: 310,
      proteinG: 31,
      carbsG: 15,
      fatG: 9,
    );

    final rescaled = rescaleDiaryEntry(entry, newQuantity: const LoggedQuantity(amount: 2.0, unit: 'serving'));

    expect(rescaled.calories, 620);
    expect(rescaled.proteinG, 62);
  });

  test('throws for a zero or negative new quantity', () {
    final entry = DiaryEntry(
      id: 3,
      loggedAt: DateTime(2026, 7, 21),
      mealType: MealType.snack,
      foodName: 'X',
      quantity: const LoggedQuantity(amount: 1.0, unit: 'serving'),
      calories: 100,
      proteinG: 1,
      carbsG: 1,
      fatG: 1,
    );

    expect(() => rescaleDiaryEntry(entry, newQuantity: const LoggedQuantity(amount: 0.0, unit: 'serving')), throwsArgumentError);
    expect(() => rescaleDiaryEntry(entry, newQuantity: const LoggedQuantity(amount: -1.0, unit: 'serving')), throwsArgumentError);
  });
}
