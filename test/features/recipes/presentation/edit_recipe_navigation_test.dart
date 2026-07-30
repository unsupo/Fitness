import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/pages/add_recipe_page.dart';
import 'package:arndt_fitness/features/recipes/presentation/pages/recipes_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../diary/fakes/fake_diary_repository.dart';
import '../fakes/fake_recipe_repository.dart';

void main() {
  testWidgets(
    'tapping the recipe name on a card opens it pre-filled, and saving '
    'refreshes the list',
    (tester) async {
      final fake = FakeRecipeRepository();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const RecipesListPage()),
          GoRoute(
            path: '/recipes/add',
            builder: (context, state) =>
                AddRecipePage(recipeToEdit: state.extra as Recipe?),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(fake),
            diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Chicken Rice Bowl'), findsOneWidget);

      await tester.tap(find.text('Chicken Rice Bowl'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Recipe'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('name-field')),
        'Chicken Rice Bowl (updated)',
      );
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back on the list, showing the updated name, not the stale one.
      expect(find.text('Chicken Rice Bowl'), findsNothing);
      expect(find.text('Chicken Rice Bowl (updated)'), findsOneWidget);
    },
  );
}
