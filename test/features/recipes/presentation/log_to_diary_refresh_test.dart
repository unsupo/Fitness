import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/pages/recipes_list_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../diary/fakes/fake_diary_repository.dart';
import '../fakes/fake_recipe_repository.dart';

void main() {
  testWidgets(
    'logging a recipe to the diary invalidates the diary entries provider',
    (tester) async {
      final fakeRecipes = FakeRecipeRepository();
      final fakeDiary = FakeDiaryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(fakeRecipes),
            diaryRepositoryProvider.overrideWithValue(fakeDiary),
          ],
          child: MaterialApp(
            home: Column(
              children: [
                // Mounts diaryEntriesProvider so we can observe refetches,
                // mirroring the real app having the Diary tab alive in the
                // StatefulShellRoute IndexedStack alongside Recipes.
                Consumer(
                  builder: (context, ref, _) {
                    ref.watch(diaryEntriesProvider(DateTime(2026, 7, 21)));
                    return const SizedBox.shrink();
                  },
                ),
                const Expanded(child: RecipesListPage()),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(fakeDiary.getEntriesForDateCallCount, 1);

      await tester.tap(find.text('Log to diary'));
      await tester.pumpAndSettle();

      expect(
        fakeDiary.getEntriesForDateCallCount,
        2,
        reason:
            'logRecipeToDiary must invalidate diaryEntriesProvider so the '
            'diary refetches and shows the newly logged recipe',
      );
    },
  );
}
