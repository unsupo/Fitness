import 'dart:math' as math;

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

  testWidgets(
    'pre-fills the calorie field and the macro legend from the current '
    'goals, rescaled so the pie always starts in sync with the calorie '
    'field even if the stored macros drifted from it',
    (tester) async {
      await pumpDialog(tester);

      final calorieField = tester.widget<TextField>(
        find.byKey(const Key('goals-calorie-field')),
      );
      expect(calorieField.controller!.text, '2000');

      expect(find.byKey(const Key('macro-pie-chart')), findsOneWidget);
      // startingGoals' stored macros (150/200/65g -> 1985 kcal) don't quite
      // match the stored calorie goal (2000) -- opening the dialog rescales
      // them onto the goal (scale = 2000/1985) so the pie's center number
      // and the calorie field never visibly disagree.
      expect(find.text('151g (30%)'), findsOneWidget);
      expect(find.text('202g (40%)'), findsOneWidget);
      expect(find.text('65g (29%)'), findsOneWidget);
    },
  );

  testWidgets(
    'editing only the calorie field rescales the macro split '
    'proportionally, so the pie always totals the new goal',
    (tester) async {
      final fake = await pumpDialog(tester);

      await tester.enterText(
        find.byKey(const Key('goals-calorie-field')),
        '2200',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fake.goals.calorieGoal, 2200);
      // Original split: 600/800/585 kcal (protein/carbs/fat), scaled by
      // 2200/1985 to keep the same percentages at the new total.
      const scale = 2200 / 1985;
      expect(fake.goals.proteinGoalG, closeTo(150 * scale, 0.1));
      expect(fake.goals.carbsGoalG, closeTo(200 * scale, 0.1));
      expect(fake.goals.fatGoalG, closeTo(65 * scale, 0.1));
    },
  );

  testWidgets(
    'dragging the macro pie chart and saving persists the new split',
    (tester) async {
      final fake = await pumpDialog(tester);

      // Same geometry convention as adjustable_macro_pie_chart_test.dart:
      // angle 0 = 12 o'clock, clockwise, at 80% of the chart's radius.
      const chartSize = 220.0;
      const chartCenter = Offset(chartSize / 2, chartSize / 2);
      Offset pointAt(double angle) =>
          chartCenter +
          Offset(
            chartSize / 2 * 0.8 * math.sin(angle),
            -chartSize / 2 * 0.8 * math.cos(angle),
          );

      final topLeft = tester.getTopLeft(
        find.byKey(const Key('macro-pie-chart')),
      );
      // Starting split: 600/800/585 kcal -> proteinCarbs boundary at
      // 600/1985 * 2π.
      final boundaryAngle = 600 / 1985 * 2 * math.pi;
      final startPoint = topLeft + pointAt(boundaryAngle);
      final endPoint = topLeft + pointAt(boundaryAngle + math.pi / 6);

      final gesture = await tester.startGesture(startPoint);
      await tester.pump();
      await gesture.moveTo(endPoint);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      // Calorie field itself wasn't touched; protein grew, carbs shrank,
      // fat untouched (aside from the on-open rescale onto the 2000
      // calorie goal, same as the pre-fill test).
      expect(fake.goals.calorieGoal, closeTo(2000, 0.01));
      expect(fake.goals.proteinGoalG, greaterThan(150));
      expect(fake.goals.carbsGoalG, lessThan(200));
      expect(fake.goals.fatGoalG, closeTo(65 * (2000 / 1985), 0.1));
    },
  );

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
