import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/domain/entities/online_food_candidate.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/pages/add_recipe_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../diary/fakes/fake_diary_repository.dart';
import '../fakes/fake_recipe_repository.dart';

void main() {
  group('AddRecipePage', () {
    testWidgets(
      'fills in name/servings/ingredient, updates preview, and saves',
      (tester) async {
        final fake = FakeRecipeRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              recipeRepositoryProvider.overrideWithValue(fake),
              diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
            ],
            child: const MaterialApp(home: AddRecipePage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('name-field')),
          'My Recipe',
        );
        await tester.enterText(
          find.byKey(const Key('servings-field')),
          '2',
        );
        await tester.pump();

        // Preview should be all-zero before any ingredient is selected.
        expect(find.text('0 cal total'), findsOneWidget);

        // Select a food for the first (default) ingredient row.
        await tester.enterText(
          find.byKey(const Key('food-field-0')),
          'Chicken',
        );
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(ListTile, 'Chicken Breast'),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('quantity-field-0')),
          '2',
        );
        await tester.pump();

        // Chicken Breast: 165 cal * quantity 2 = 330 total, /2 servings = 165.
        expect(find.text('330 cal total'), findsOneWidget);
        expect(find.text('165 cal / serving'), findsOneWidget);

        // "Add ingredient" grows the list with a new blank row.
        await tester.tap(find.text('Add ingredient'));
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('food-field-1')), findsOneWidget);

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(fake.lastCreateRecipeCall, isNotNull);
        expect(fake.lastCreateRecipeCall!.name, 'My Recipe');
        expect(fake.lastCreateRecipeCall!.servings, 2);
        expect(fake.lastCreateRecipeCall!.ingredients, [
          (foodId: 1, quantity: 2.0, quantityUnit: 'serving'),
        ]);
      },
    );

    testWidgets('allows adding and removing ingredients', (tester) async {
      final fake = FakeRecipeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(fake),
            diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
          ],
          child: const MaterialApp(home: AddRecipePage()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially 1 ingredient row. Delete button should not show when only 1 row.
      expect(find.byTooltip('Remove ingredient'), findsNothing);

      // Add a second row
      await tester.tap(find.text('Add ingredient'));
      await tester.pumpAndSettle();

      // Now we have 2 rows, so both should have a delete button.
      expect(find.byTooltip('Remove ingredient'), findsNWidgets(2));

      // Remove the second row
      await tester.tap(find.byKey(const Key('remove-ingredient-1')));
      await tester.pumpAndSettle();

      // Back to 1 row, no delete button.
      expect(find.byTooltip('Remove ingredient'), findsNothing);
    });

    testWidgets(
      'the ingredient list is collapsible, expanded by default, showing '
      'a count that stays visible either way',
      (tester) async {
        final fake = FakeRecipeRepository();
        final recipeToEdit = fake.recipes.first; // Chicken Rice Bowl, 2 ingredients.

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              recipeRepositoryProvider.overrideWithValue(fake),
              diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
            ],
            child: MaterialApp(home: AddRecipePage(recipeToEdit: recipeToEdit)),
          ),
        );
        await tester.pumpAndSettle();

        // Expanded by default — existing ingredient rows are editable.
        expect(find.text('Ingredients (2)'), findsOneWidget);
        expect(find.byKey(const Key('food-field-0')), findsOneWidget);
        expect(find.byKey(const Key('food-field-1')), findsOneWidget);

        await tester.tap(find.text('Ingredients (2)'));
        await tester.pumpAndSettle();

        // Collapsed — rows hidden, but the count heading stays.
        expect(find.text('Ingredients (2)'), findsOneWidget);
        expect(find.byKey(const Key('food-field-0')), findsNothing);
        expect(find.byKey(const Key('food-field-1')), findsNothing);

        await tester.tap(find.text('Ingredients (2)'));
        await tester.pumpAndSettle();

        // Expands again.
        expect(find.byKey(const Key('food-field-0')), findsOneWidget);
        expect(find.byKey(const Key('food-field-1')), findsOneWidget);
      },
    );

    testWidgets('shows a validation error and does not save when incomplete', (
      tester,
    ) async {
      final fake = FakeRecipeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(fake),
            diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
          ],
          child: const MaterialApp(home: AddRecipePage()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fake.lastCreateRecipeCall, isNull);
    });
  });

  group('AddRecipePage editing', () {
    testWidgets('pre-fills fields from recipeToEdit and calls updateRecipe on save', (
      tester,
    ) async {
      final fake = FakeRecipeRepository();
      final recipeToEdit = fake.recipes.first; // Chicken Rice Bowl, id 1.

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(fake),
            diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
          ],
          child: MaterialApp(home: AddRecipePage(recipeToEdit: recipeToEdit)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Recipe'), findsOneWidget);
      expect(find.text('Chicken Rice Bowl'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('servings-field')))
            .controller!
            .text,
        '2',
      );
      expect(find.text('Chicken Breast'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('name-field')),
        'Chicken Rice Bowl (updated)',
      );
      await tester.pump();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fake.lastUpdateRecipeCall, isNotNull);
      expect(fake.lastUpdateRecipeCall!.recipeId, recipeToEdit.id);
      expect(
        fake.lastUpdateRecipeCall!.name,
        'Chicken Rice Bowl (updated)',
      );
      expect(fake.lastUpdateRecipeCall!.servings, 2);
      expect(fake.lastUpdateRecipeCall!.ingredients, [
        (foodId: 1, quantity: 2.0, quantityUnit: 'serving'),
        (foodId: 2, quantity: 1.0, quantityUnit: 'serving'),
      ]);
      expect(fake.lastCreateRecipeCall, isNull);
    });

    testWidgets('shows a Delete button in edit mode that calls deleteRecipe', (
      tester,
    ) async {
      final fake = FakeRecipeRepository();
      final recipeToEdit = fake.recipes.first;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(fake),
            diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
          ],
          child: MaterialApp(home: AddRecipePage(recipeToEdit: recipeToEdit)),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Delete recipe'));
      await tester.pumpAndSettle();

      // Confirmation dialog.
      expect(find.text('Delete recipe?'), findsOneWidget);
      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();

      expect(fake.lastDeleteRecipeCall, recipeToEdit.id);
    });

    testWidgets('does not show a Delete button when creating a new recipe', (
      tester,
    ) async {
      final fake = FakeRecipeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            recipeRepositoryProvider.overrideWithValue(fake),
            diaryRepositoryProvider.overrideWithValue(FakeDiaryRepository()),
          ],
          child: const MaterialApp(home: AddRecipePage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Delete recipe'), findsNothing);
    });
  });

  group('AddRecipePage food search', () {
    testWidgets(
      'shows a Recent section when the food field is empty, and selecting '
      'one fills it in',
      (tester) async {
        final fake = FakeRecipeRepository();
        final diaryFake = FakeDiaryRepository(
          recentFoods: const [
            FoodItem(
              id: 42,
              name: 'Protein Shake',
              calories: 160,
              proteinG: 25,
              carbsG: 5,
              fatG: 2,
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              recipeRepositoryProvider.overrideWithValue(fake),
              diaryRepositoryProvider.overrideWithValue(diaryFake),
            ],
            child: const MaterialApp(home: AddRecipePage()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Recent'), findsOneWidget);
        expect(find.text('Protein Shake'), findsOneWidget);

        await tester.tap(find.widgetWithText(ListTile, 'Protein Shake'));
        await tester.pumpAndSettle();

        expect(
          tester
              .widget<TextField>(find.byKey(const Key('food-field-0')))
              .controller!
              .text,
          'Protein Shake',
        );
        // Selecting a food clears the Recent section (query no longer empty).
        expect(find.text('Recent'), findsNothing);
      },
    );

    testWidgets(
      'shows local and OpenFoodFacts results while searching, and selecting '
      'an OpenFoodFacts result imports it',
      (tester) async {
        final fake = FakeRecipeRepository();
        final diaryFake = FakeDiaryRepository(
          onlineFoods: const [
            OnlineFoodCandidate(
              name: 'Online Snack',
              calories: 210,
              proteinG: 4,
              carbsG: 30,
              fatG: 8,
              sourceUrl: 'https://world.openfoodfacts.org/product/999',
            ),
          ],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              recipeRepositoryProvider.overrideWithValue(fake),
              diaryRepositoryProvider.overrideWithValue(diaryFake),
            ],
            child: const MaterialApp(home: AddRecipePage()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('food-field-0')),
          'Chicken',
        );
        await tester.pumpAndSettle();

        // Local match still shows.
        expect(find.widgetWithText(ListTile, 'Chicken Breast'), findsOneWidget);
        // Online section shows alongside it.
        expect(find.text('From OpenFoodFacts'), findsOneWidget);
        expect(find.widgetWithText(ListTile, 'Online Snack'), findsOneWidget);

        await tester.tap(find.widgetWithText(ListTile, 'Online Snack'));
        await tester.pumpAndSettle();

        expect(diaryFake.lastImportedCandidate, isNotNull);
        expect(diaryFake.lastImportedCandidate!.name, 'Online Snack');
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('food-field-0')))
              .controller!
              .text,
          'Online Snack',
        );
      },
    );
  });
}
