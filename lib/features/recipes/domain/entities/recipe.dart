import 'package:arndt_fitness/features/recipes/domain/entities/recipe_ingredient.dart';

/// A saved recipe — a named collection of [RecipeIngredient]s that yields
/// [servings] servings. Total/per-serving macros are derived, not stored;
/// see `compute_recipe_totals.dart`.
class Recipe {
  const Recipe({
    required this.id,
    required this.name,
    required this.servings,
    required this.ingredients,
  });

  final int id;
  final String name;
  final double servings;
  final List<RecipeIngredient> ingredients;
}
