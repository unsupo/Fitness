import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/meal_section.dart';

import 'package:arndt_fitness/core/entities/logged_quantity.dart';

void main() {
  final entries = [
    DiaryEntry(
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
    ),
  ];

  testWidgets('shows quantity and logged time, and navigates to food detail on tap', (
    tester,
  ) async {
    String? pushedFoodDetailId;

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              Scaffold(body: MealSection(mealType: MealType.breakfast, entries: entries)),
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

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    expect(find.textContaining('0.5'), findsOneWidget);
    final thumbnail = tester.widget<FoodThumbnail>(find.byType(FoodThumbnail));
    expect(thumbnail.imageUrl, 'https://images.example.com/pringles.jpg');

    await tester.tap(find.text('BBQ Pringles'));
    await tester.pumpAndSettle();

    expect(pushedFoodDetailId, '3');
  });

  testWidgets(
    'navigates to the recipe detail route when a recipe-based entry is tapped',
    (tester) async {
      String? pushedRecipeDetailId;

      final recipeEntries = [
        DiaryEntry(
          id: 5,
          loggedAt: DateTime(2026, 7, 21, 8, 36),
          mealType: MealType.breakfast,
          foodName: 'Protein Snack Plate',
          quantity: const LoggedQuantity(amount: 1, unit: 'serving'),
          calories: 400,
          proteinG: 20,
          carbsG: 30,
          fatG: 10,
          recipeId: 9,
        ),
      ];

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: MealSection(
                mealType: MealType.breakfast,
                entries: recipeEntries,
              ),
            ),
          ),
          GoRoute(
            path: '/recipes/detail/:id',
            builder: (context, state) {
              pushedRecipeDetailId = state.pathParameters['id'];
              return const Scaffold(body: Text('Recipe Detail'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      await tester.tap(find.text('Protein Snack Plate'));
      await tester.pumpAndSettle();

      expect(pushedRecipeDetailId, '9');
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

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MealSection(mealType: MealType.breakfast, entries: [messyEntry]),
        ),
      ),
    );

    expect(find.textContaining('1.8x'), findsOneWidget);
    expect(find.textContaining('1.804511'), findsNothing);
  });
}
