import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around [SupabaseClient] — one method per query. Returns raw
/// decoded JSON; mapping to domain entities happens in the repository/model
/// layer, not here.
class RecipesRemoteDataSource {
  RecipesRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _recipeSelect =
      '*, recipe_ingredients(quantity, quantity_unit, foods(id, name, calories, protein_g, carbs_g, fat_g, serving_size, serving_unit))';

  Future<List<Map<String, dynamic>>> getRecipes() async {
    final rows = await _client
        .from(SupabaseTables.recipes)
        .select(_recipeSelect);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> getRecipeById(int id) async {
    return await _client
        .from(SupabaseTables.recipes)
        .select(_recipeSelect)
        .eq('id', id)
        .single();
  }

  /// Empty [query] returns every food row (there are only ~7 right now).
  Future<List<Map<String, dynamic>>> searchFoods(String query) async {
    final rows = query.isEmpty
        ? await _client.from(SupabaseTables.foods).select()
        : await _client
              .from(SupabaseTables.foods)
              .select()
              .ilike('name', '%$query%');

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Inserts a `recipes` row and returns its generated `id` (read back from
  /// the insert response, never assumed/hardcoded).
  Future<int> insertRecipe({required String name, required double servings}) async {
    final row = await _client
        .from(SupabaseTables.recipes)
        .insert({'name': name, 'servings': servings})
        .select('id')
        .single();

    return row['id'] as int;
  }

  Future<void> insertRecipeIngredients(
    int recipeId,
    List<({int foodId, double quantity, String quantityUnit})> ingredients,
  ) async {
    await _client.from(SupabaseTables.recipeIngredients).insert([
      for (final ingredient in ingredients)
        {
          'recipe_id': recipeId,
          'food_id': ingredient.foodId,
          'quantity': ingredient.quantity,
          'quantity_unit': ingredient.quantityUnit,
        },
    ]);
  }

  Future<void> insertFoodLog(Map<String, dynamic> row) async {
    await _client.from(SupabaseTables.foodLog).insert(row);
  }

  Future<void> updateRecipe({
    required int recipeId,
    required String name,
    required double servings,
  }) async {
    await _client
        .from(SupabaseTables.recipes)
        .update({'name': name, 'servings': servings})
        .eq('id', recipeId);
  }

  /// Full replace: deletes every existing ingredient row for [recipeId] then
  /// inserts the new set. Simpler and safer than diffing when the whole form
  /// is re-submitted on every save.
  Future<void> replaceRecipeIngredients(
    int recipeId,
    List<({int foodId, double quantity, String quantityUnit})> ingredients,
  ) async {
    await _client
        .from(SupabaseTables.recipeIngredients)
        .delete()
        .eq('recipe_id', recipeId);
    await insertRecipeIngredients(recipeId, ingredients);
  }

  Future<void> deleteRecipe(int recipeId) async {
    await _client.from(SupabaseTables.recipes).delete().eq('id', recipeId);
  }
}
