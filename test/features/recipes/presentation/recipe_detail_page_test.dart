import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/pages/recipe_detail_page.dart';

import '../../diary/fakes/fake_diary_repository.dart';
import '../fakes/fake_recipe_repository.dart';

void main() {
  testWidgets('looks up the recipe by id and shows its detail/edit view', (
    tester,
  ) async {
    final fake = FakeRecipeRepository();
    final recipe = fake.recipes.first; // Chicken Rice Bowl, id 1.

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeRepositoryProvider.overrideWithValue(fake),
          diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
        ],
        child: MaterialApp(home: RecipeDetailPage(recipeId: recipe.id)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chicken Rice Bowl'), findsOneWidget);
    expect(find.text('Chicken Breast'), findsOneWidget);
  });

  testWidgets('shows a friendly message when the recipe no longer exists', (
    tester,
  ) async {
    final fake = FakeRecipeRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          recipeRepositoryProvider.overrideWithValue(fake),
          diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
        ],
        child: const MaterialApp(home: RecipeDetailPage(recipeId: 999999)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This recipe no longer exists.'), findsOneWidget);
  });
}
