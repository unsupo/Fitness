import 'package:arndt_fitness/core/network/supabase_json.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe_ingredient.dart';

/// Maps a `recipes` row joined with
/// `recipe_ingredients(quantity, foods(id, name, calories, protein_g, carbs_g, fat_g))`
/// (see `RecipesRemoteDataSource.getRecipes`) to a [Recipe].
class RecipeModel {
  const RecipeModel({
    required this.id,
    required this.name,
    required this.servings,
    required this.ingredients,
  });

  final int id;
  final String name;
  final double servings;
  final List<RecipeIngredient> ingredients;

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final rawIngredients = List<Map<String, dynamic>>.from(
      json['recipe_ingredients'] as List? ?? const [],
    );

    final ingredients = rawIngredients.map((row) {
      final food = row['foods'] as Map<String, dynamic>;
      final quantity = parseSupabaseNum(row['quantity']);
      final foodCalories = parseSupabaseNum(food['calories']);
      final foodProteinG = parseSupabaseNum(food['protein_g']);
      final foodCarbsG = parseSupabaseNum(food['carbs_g']);
      final foodFatG = parseSupabaseNum(food['fat_g']);

      return RecipeIngredient(
        foodId: food['id'] as int,
        foodName: food['name'] as String,
        quantity: quantity,
        calories: quantity * foodCalories,
        proteinG: quantity * foodProteinG,
        carbsG: quantity * foodCarbsG,
        fatG: quantity * foodFatG,
      );
    }).toList();

    return RecipeModel(
      id: json['id'] as int,
      name: json['name'] as String,
      servings: parseSupabaseNum(json['servings']),
      ingredients: ingredients,
    );
  }

  Recipe toEntity() => Recipe(
    id: id,
    name: name,
    servings: servings,
    ingredients: ingredients,
  );
}
