import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/data/models/food_item_model.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/recipes/data/data_sources/recipes_remote_data_source.dart';
import 'package:arndt_fitness/features/recipes/data/models/recipe_model.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:arndt_fitness/features/recipes/domain/use_cases/compute_recipe_totals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase adapter implementation of [RecipeRepository] — the concrete
/// backend the app defaults to. Delegates to [RecipesRemoteDataSource] and
/// maps raw JSON/models to domain entities.
class SupabaseRecipeRepository implements RecipeRepository {
  SupabaseRecipeRepository(SupabaseClient client)
    : _dataSource = RecipesRemoteDataSource(client);

  final RecipesRemoteDataSource _dataSource;

  @override
  Future<List<Recipe>> getRecipes() async {
    final rows = await _dataSource.getRecipes();
    return rows.map((row) => RecipeModel.fromJson(row).toEntity()).toList();
  }

  @override
  Future<List<FoodItem>> searchFoods(String query) async {
    final rows = await _dataSource.searchFoods(query);
    return rows.map((row) => FoodItemModel.fromJson(row).toEntity()).toList();
  }

  @override
  Future<void> createRecipe({
    required String name,
    required double servings,
    required List<({int foodId, double quantity})> ingredients,
  }) async {
    final recipeId = await _dataSource.insertRecipe(
      name: name,
      servings: servings,
    );
    await _dataSource.insertRecipeIngredients(recipeId, ingredients);
  }

  @override
  Future<void> updateRecipe({
    required int recipeId,
    required String name,
    required double servings,
    required List<({int foodId, double quantity})> ingredients,
  }) async {
    await _dataSource.updateRecipe(
      recipeId: recipeId,
      name: name,
      servings: servings,
    );
    await _dataSource.replaceRecipeIngredients(recipeId, ingredients);
  }

  @override
  Future<void> deleteRecipe(int recipeId) => _dataSource.deleteRecipe(recipeId);

  @override
  Future<void> logRecipeToDiary(int recipeId, MealType mealType) async {
    final row = await _dataSource.getRecipeById(recipeId);
    final recipe = RecipeModel.fromJson(row).toEntity();
    final perServing = recipePerServing(recipe);

    await _dataSource.insertFoodLog({
      'logged_at': DateTime.now().toUtc().toIso8601String(),
      'recipe_id': recipeId,
      'food_id': null,
      'quantity': 1,
      'calories': perServing.calories,
      'protein_g': perServing.proteinG,
      'carbs_g': perServing.carbsG,
      'fat_g': perServing.fatG,
      'meal_type': mealType.name,
    });
  }
}
