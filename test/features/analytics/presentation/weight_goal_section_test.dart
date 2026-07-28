import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/analytics/presentation/widgets/weight_goal_section.dart';

import '../fakes/fake_analytics_repository.dart';

void main() {
  Future<void> pump(WidgetTester tester, FakeAnalyticsRepository fake) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: Scaffold(body: WeightGoalSection())),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('prompts to set up a goal when the profile is incomplete', (
    tester,
  ) async {
    final fake = FakeAnalyticsRepository(
      weightHistory: [
        WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 20), weightKg: 85, goalType: 'lose'),
      ],
    );
    await pump(tester, fake);

    expect(find.text('Set up weight goal'), findsOneWidget);
  });

  testWidgets(
    'shows a projected target date once the profile and weight history are complete',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 20), weightKg: 85, goalType: 'lose'),
        ],
        calorieGoal: 2000,
        userProfile: const UserProfile(
          sex: 'male',
          age: 30,
          heightCm: 180,
          activityLevel: 'sedentary',
          targetWeightKg: 80,
        ),
      );
      await pump(tester, fake);

      expect(find.textContaining('80'), findsWidgets);
      expect(find.byType(Icon), findsWidgets);
    },
  );

  testWidgets('prompts to log weight first when there is no weight history', (
    tester,
  ) async {
    final fake = FakeAnalyticsRepository(weightHistory: const []);
    await pump(tester, fake);

    expect(find.textContaining('Log your weight'), findsOneWidget);
    expect(find.text('Set up weight goal'), findsNothing);
  });

  testWidgets(
    'renders both an actual weekly-average series and a projected series, '
    'with a legend distinguishing them',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 20), weightKg: 85, goalType: 'lose'),
        ],
        calorieGoal: 2000,
        userProfile: const UserProfile(
          sex: 'male',
          age: 30,
          heightCm: 180,
          activityLevel: 'sedentary',
          targetWeightKg: 80,
        ),
      );
      await pump(tester, fake);

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.length, 2);
      expect(find.text('Actual (weekly avg)'), findsOneWidget);
      expect(find.text('Projected'), findsOneWidget);
    },
  );

  testWidgets(
    'uses the latest weekly average (not just the single last entry) as '
    'the projection start',
    (tester) async {
      // Two entries in the same week averaging to 85 — if the projection
      // used only the last raw entry (86), the target date would differ.
      final fakeAveraged = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 20), weightKg: 84, goalType: 'lose'),
          WeightEntry(id: 2, loggedAt: DateTime(2026, 7, 21), weightKg: 86, goalType: 'lose'),
        ],
        calorieGoal: 2000,
        userProfile: const UserProfile(
          sex: 'male',
          age: 30,
          heightCm: 180,
          activityLevel: 'sedentary',
          targetWeightKg: 80,
        ),
      );
      await pump(tester, fakeAveraged);

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      final projectedSeries = chart.data.lineBarsData.last;
      // Starting point of the projected series should be the weekly
      // average (85), not the last raw entry (86).
      expect(projectedSeries.spots.first.y, closeTo(85, 0.01));
    },
  );
}
