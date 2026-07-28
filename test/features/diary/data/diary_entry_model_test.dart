import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/data/models/diary_entry_model.dart';

void main() {
  test('fromJson captures food_id for navigating to food detail', () {
    final json = {
      'id': 42,
      'logged_at': '2026-07-21T18:35:54.583702+00:00',
      'meal_type': 'lunch',
      'food_id': 7,
      'quantity': '0.5',
      'calories': '75',
      'protein_g': '0.5',
      'carbs_g': '7.5',
      'fat_g': '4.5',
      'foods': {
        'name': 'BBQ Pringles',
        'serving_size': '14',
        'serving_unit': 'crisps',
        'image_url': 'https://images.example.com/pringles.jpg',
      },
    };

    final entry = DiaryEntryModel.fromJson(json).toEntity();

    expect(entry.foodId, 7);
    expect(entry.foodName, 'BBQ Pringles');
    expect(entry.quantity, 0.5);
    expect(entry.mealType, MealType.lunch);
    expect(entry.servingSize, 14);
    expect(entry.servingUnit, 'crisps');
    expect(entry.imageUrl, 'https://images.example.com/pringles.jpg');
    // logged_at arrives as a UTC instant ("+00:00"); it must be converted to
    // the device's local time here, once, so every downstream display and
    // day-grouping is correct without repeating the conversion everywhere.
    expect(entry.loggedAt.isUtc, isFalse);
  });

  test('fromJson uses the joined recipe name for a recipe-based entry', () {
    final json = {
      'id': 43,
      'logged_at': '2026-07-21T18:35:54.583702+00:00',
      'meal_type': 'dinner',
      'food_id': null,
      'recipe_id': 1,
      'quantity': '1',
      'calories': '400',
      'protein_g': '20',
      'carbs_g': '30',
      'fat_g': '10',
      'foods': null,
      'recipes': {'name': 'Protein Snack Plate'},
    };

    final entry = DiaryEntryModel.fromJson(json).toEntity();

    expect(entry.foodId, isNull);
    expect(entry.foodName, 'Protein Snack Plate');
    expect(entry.imageUrl, isNull);
  });

  test('fromJson falls back to "Unknown food" when neither joins have a name', () {
    final json = {
      'id': 44,
      'logged_at': '2026-07-21T18:35:54.583702+00:00',
      'meal_type': 'dinner',
      'food_id': null,
      'recipe_id': null,
      'quantity': '1',
      'calories': '400',
      'protein_g': '20',
      'carbs_g': '30',
      'fat_g': '10',
      'foods': null,
      'recipes': null,
    };

    final entry = DiaryEntryModel.fromJson(json).toEntity();

    expect(entry.foodId, isNull);
    expect(entry.foodName, 'Unknown food');
  });
}
