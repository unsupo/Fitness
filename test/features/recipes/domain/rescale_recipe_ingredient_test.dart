import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:arndt_fitness/features/recipes/domain/use_cases/rescale_recipe_ingredient.dart';

void main() {
  test('rescales calories/macros proportionally when quantity changes', () {
    const ingredient = RecipeIngredient(
      foodId: 1,
      foodName: 'Chicken Breast',
      quantity: LoggedQuantity(amount: 1.0, unit: 'serving'),
      calories: 165,
      proteinG: 31,
      carbsG: 0,
      fatG: 3.6,
    );

    final rescaled = rescaleRecipeIngredient(
      ingredient,
      newQuantity: const LoggedQuantity(amount: 2.0, unit: 'serving'),
    );

    expect(rescaled.quantity.amount, 2.0);
    expect(rescaled.calories, 330);
    expect(rescaled.proteinG, 62);
    expect(rescaled.carbsG, 0);
    expect(rescaled.fatG, 7.2);
    // Everything else stays the same.
    expect(rescaled.foodId, 1);
    expect(rescaled.foodName, 'Chicken Breast');
  });

  test('scales correctly when switching units via servingSize', () {
    const ingredient = RecipeIngredient(
      foodId: 2,
      foodName: 'Greek Yogurt',
      quantity: LoggedQuantity(amount: 1.0, unit: 'serving'),
      calories: 100,
      proteinG: 10,
      carbsG: 5,
      fatG: 2,
      servingSize: 100,
      servingUnit: 'g',
    );

    // 50g is half a serving.
    final rescaled = rescaleRecipeIngredient(
      ingredient,
      newQuantity: const LoggedQuantity(amount: 50, unit: 'g'),
    );

    expect(rescaled.calories, 50);
    expect(rescaled.proteinG, 5);
  });

  test('throws for a zero or negative new quantity', () {
    const ingredient = RecipeIngredient(
      foodId: 3,
      foodName: 'X',
      quantity: LoggedQuantity(amount: 1.0, unit: 'serving'),
      calories: 100,
      proteinG: 1,
      carbsG: 1,
      fatG: 1,
    );

    expect(
      () => rescaleRecipeIngredient(
        ingredient,
        newQuantity: const LoggedQuantity(amount: 0.0, unit: 'serving'),
      ),
      throwsArgumentError,
    );
    expect(
      () => rescaleRecipeIngredient(
        ingredient,
        newQuantity: const LoggedQuantity(amount: -1.0, unit: 'serving'),
      ),
      throwsArgumentError,
    );
  });
}
