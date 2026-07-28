import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:arndt_fitness/features/recipes/domain/use_cases/compute_recipe_totals.dart';
import 'package:flutter_test/flutter_test.dart';

Recipe _recipe({required double servings}) {
  return Recipe(
    id: 1,
    name: 'Chicken Rice Bowl',
    servings: servings,
    ingredients: const [
      RecipeIngredient(
        foodId: 1,
        foodName: 'Chicken Breast',
        quantity: 2,
        calories: 330,
        proteinG: 62,
        carbsG: 0,
        fatG: 7.2,
      ),
      RecipeIngredient(
        foodId: 2,
        foodName: 'White Rice',
        quantity: 1.5,
        calories: 195,
        proteinG: 4.5,
        carbsG: 42,
        fatG: 0.6,
      ),
      RecipeIngredient(
        foodId: 3,
        foodName: 'Olive Oil',
        quantity: 1,
        calories: 120,
        proteinG: 0,
        carbsG: 0,
        fatG: 14,
      ),
    ],
  );
}

void main() {
  group('recipeTotals', () {
    test('sums calories/protein/carbs/fat across ingredients', () {
      final totals = recipeTotals(_recipe(servings: 4));

      expect(totals.calories, 645);
      expect(totals.proteinG, 66.5);
      expect(totals.carbsG, 42);
      expect(totals.fatG, 21.8);
    });

    test('empty ingredient list produces all-zero totals', () {
      final recipe = Recipe(
        id: 2,
        name: 'Empty',
        servings: 1,
        ingredients: const [],
      );

      final totals = recipeTotals(recipe);

      expect(totals.calories, 0);
      expect(totals.proteinG, 0);
      expect(totals.carbsG, 0);
      expect(totals.fatG, 0);
    });
  });

  group('recipePerServing', () {
    test('divides totals by servings', () {
      final perServing = recipePerServing(_recipe(servings: 4));

      expect(perServing.calories, 645 / 4);
      expect(perServing.proteinG, 66.5 / 4);
      expect(perServing.carbsG, 42 / 4);
      expect(perServing.fatG, 21.8 / 4);
    });

    test('servings == 0 is treated as 1 to avoid division by zero', () {
      final perServing = recipePerServing(_recipe(servings: 0));

      expect(perServing.calories, 645);
      expect(perServing.proteinG, 66.5);
      expect(perServing.carbsG, 42);
      expect(perServing.fatG, 21.8);
    });
  });
}
