import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/quick_add_modal.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';

import '../fakes/fake_diary_repository.dart';
import '../../recipes/fakes/fake_recipe_repository.dart';

void main() {
  testWidgets('QuickAddModal shows recent foods and searches local foods', (
    tester,
  ) async {
    final fakeDiary = FakeDiaryRepository(
      recentFoods: const [
        FoodItem(
          id: 5,
          name: 'Recent Oatmeal',
          calories: 250,
          proteinG: 8,
          carbsG: 45,
          fatG: 4,
        ),
      ],
    );
    final fakeRecipe = FakeRecipeRepository(
      foods: const [
        FoodItem(
          id: 6,
          name: 'Search Apple',
          calories: 95,
          proteinG: 0,
          carbsG: 25,
          fatG: 0,
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diaryRepositoryProvider.overrideWithValue(fakeDiary),
          recipeRepositoryProvider.overrideWithValue(fakeRecipe),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: QuickAddModal(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify "Recent Foods" and "Recent Oatmeal" are visible
    expect(find.text('Recent Foods'), findsOneWidget);
    expect(find.text('Recent Oatmeal'), findsOneWidget);

    // Type in search bar
    await tester.enterText(find.byType(TextField).first, 'Apple');
    await tester.pump(); // Start search
    await tester.pumpAndSettle();

    // Verify search result is visible
    expect(find.text('Search Results'), findsOneWidget);
    expect(find.text('Search Apple'), findsOneWidget);
    expect(find.text('Recent Oatmeal'), findsNothing);

    // Tap the plus button to log it directly
    await tester.tap(find.byIcon(Icons.add_circle));
    await tester.pumpAndSettle();

    expect(fakeDiary.lastLoggedFoodId, 6);
  });
}
