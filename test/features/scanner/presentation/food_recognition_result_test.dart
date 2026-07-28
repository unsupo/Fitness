import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_totals.dart';
import 'package:arndt_fitness/features/scanner/domain/entities/recognized_meal.dart';
import 'package:arndt_fitness/features/scanner/presentation/widgets/recognized_meal_result.dart';

void main() {
  const meal = RecognizedMeal(
    name: 'Arugula Salad with Grilled Chicken',
    estimatedCalories: 380,
    proteinG: 38,
    carbsG: 12,
    fatG: 22,
    servings: 1,
  );

  Future<void> pumpResult(
    WidgetTester tester, {
    required ValueChanged<RecognizedMeal> onSave,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RecognizedMealResult(meal: meal, onSave: onSave),
        ),
      ),
    );
  }

  testWidgets('renders meal name, calorie subtitle, and macro stats', (
    tester,
  ) async {
    await pumpResult(tester, onSave: (_) {});

    expect(find.text('Arugula Salad with Grilled Chicken'), findsOneWidget);
    expect(find.text('~380 kcal'), findsOneWidget);
    expect(find.text('380'), findsOneWidget); // calories stat
    expect(find.text('38g'), findsOneWidget); // protein
    expect(find.text('12g'), findsOneWidget); // carbs
    expect(find.text('22g'), findsOneWidget); // fat
    expect(find.text('1.0'), findsOneWidget); // initial servings
    expect(find.text('Save to Diary'), findsOneWidget);
  });

  testWidgets('+ / - adjust the displayed servings value', (tester) async {
    await pumpResult(tester, onSave: (_) {});

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(find.text('1.5'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('0.5'), findsOneWidget);

    // Clamped: shouldn't go below 0.5.
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('0.5'), findsOneWidget);
  });

  testWidgets('Save to Diary invokes onSave with the adjusted servings', (
    tester,
  ) async {
    RecognizedMeal? saved;
    await pumpResult(tester, onSave: (m) => saved = m);

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    await tester.tap(find.text('Save to Diary'));
    await tester.pump();

    expect(saved, isNotNull);
    expect(saved!.servings, 1.5);
    expect(saved!.name, meal.name);
    expect(saved!.estimatedCalories, meal.estimatedCalories);
  });

  group('remaining-after-adding caution', () {
    const goals = DailyGoals(
      calorieGoal: 2000,
      proteinGoalG: 150,
      carbsGoalG: 200,
      fatGoalG: 65,
    );

    testWidgets('shows nothing when currentTotals/goals are not supplied', (
      tester,
    ) async {
      await pumpResult(tester, onSave: (_) {});

      expect(find.textContaining('left today after adding this'), findsNothing);
    });

    testWidgets(
      'shows the neutral remaining line, and recomputes live as servings change',
      (tester) async {
        const currentTotals = DailyTotals(
          calories: 1000,
          proteinG: 0,
          carbsG: 0,
          fatG: 0,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RecognizedMealResult(
                meal: meal,
                onSave: (_) {},
                currentTotals: currentTotals,
                goals: goals,
              ),
            ),
          ),
        );

        // 2000 - 1000 - 380 (servings=1.0) = 620.
        expect(find.text('620 kcal left today after adding this'), findsOneWidget);
        expect(find.textContaining('over your daily goal'), findsNothing);

        await tester.tap(find.byIcon(Icons.add_circle_outline));
        await tester.pump();

        // servings now 1.5 -> added calories 570 -> 2000 - 1000 - 570 = 430.
        expect(find.text('430 kcal left today after adding this'), findsOneWidget);
      },
    );

    testWidgets('shows the over-goal caution line when it would exceed goal', (
      tester,
    ) async {
      const currentTotals = DailyTotals(
        calories: 1900,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecognizedMealResult(
              meal: meal,
              onSave: (_) {},
              currentTotals: currentTotals,
              goals: goals,
            ),
          ),
        ),
      );

      // 2000 - 1900 - 380 = -280.
      expect(find.text('-280 kcal left today after adding this'), findsOneWidget);
      expect(
        find.text('This puts you 280 kcal over your daily goal.'),
        findsOneWidget,
      );
    });
  });
}
