import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';

/// Sums calories/protein/carbs/fat across a recipe's ingredients. An empty
/// ingredient list produces all-zero totals.
({double calories, double proteinG, double carbsG, double fatG}) recipeTotals(
  Recipe recipe,
) {
  var calories = 0.0;
  var proteinG = 0.0;
  var carbsG = 0.0;
  var fatG = 0.0;

  for (final ingredient in recipe.ingredients) {
    calories += ingredient.calories;
    proteinG += ingredient.proteinG;
    carbsG += ingredient.carbsG;
    fatG += ingredient.fatG;
  }

  return (calories: calories, proteinG: proteinG, carbsG: carbsG, fatG: fatG);
}

/// Divides [recipeTotals] by `recipe.servings`. Guards against division by
/// zero by treating `servings == 0` as 1.
({double calories, double proteinG, double carbsG, double fatG})
recipePerServing(Recipe recipe) {
  final totals = recipeTotals(recipe);
  final servings = recipe.servings == 0 ? 1 : recipe.servings;

  return (
    calories: totals.calories / servings,
    proteinG: totals.proteinG / servings,
    carbsG: totals.carbsG / servings,
    fatG: totals.fatG / servings,
  );
}
