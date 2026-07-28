import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
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
    'creating a recipe and navigating back refreshes the recipes list',
    (tester) async {
      final fake = FakeRecipeRepository(recipes: []);

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const RecipesListPage()),
          GoRoute(
            path: '/recipes/add',
            builder: (context, state) => const AddRecipePage(),
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

      expect(find.text('No recipes yet'), findsOneWidget);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.add));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('name-field')), 'New Recipe');
      await tester.enterText(find.byKey(const Key('servings-field')), '1');
      await tester.enterText(
        find.byKey(const Key('food-field-0')),
        'Chicken',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ListTile, 'Chicken Breast'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Back on the list — it must show the just-created recipe, not the
      // stale empty snapshot from before navigating away.
      expect(find.text('No recipes yet'), findsNothing);
      expect(find.text('New Recipe'), findsOneWidget);
    },
  );
}
