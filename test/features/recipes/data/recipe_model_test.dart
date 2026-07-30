import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/recipes/data/models/recipe_model.dart';

void main() {
  test(
    'fromJson uses each ingredient\'s persisted quantity_unit to '
    'disambiguate "serving" from the food\'s native unit',
    () {
      final json = {
        'id': 1,
        'name': 'Chicken Rice Bowl',
        'servings': '2',
        'recipe_ingredients': [
          {
            'quantity': '2',
            'quantity_unit': 'serving',
            'foods': {
              'id': 7,
              'name': 'BBQ Pringles',
              'calories': '75',
              'protein_g': '0.5',
              'carbs_g': '7.5',
              'fat_g': '4.5',
              'serving_size': '14',
              'serving_unit': 'crisps',
            },
          },
        ],
      };

      final recipe = RecipeModel.fromJson(json).toEntity();

      expect(recipe.ingredients.single.quantity.amount, 2.0);
      expect(recipe.ingredients.single.quantity.unit, 'serving');
    },
  );

  test(
    'fromJson falls back to reconstructing the unit from serving size '
    'when quantity_unit is null (legacy rows logged before it existed)',
    () {
      final json = {
        'id': 2,
        'name': 'Chicken Rice Bowl',
        'servings': '2',
        'recipe_ingredients': [
          {
            'quantity': '2',
            'quantity_unit': null,
            'foods': {
              'id': 7,
              'name': 'BBQ Pringles',
              'calories': '75',
              'protein_g': '0.5',
              'carbs_g': '7.5',
              'fat_g': '4.5',
              'serving_size': '14',
              'serving_unit': 'crisps',
            },
          },
        ],
      };

      final recipe = RecipeModel.fromJson(json).toEntity();

      expect(recipe.ingredients.single.quantity.amount, 28.0);
      expect(recipe.ingredients.single.quantity.unit, 'crisps');
    },
  );
}
