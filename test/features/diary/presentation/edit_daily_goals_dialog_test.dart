import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/edit_daily_goals_dialog.dart';

import '../../analytics/fakes/fake_analytics_repository.dart';
import '../fakes/fake_diary_repository.dart';

void main() {
  const startingGoals = DailyGoals(
    calorieGoal: 2000,
    proteinGoalG: 150,
    carbsGoalG: 200,
    fatGoalG: 65,
  );

  Future<FakeDiaryRepository> pumpDialog(WidgetTester tester) async {
    final fake = FakeDiaryRepository(goals: startingGoals);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () =>
                  showEditDailyGoalsDialog(context, ref, startingGoals),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('pre-fills fields from the current goals', (tester) async {
    await pumpDialog(tester);

    final calorieField = tester.widget<TextField>(
      find.byKey(const Key('goals-calorie-field')),
    );
    final proteinField = tester.widget<TextField>(
      find.byKey(const Key('goals-protein-field')),
    );
    final carbsField = tester.widget<TextField>(
      find.byKey(const Key('goals-carbs-field')),
    );
    final fatField = tester.widget<TextField>(
      find.byKey(const Key('goals-fat-field')),
    );

    expect(calorieField.controller!.text, '2000');
    expect(proteinField.controller!.text, '150');
    expect(carbsField.controller!.text, '200');
    expect(fatField.controller!.text, '65');
  });

  testWidgets('saving calls updateDailyGoals with the edited values', (
    tester,
  ) async {
    final fake = await pumpDialog(tester);

    await tester.enterText(
      find.byKey(const Key('goals-calorie-field')),
      '2200',
    );
    await tester.enterText(
      find.byKey(const Key('goals-protein-field')),
      '160',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.goals.calorieGoal, 2200);
    expect(fake.goals.proteinGoalG, 160);
    expect(fake.goals.carbsGoalG, 200);
    expect(fake.goals.fatGoalG, 65);
  });

  testWidgets('does not save when a field is invalid/empty', (tester) async {
    final fake = await pumpDialog(tester);

    await tester.enterText(find.byKey(const Key('goals-calorie-field')), '');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.goals.calorieGoal, startingGoals.calorieGoal);
  });

  testWidgets('Cancel closes without saving', (tester) async {
    final fake = await pumpDialog(tester);

    await tester.enterText(
      find.byKey(const Key('goals-calorie-field')),
      '9999',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fake.goals.calorieGoal, startingGoals.calorieGoal);
  });

  group('weekly-rate calculator', () {
    const completeProfile = UserProfile(
      sex: 'male',
      age: 30,
      heightCm: 180,
      activityLevel: 'sedentary',
    );
    final weightHistory = [
      WeightEntry(
        id: 1,
        loggedAt: DateTime(2026, 7, 20),
        weightKg: 80,
        goalType: 'lose',
      ),
    ];

    Future<FakeDiaryRepository> pumpDialogWithCompleteProfile(
      WidgetTester tester,
    ) async {
      final diaryFake = FakeDiaryRepository(goals: startingGoals);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            diaryRepositoryProvider.overrideWithValue(diaryFake),
            analyticsRepositoryProvider.overrideWithValue(
              FakeAnalyticsRepository(
                userProfile: completeProfile,
                weightHistory: weightHistory,
              ),
            ),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () =>
                    showEditDailyGoalsDialog(context, ref, startingGoals),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return diaryFake;
    }

    testWidgets(
      'shows the weekly-rate slider (not the setup prompt) once the '
      'profile and weight history are complete',
      (tester) async {
        await pumpDialogWithCompleteProfile(tester);

        expect(find.byKey(const Key('weekly-rate-slider')), findsOneWidget);
        expect(find.textContaining('Estimated TDEE'), findsOneWidget);
        expect(
          find.textContaining('Add sex, age, height'),
          findsNothing,
        );
      },
    );

    testWidgets(
      'moving the weekly-rate slider updates the calorie field',
      (tester) async {
        await pumpDialogWithCompleteProfile(tester);

        final before = tester
            .widget<TextField>(find.byKey(const Key('goals-calorie-field')))
            .controller!
            .text;

        await tester.drag(
          find.byKey(const Key('weekly-rate-slider')),
          const Offset(-80, 0),
        );
        await tester.pumpAndSettle();

        final after = tester
            .widget<TextField>(find.byKey(const Key('goals-calorie-field')))
            .controller!
            .text;

        expect(after, isNot(before));
      },
    );

    testWidgets(
      'editing the calorie field updates the weekly-rate label',
      (tester) async {
        await pumpDialogWithCompleteProfile(tester);

        // TDEE at 80kg/male/30/sedentary ≈ 1780 kcal. A big deficit should
        // read as "Lose", not stay on the initial "Maintain weight" label.
        await tester.enterText(
          find.byKey(const Key('goals-calorie-field')),
          '1200',
        );
        await tester.pump();

        expect(find.textContaining('Lose'), findsOneWidget);
      },
    );
  });
}
