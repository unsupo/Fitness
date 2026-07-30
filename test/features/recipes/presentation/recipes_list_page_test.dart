import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/pages/recipes_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

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
      // No pencil icon — the card itself is tap-to-edit.
      expect(find.byIcon(Icons.edit_outlined), findsNothing);
    });

    testWidgets('tapping the recipe name navigates to the edit page', (
      tester,
    ) async {
      final fake = FakeRecipeRepository();
      Recipe? pushedRecipe;

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const RecipesListPage()),
          GoRoute(
            path: '/recipes/add',
            builder: (context, state) {
              pushedRecipe = state.extra as Recipe?;
              return const Scaffold(body: Text('Edit Recipe Page'));
            },
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [recipeRepositoryProvider.overrideWithValue(fake)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chicken Rice Bowl'));
      await tester.pumpAndSettle();

      expect(pushedRecipe?.id, 1);
    });

    testWidgets(
      'swiping past the delete threshold removes the recipe and calls deleteRecipe',
      (tester) async {
        final fake = FakeRecipeRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [recipeRepositoryProvider.overrideWithValue(fake)],
            child: const MaterialApp(home: RecipesListPage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Chicken Rice Bowl'), findsOneWidget);

        await tester.drag(find.text('Chicken Rice Bowl'), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(fake.lastDeleteRecipeCall, 1);
        expect(find.text('Chicken Rice Bowl'), findsNothing);
      },
    );

    testWidgets(
      'pulling to refresh re-fetches the recipe list, same as Home/Trends',
      (tester) async {
        final fake = FakeRecipeRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [recipeRepositoryProvider.overrideWithValue(fake)],
            child: const MaterialApp(home: RecipesListPage()),
          ),
        );
        await tester.pumpAndSettle();

        final callsBeforeRefresh = fake.getRecipesCallCount;
        expect(callsBeforeRefresh, greaterThan(0));

        await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
        await tester.pumpAndSettle();

        expect(fake.getRecipesCallCount, greaterThan(callsBeforeRefresh));
      },
    );

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

      // Confirm in the LogRecipeDialog
      await tester.tap(find.widgetWithText(FilledButton, 'Log'));
      await tester.pumpAndSettle();

      expect(fake.lastLogRecipeToDiaryCall?.recipeId, 1);
    });
  });
}
