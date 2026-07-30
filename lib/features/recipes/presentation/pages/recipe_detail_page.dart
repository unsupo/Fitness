import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/recipe.dart';
import '../controllers/recipes_providers.dart';
import 'add_recipe_page.dart';

/// Reached by tapping a recipe-logged diary entry (`DiaryEntry.recipeId`),
/// which only has the recipe's id, not the full [Recipe] object needed by
/// [AddRecipePage]. Looks it up from [recipesListProvider] first, then
/// hands off to the same view/edit/delete page recipes already use from
/// the Recipes tab — no separate read-only page needed.
class RecipeDetailPage extends ConsumerWidget {
  const RecipeDetailPage({super.key, required this.recipeId});

  final int recipeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesListProvider);

    return recipesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load recipe: $error')),
      ),
      data: (recipes) {
        Recipe? recipe;
        for (final candidate in recipes) {
          if (candidate.id == recipeId) {
            recipe = candidate;
            break;
          }
        }
        if (recipe == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: Text('This recipe no longer exists.'),
            ),
          );
        }
        return AddRecipePage(recipeToEdit: recipe);
      },
    );
  }
}
