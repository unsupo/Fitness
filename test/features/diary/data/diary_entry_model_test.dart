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
    expect(entry.quantity.amount, 7.0);
    expect(entry.quantity.unit, 'crisps');
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
    expect(entry.recipeId, 1);
    expect(entry.foodName, 'Protein Snack Plate');
    expect(entry.quantity.amount, 1.0);
    expect(entry.quantity.unit, 'serving');
    expect(entry.imageUrl, isNull);
  });

  test(
    'fromJson uses the persisted quantity_unit to disambiguate "serving" '
    'from the food\'s native unit — both are valid choices for this food, '
    'and only quantity_unit records which one was actually picked',
    () {
      // 2 servings of a 14-crisps-per-serving food, logged as *servings*
      // (not "28 crisps"). Without quantity_unit, toEntity() would always
      // prefer reconstructing via servingUnit when one is known, silently
      // relabeling this "2 serving" entry as "28 crisps".
      final json = {
        'id': 45,
        'logged_at': '2026-07-21T18:35:54.583702+00:00',
        'meal_type': 'lunch',
        'food_id': 7,
        'quantity': '2',
        'quantity_unit': 'serving',
        'calories': '150',
        'protein_g': '1',
        'carbs_g': '15',
        'fat_g': '9',
        'foods': {
          'name': 'BBQ Pringles',
          'serving_size': '14',
          'serving_unit': 'crisps',
        },
      };

      final entry = DiaryEntryModel.fromJson(json).toEntity();

      expect(entry.quantity.amount, 2.0);
      expect(entry.quantity.unit, 'serving');
    },
  );

  test(
    'fromJson uses the persisted quantity_unit to reconstruct the '
    "food's native unit correctly (50g of a 100g-serving food)",
    () {
      final json = {
        'id': 47,
        'logged_at': '2026-07-21T18:35:54.583702+00:00',
        'meal_type': 'lunch',
        'food_id': 8,
        'quantity': '0.5',
        'quantity_unit': 'g',
        'calories': '75',
        'protein_g': '0.5',
        'carbs_g': '7.5',
        'fat_g': '4.5',
        'foods': {
          'name': 'Greek Yogurt',
          'serving_size': '100',
          'serving_unit': 'g',
        },
      };

      final entry = DiaryEntryModel.fromJson(json).toEntity();

      expect(entry.quantity.amount, 50.0);
      expect(entry.quantity.unit, 'g');
    },
  );

  test('fromJson falls back to reconstructing the unit from serving size '
      'when quantity_unit is null (legacy rows logged before it existed)', () {
    final json = {
      'id': 46,
      'logged_at': '2026-07-21T18:35:54.583702+00:00',
      'meal_type': 'lunch',
      'food_id': 7,
      'quantity': '0.5',
      'quantity_unit': null,
      'calories': '75',
      'protein_g': '0.5',
      'carbs_g': '7.5',
      'fat_g': '4.5',
      'foods': {
        'name': 'BBQ Pringles',
        'serving_size': '14',
        'serving_unit': 'crisps',
      },
    };

    final entry = DiaryEntryModel.fromJson(json).toEntity();

    expect(entry.quantity.amount, 7.0);
    expect(entry.quantity.unit, 'crisps');
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
    expect(entry.quantity.amount, 1.0);
    expect(entry.quantity.unit, 'serving');
  });
}
