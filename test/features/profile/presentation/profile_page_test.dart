import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/profile/presentation/pages/profile_page.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import '../../analytics/fakes/fake_analytics_repository.dart';
import '../../diary/fakes/fake_diary_repository.dart';

void main() {
  const goals = DailyGoals(
    calorieGoal: 2000,
    proteinGoalG: 150,
    carbsGoalG: 200,
    fatGoalG: 65,
  );

  Future<void> pumpProfilePage(
    WidgetTester tester, {
    required FakeDiaryRepository diaryFake,
    required FakeAnalyticsRepository analyticsFake,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diaryRepositoryProvider.overrideWithValue(diaryFake),
          analyticsRepositoryProvider.overrideWithValue(analyticsFake),
        ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the daily calorie/macro goals', (tester) async {
    await pumpProfilePage(
      tester,
      diaryFake: FakeDiaryRepository(goals: goals),
      analyticsFake: FakeAnalyticsRepository(),
    );

    expect(find.text('Daily Goals'), findsOneWidget);
    expect(find.text('2000 cal'), findsOneWidget);
    expect(find.text('150 g'), findsOneWidget);
    expect(find.text('200 g'), findsOneWidget);
    expect(find.text('65 g'), findsOneWidget);
  });

  testWidgets(
    'prompts to set up the biometric profile when incomplete',
    (tester) async {
      await pumpProfilePage(
        tester,
        diaryFake: FakeDiaryRepository(goals: goals),
        analyticsFake: FakeAnalyticsRepository(),
      );

      expect(find.text('Set up profile'), findsOneWidget);
    },
  );

  testWidgets('shows biometric profile details when complete', (
    tester,
  ) async {
    await pumpProfilePage(
      tester,
      diaryFake: FakeDiaryRepository(goals: goals),
      analyticsFake: FakeAnalyticsRepository(
        userProfile: const UserProfile(
          sex: 'male',
          age: 30,
          heightCm: 180,
          activityLevel: 'sedentary',
          targetWeightKg: 80,
          unitSystem: 'metric',
        ),
      ),
    );

    expect(find.textContaining('30'), findsWidgets); // age
    expect(find.textContaining('180'), findsWidgets); // height
    expect(find.text('Set up profile'), findsNothing);
  });

  testWidgets('tapping the daily goals edit icon opens the edit dialog', (
    tester,
  ) async {
    await pumpProfilePage(
      tester,
      diaryFake: FakeDiaryRepository(goals: goals),
      analyticsFake: FakeAnalyticsRepository(),
    );

    await tester.tap(find.byKey(const Key('edit-daily-goals-button')));
    await tester.pumpAndSettle();

    expect(find.text('Daily goals'), findsOneWidget);
    expect(find.byKey(const Key('goals-calorie-field')), findsOneWidget);
  });

  testWidgets('tapping the profile edit icon opens the weight-goal dialog', (
    tester,
  ) async {
    await pumpProfilePage(
      tester,
      diaryFake: FakeDiaryRepository(goals: goals),
      analyticsFake: FakeAnalyticsRepository(
        userProfile: const UserProfile(
          sex: 'male',
          age: 30,
          heightCm: 180,
          activityLevel: 'sedentary',
          targetWeightKg: 80,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('edit-profile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Weight goal'), findsOneWidget);
    expect(find.byKey(const Key('goal-target-weight-field')), findsOneWidget);
  });

  testWidgets('shows weekly rate slider and bidirectionally calculates calorie goal', (tester) async {
    final analyticsFake = FakeAnalyticsRepository(
      userProfile: const UserProfile(
        sex: 'male',
        age: 30,
        heightCm: 180,
        activityLevel: 'sedentary',
        targetWeightKg: 80,
        unitSystem: 'metric',
      ),
      weightHistory: [
        WeightEntry(
          id: 1,
          loggedAt: DateTime(2026, 7, 29),
          weightKg: 80.0,
          goalType: 'lose',
        ),
      ],
    );

    await pumpProfilePage(
      tester,
      diaryFake: FakeDiaryRepository(goals: goals),
      analyticsFake: analyticsFake,
    );

    // Open Daily Goals dialog
    await tester.tap(find.byKey(const Key('edit-daily-goals-button')));
    await tester.pumpAndSettle();

    // Verify TDEE estimated and weekly rate slider displayed
    // TDEE = (10 * 80 + 6.25 * 180 - 5 * 30 + 5) * 1.2 = (800 + 1125 - 150 + 5) * 1.2 = 1780 * 1.2 = 2136
    expect(find.text('Estimated TDEE: 2136 kcal'), findsOneWidget);
    expect(find.byKey(const Key('weekly-rate-slider')), findsOneWidget);

    // Initial calories is 2000. 
    // Rate: (2000 - 2136) * 7 / 7700 = -136 * 7 / 7700 = -0.123 kg/week. Rounded to nearest 0.25 -> -0.00
    // Check if slider is found and we can interact with it
    final sliderFinder = find.byKey(const Key('weekly-rate-slider'));
    expect(sliderFinder, findsOneWidget);

    // Let's enter a new calorie goal in the text field and see slider update
    // Calorie goal = 1036 (deficit of 1100 kcal -> -1.0 kg/week)
    await tester.enterText(find.byKey(const Key('goals-calorie-field')), '1036');
    await tester.pumpAndSettle();
    
    // Slider value should be updated to -1.0. Let's verify text says "Lose 1.00 kg/week"
    expect(find.text('Lose 1.00 kg/week'), findsOneWidget);

    // Let's drag the slider to 0.0 (Maintain weight)
    // A Slider widget can be updated by tapping or dragging. Let's tap the center of the slider.
    await tester.tap(sliderFinder);
    await tester.pumpAndSettle();

    // Verify calorie goal text updated to TDEE (approx 2136)
    final calorieFieldVal = (tester.widget(find.byKey(const Key('goals-calorie-field'))) as TextField).controller?.text;
    expect(double.parse(calorieFieldVal!), closeTo(2136, 100)); // allow some tolerance depending on slider tap accuracy
  });
}
