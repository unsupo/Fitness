import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/widgets/log_recipe_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_recipe_repository.dart';

void main() {
  group('LogRecipeDialog', () {
    testWidgets(
      'renders recipe information, meal type selection, collapsible ingredients, and confirms log',
      (tester) async {
        final fake = FakeRecipeRepository();
        final recipe = fake.recipes.first; // Chicken Rice Bowl

        await tester.pumpWidget(
          ProviderScope(
            overrides: [recipeRepositoryProvider.overrideWithValue(fake)],
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) {
                    return ElevatedButton(
                      onPressed: () => showLogRecipeDialog(context, recipe),
                      child: const Text('Show'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Open the dialog
        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        // Verify recipe details rendering
        expect(find.text('Log Chicken Rice Bowl'), findsOneWidget);
        expect(find.textContaining('Chicken Breast'), findsNothing); // Collapsed initially

        // Expand the ingredients tile
        await tester.tap(find.textContaining('Ingredients (2)'));
        await tester.pumpAndSettle();

        // Verify expanded ingredients are visible
        expect(find.text('Chicken Breast'), findsOneWidget);
        expect(find.text('White Rice'), findsOneWidget);

        // Change servings to log to 3
        await tester.enterText(find.widgetWithText(TextField, 'Servings to log'), '3');
        await tester.pumpAndSettle();

        // Tap the Log button
        await tester.tap(find.widgetWithText(FilledButton, 'Log'));
        await tester.pumpAndSettle();

        // Verify dialog closes and calls repository
        expect(find.text('Log Chicken Rice Bowl'), findsNothing);
        expect(fake.lastLogRecipeToDiaryCall?.recipeId, 1);
        expect(fake.lastLogRecipeToDiaryCall?.mealType, MealType.snack);
        expect(fake.lastLogRecipeToDiaryCall?.portionQuantity, 3.0);
      },
    );
  });
}
