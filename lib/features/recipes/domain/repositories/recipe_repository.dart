import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';

/// Abstract seam between the recipes presentation layer and whatever backend
/// stores recipes/ingredients. `SupabaseRecipeRepository` is the concrete
/// adapter used by default; tests use a `FakeRecipeRepository`.
abstract class RecipeRepository {
  Future<List<Recipe>> getRecipes();

  /// For the ingredient picker; empty query = list all (there are only ~7
  /// foods right now).
  Future<List<FoodItem>> searchFoods(String query);

  Future<void> createRecipe({
    required String name,
    required double servings,
    required List<({int foodId, double quantity})> ingredients,
  });

  /// Replaces the recipe's name/servings and its full ingredient list.
  Future<void> updateRecipe({
    required int recipeId,
    required String name,
    required double servings,
    required List<({int foodId, double quantity})> ingredients,
  });

  /// Deletes the recipe and its ingredients. Diary entries already logged
  /// from it keep their frozen calories/macros but lose the recipe-name link
  /// (the `food_log.recipe_id` FK is `ON DELETE SET NULL`).
  Future<void> deleteRecipe(int recipeId);

  Future<void> logRecipeToDiary(int recipeId, MealType mealType);
}
