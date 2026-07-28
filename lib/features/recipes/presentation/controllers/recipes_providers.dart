import 'package:arndt_fitness/core/di/backend.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final recipeRepositoryProvider = Provider<RecipeRepository>(
  (ref) => ref.watch(backendProvider).createRecipeRepository(),
);

final recipesListProvider = FutureProvider<List<Recipe>>(
  (ref) => ref.watch(recipeRepositoryProvider).getRecipes(),
);

final foodSearchProvider = FutureProvider.family<List<FoodItem>, String>(
  (ref, query) => ref.watch(recipeRepositoryProvider).searchFoods(query),
);
