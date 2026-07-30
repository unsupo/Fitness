import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/meal_section.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';

import '../fakes/fake_diary_repository.dart';
import '../../recipes/fakes/fake_recipe_repository.dart';

void main() {
  final foodEntry = DiaryEntry(
    id: 1,
    loggedAt: DateTime(2026, 7, 21, 8, 36),
    mealType: MealType.breakfast,
    foodName: 'BBQ Pringles',
    quantity: const LoggedQuantity(amount: 0.5, unit: 'serving'),
    calories: 75,
    proteinG: 0.5,
    carbsG: 7.5,
    fatG: 4.5,
    foodId: 3,
    imageUrl: 'https://images.example.com/pringles.jpg',
  );

  final recipeEntry = DiaryEntry(
    id: 5,
    loggedAt: DateTime(2026, 7, 21, 8, 36),
    mealType: MealType.breakfast,
    foodName: 'Chicken Rice Bowl',
    quantity: const LoggedQuantity(amount: 1, unit: 'serving'),
    calories: 460,
    proteinG: 64.7,
    carbsG: 28,
    fatG: 7.5,
    recipeId: 1,
  );

  Future<void> pumpSection(
    WidgetTester tester, {
    required List<DiaryEntry> entries,
    FakeDiaryRepository? diaryFake,
    FakeRecipeRepository? recipeFake,
    GoRouter? router,
  }) async {
    final providerScope = ProviderScope(
      overrides: [
        diaryRepositoryProvider.overrideWithValue(diaryFake ?? FakeDiaryRepository()),
        recipeRepositoryProvider.overrideWithValue(recipeFake ?? FakeRecipeRepository()),
      ],
      child: router != null
          ? MaterialApp.router(routerConfig: router)
          : MaterialApp(
              home: Scaffold(
                body: MealSection(mealType: MealType.breakfast, entries: entries),
              ),
            ),
    );
    await tester.pumpWidget(providerScope);
    await tester.pumpAndSettle();
  }

  group('food entries', () {
    testWidgets('shows calories and logged time, with the quantity in an editable field', (
      tester,
    ) async {
      await pumpSection(tester, entries: [foodEntry]);

      expect(find.text('BBQ Pringles'), findsOneWidget);
      expect(find.textContaining('75 cal'), findsOneWidget);
      final thumbnail = tester.widget<FoodThumbnail>(find.byType(FoodThumbnail));
      expect(thumbnail.imageUrl, 'https://images.example.com/pringles.jpg');

      final qtyField = tester.widget<TextField>(
        find.byKey(const Key('entry-quantity-field-1')),
      );
      expect(qtyField.controller!.text, '0.5');
      expect(find.textContaining('serving'), findsOneWidget);
    });

    testWidgets('tap navigates to food-detail page', (tester) async {
      String? pushedFoodDetailId;
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MealSection(mealType: MealType.breakfast, entries: [foodEntry]),
            ),
          ),
          GoRoute(
            path: '/food-detail/:id',
            builder: (context, state) {
              pushedFoodDetailId = state.pathParameters['id'];
              return const Scaffold(body: Text('Food Detail'));
            },
          ),
        ],
      );

      await pumpSection(tester, entries: [foodEntry], router: router);

      await tester.tap(find.text('BBQ Pringles'));
      await tester.pumpAndSettle();

      expect(pushedFoodDetailId, '3');
    });

    testWidgets(
      'editing the quantity field and confirming rescales and saves the entry',
      (tester) async {
        final fake = FakeDiaryRepository(entries: [foodEntry]);
        await pumpSection(tester, entries: [foodEntry], diaryFake: fake);

        await tester.enterText(
          find.byKey(const Key('entry-quantity-field-1')),
          '1',
        );
        await tester.tap(find.byKey(const Key('entry-quantity-confirm-1')));
        await tester.pumpAndSettle();

        expect(fake.lastUpdatedEntry, isNotNull);
        expect(fake.lastUpdatedEntry!.id, 1);
        expect(fake.lastUpdatedEntry!.quantity.amount, 1.0);
        expect(fake.lastUpdatedEntry!.calories, 150);
        expect(fake.lastUpdatedEntry!.proteinG, 1.0);
      },
    );

    testWidgets(
      'swiping past the delete threshold removes the entry and calls deleteEntry',
      (tester) async {
        final fake = FakeDiaryRepository(entries: [foodEntry]);
        await pumpSection(tester, entries: [foodEntry], diaryFake: fake);

        expect(find.text('BBQ Pringles'), findsOneWidget);

        await tester.drag(find.text('BBQ Pringles'), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(fake.lastDeletedId, 1);
        expect(find.text('BBQ Pringles'), findsNothing);
      },
    );

    testWidgets('rounds messy floating-point quantities to one decimal place', (
      tester,
    ) async {
      final messyEntry = DiaryEntry(
        id: 2,
        loggedAt: DateTime(2026, 7, 20, 0, 6),
        mealType: MealType.breakfast,
        foodName: 'BBQ Chicken Pizza Slice',
        quantity: const LoggedQuantity(amount: 1.8045112781954886, unit: 'serving'),
        calories: 554,
        proteinG: 30.7,
        carbsG: 63.2,
        fatG: 19.9,
        foodId: 4,
      );

      await pumpSection(tester, entries: [messyEntry]);

      final qtyField = tester.widget<TextField>(
        find.byKey(const Key('entry-quantity-field-2')),
      );
      expect(qtyField.controller!.text, '1.8');
    });
  });

  group('recipe entries', () {
    testWidgets('renders collapsed by default, showing only the header', (
      tester,
    ) async {
      await pumpSection(tester, entries: [recipeEntry]);

      expect(find.text('Chicken Rice Bowl'), findsOneWidget);
      expect(find.textContaining('460 cal'), findsOneWidget);
      expect(find.text('Chicken Breast'), findsNothing);
      expect(find.text('White Rice'), findsNothing);
    });

    testWidgets(
      'tapping the header expands to show the recipe\'s ingredients, indented, '
      'and tapping again collapses it',
      (tester) async {
        await pumpSection(tester, entries: [recipeEntry]);

        await tester.tap(find.byKey(const Key('recipe-entry-header-5')));
        await tester.pumpAndSettle();

        expect(find.text('Chicken Breast'), findsOneWidget);
        expect(find.text('White Rice'), findsOneWidget);

        await tester.tap(find.byKey(const Key('recipe-entry-header-5')));
        await tester.pumpAndSettle();

        expect(find.text('Chicken Breast'), findsNothing);
        expect(find.text('White Rice'), findsNothing);
      },
    );

    testWidgets(
      'editing an ingredient\'s quantity and confirming calls updateRecipe '
      'with that ingredient rescaled',
      (tester) async {
        final recipeFake = FakeRecipeRepository();
        await pumpSection(tester, entries: [recipeEntry], recipeFake: recipeFake);

        await tester.tap(find.byKey(const Key('recipe-entry-header-5')));
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('ingredient-quantity-field-1')),
          '4',
        );
        await tester.tap(find.byKey(const Key('ingredient-quantity-confirm-1')));
        await tester.pumpAndSettle();

        expect(recipeFake.lastUpdateRecipeCall, isNotNull);
        expect(recipeFake.lastUpdateRecipeCall!.recipeId, 1);
        final updated = recipeFake.lastUpdateRecipeCall!.ingredients
            .firstWhere((i) => i.foodId == 1);
        expect(updated.quantity, 4.0);
        // The other ingredient is untouched.
        final untouched = recipeFake.lastUpdateRecipeCall!.ingredients
            .firstWhere((i) => i.foodId == 2);
        expect(untouched.quantity, 1.0);
      },
    );

    testWidgets(
      'swiping an ingredient past the delete threshold removes it from the '
      'recipe (calls updateRecipe without it)',
      (tester) async {
        final recipeFake = FakeRecipeRepository();
        await pumpSection(tester, entries: [recipeEntry], recipeFake: recipeFake);

        await tester.tap(find.byKey(const Key('recipe-entry-header-5')));
        await tester.pumpAndSettle();

        expect(find.text('Chicken Breast'), findsOneWidget);

        await tester.drag(find.text('Chicken Breast'), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(recipeFake.lastUpdateRecipeCall, isNotNull);
        expect(recipeFake.lastUpdateRecipeCall!.recipeId, 1);
        expect(
          recipeFake.lastUpdateRecipeCall!.ingredients.any((i) => i.foodId == 1),
          isFalse,
        );
        expect(find.text('Chicken Breast'), findsNothing);
      },
    );

    testWidgets(
      'swiping the recipe header past the delete threshold removes the '
      'whole diary entry (calls deleteEntry)',
      (tester) async {
        final diaryFake = FakeDiaryRepository(entries: [recipeEntry]);
        await pumpSection(tester, entries: [recipeEntry], diaryFake: diaryFake);

        await tester.drag(
          find.byKey(const Key('recipe-entry-header-5')),
          const Offset(-500, 0),
        );
        await tester.pumpAndSettle();

        expect(diaryFake.lastDeletedId, 5);
        expect(find.text('Chicken Rice Bowl'), findsNothing);
      },
    );
  });
}
