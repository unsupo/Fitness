import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/pages/recipes_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_recipe_repository.dart';

void main() {
  group('RecipesListPage', () {
    testWidgets('renders recipe name and computed per-serving calories', (
      tester,
    ) async {
      final fake = FakeRecipeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [recipeRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: RecipesListPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Fixture recipe: chicken (330) + rice (130) = 460 total, 2 servings
      // -> 230 cal/serving.
      expect(find.text('Chicken Rice Bowl'), findsOneWidget);
      expect(find.textContaining('230'), findsOneWidget);
      expect(find.text('Log to diary'), findsOneWidget);
    });

    testWidgets('shows empty state when there are no recipes', (
      tester,
    ) async {
      final fake = FakeRecipeRepository(recipes: const <Recipe>[]);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [recipeRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: RecipesListPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No recipes yet'), findsOneWidget);
    });

    testWidgets('tapping "Log to diary" calls the repository and pops', (
      tester,
    ) async {
      final fake = FakeRecipeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [recipeRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: RecipesListPage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log to diary'));
      await tester.pumpAndSettle();

      expect(fake.lastLogRecipeToDiaryCall?.recipeId, 1);
    });
  });
}
