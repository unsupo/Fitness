import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/format_quantity.dart';

void main() {
  DiaryEntry entry({
    required double quantity,
    double? servingSize,
    String? servingUnit,
  }) => DiaryEntry(
    id: 1,
    loggedAt: DateTime(2026, 7, 21),
    mealType: MealType.snack,
    foodName: 'BBQ Pringles',
    quantity: quantity,
    calories: 150,
    proteinG: 1,
    carbsG: 15,
    fatG: 9,
    servingSize: servingSize,
    servingUnit: servingUnit,
  );

  test('shows real units when servingSize/servingUnit are known: 1 serving of 14 crisps -> "14 crisps"', () {
    expect(
      formatQuantity(entry(quantity: 1, servingSize: 14, servingUnit: 'crisps')),
      '14 crisps',
    );
  });

  test('scales serving size by quantity: half a serving of 14 crisps -> "7 crisps"', () {
    expect(
      formatQuantity(entry(quantity: 0.5, servingSize: 14, servingUnit: 'crisps')),
      '7 crisps',
    );
  });

  test('rounds a messy result to one decimal place', () {
    expect(
      formatQuantity(
        entry(quantity: 1.8045112781954886, servingSize: 100, servingUnit: 'g'),
      ),
      '180.5 g',
    );
  });

  test('falls back to "Nx" when serving size/unit are unknown (e.g. recipe-based entries)', () {
    expect(formatQuantity(entry(quantity: 1)), '1x');
    expect(formatQuantity(entry(quantity: 1.8045112781954886)), '1.8x');
  });
}
