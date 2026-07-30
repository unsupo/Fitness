import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/logged_quantity_converter.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:arndt_fitness/features/recipes/domain/repositories/recipe_repository.dart';

/// A canned [RecipeRepository] for widget tests — no real network/Supabase
/// calls. Returns fixed recipes/foods and records calls made against it so
/// tests can assert the presentation layer talked to the adapter correctly.
class FakeRecipeRepository implements RecipeRepository {
  FakeRecipeRepository({List<Recipe>? recipes, List<FoodItem>? foods})
    : recipes = List.of(recipes ?? defaultRecipes),
      foods = foods ?? defaultFoods;

  final List<Recipe> recipes;
  final List<FoodItem> foods;

  static const defaultFoods = <FoodItem>[
    FoodItem(
      id: 1,
      name: 'Chicken Breast',
      calories: 165,
      proteinG: 31,
      carbsG: 0,
      fatG: 3.6,
    ),
    FoodItem(
      id: 2,
      name: 'White Rice',
      calories: 130,
      proteinG: 2.7,
      carbsG: 28,
      fatG: 0.3,
    ),
    FoodItem(
      id: 3,
      name: 'Olive Oil',
      calories: 120,
      proteinG: 0,
      carbsG: 0,
      fatG: 14,
    ),
  ];

  static final defaultRecipes = <Recipe>[
    Recipe(
      id: 1,
      name: 'Chicken Rice Bowl',
      servings: 2,
      ingredients: const [
        RecipeIngredientFixture.chicken,
        RecipeIngredientFixture.rice,
      ],
    ),
  ];

  ({int recipeId, MealType mealType, double portionQuantity})? lastLogRecipeToDiaryCall;

  /// Records the arguments of the last `createRecipe` call.
  ({
    String name,
    double servings,
    List<({int foodId, double quantity, String quantityUnit})> ingredients,
  })?
  lastCreateRecipeCall;

  /// Records the arguments of the last `updateRecipe` call.
  ({
    int recipeId,
    String name,
    double servings,
    List<({int foodId, double quantity, String quantityUnit})> ingredients,
  })?
  lastUpdateRecipeCall;

  /// Records the id passed to the last `deleteRecipe` call.
  int? lastDeleteRecipeCall;

  @override
  Future<List<Recipe>> getRecipes() async => recipes;

  @override
  Future<List<FoodItem>> searchFoods(String query) async {
    if (query.isEmpty) return foods;
    return foods
        .where((f) => f.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  @override
  Future<void> createRecipe({
    required String name,
    required double servings,
    required List<({int foodId, double quantity, String quantityUnit})> ingredients,
  }) async {
    lastCreateRecipeCall = (
      name: name,
      servings: servings,
      ingredients: ingredients,
    );

    // Mirror the real Supabase adapter: after creating, the recipe exists
    // and shows up in subsequent getRecipes() calls.
    recipes.add(
      Recipe(
        id: recipes.length + 1,
        name: name,
        servings: servings,
        ingredients: [
          for (final ing in ingredients)
            () {
              final food = foods.firstWhere((f) => f.id == ing.foodId);
              return RecipeIngredient(
                foodId: food.id,
                foodName: food.name,
                quantity: LoggedQuantityConverter.fromServingMultiplier(
                  ing.quantity,
                  servingSize: food.servingSize,
                  servingUnit: food.servingUnit,
                ),
                calories: food.calories * ing.quantity,
                proteinG: food.proteinG * ing.quantity,
                carbsG: food.carbsG * ing.quantity,
                fatG: food.fatG * ing.quantity,
                servingSize: food.servingSize,
                servingUnit: food.servingUnit,
              );
            }(),
        ],
      ),
    );
  }

  @override
  Future<void> updateRecipe({
    required int recipeId,
    required String name,
    required double servings,
    required List<({int foodId, double quantity, String quantityUnit})> ingredients,
  }) async {
    lastUpdateRecipeCall = (
      recipeId: recipeId,
      name: name,
      servings: servings,
      ingredients: ingredients,
    );

    final index = recipes.indexWhere((r) => r.id == recipeId);
    if (index == -1) return;

    recipes[index] = Recipe(
      id: recipeId,
      name: name,
      servings: servings,
      ingredients: [
        for (final ing in ingredients)
          () {
            final food = foods.firstWhere((f) => f.id == ing.foodId);
            return RecipeIngredient(
              foodId: food.id,
              foodName: food.name,
              quantity: LoggedQuantityConverter.fromServingMultiplier(
                ing.quantity,
                servingSize: food.servingSize,
                servingUnit: food.servingUnit,
              ),
              calories: food.calories * ing.quantity,
              proteinG: food.proteinG * ing.quantity,
              carbsG: food.carbsG * ing.quantity,
              fatG: food.fatG * ing.quantity,
              servingSize: food.servingSize,
              servingUnit: food.servingUnit,
            );
          }(),
      ],
    );
  }

  @override
  Future<void> deleteRecipe(int recipeId) async {
    lastDeleteRecipeCall = recipeId;
    recipes.removeWhere((r) => r.id == recipeId);
  }

  @override
  Future<void> logRecipeToDiary(int recipeId, MealType mealType, {double portionQuantity = 1.0}) async {
    lastLogRecipeToDiaryCall = (recipeId: recipeId, mealType: mealType, portionQuantity: portionQuantity);
  }
}

/// Shared ingredient fixtures used by [FakeRecipeRepository.defaultRecipes].
abstract final class RecipeIngredientFixture {
  static const chicken = RecipeIngredient(
    foodId: 1,
    foodName: 'Chicken Breast',
    quantity: LoggedQuantity(amount: 2.0, unit: 'serving'),
    calories: 330,
    proteinG: 62,
    carbsG: 0,
    fatG: 7.2,
  );

  static const rice = RecipeIngredient(
    foodId: 2,
    foodName: 'White Rice',
    quantity: LoggedQuantity(amount: 1.0, unit: 'serving'),
    calories: 130,
    proteinG: 2.7,
    carbsG: 28,
    fatG: 0.3,
  );
}
