import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/profile/presentation/pages/profile_page.dart';

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
}
