import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/analytics/presentation/widgets/weight_goal_section.dart';

import '../fakes/fake_analytics_repository.dart';

/// Series are identified by color rather than list position — position is
/// an implementation/paint-order detail (whichever series is painted last
/// is on top), not something callers should have to know.
LineChartBarData _seriesWithColor(LineChartData data, Color color) =>
    data.lineBarsData.firstWhere((s) => s.color == color);

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
      final projectedSeries = _seriesWithColor(chart.data, AppColors.brandGreen);
      // Starting point of the projected series should be the weekly
      // average (85), not the last raw entry (86).
      expect(projectedSeries.spots.first.y, closeTo(85, 0.01));
    },
  );

  testWidgets(
    'the projected series starts exactly where the actual series ends, '
    'with no visual gap between them',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 1), weightKg: 90, goalType: 'lose'),
          // A second weekly bucket a week later — its weekStart lands
          // several days before "now" (whenever the test runs), which is
          // exactly the gap the bug produced: the projected series used to
          // start at DateTime.now() instead of at this last actual point.
          WeightEntry(id: 2, loggedAt: DateTime(2026, 7, 8), weightKg: 85, goalType: 'lose'),
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
      final actualSeries = _seriesWithColor(chart.data, AppColors.accentOrange);
      final projectedSeries = _seriesWithColor(chart.data, AppColors.brandGreen);

      expect(projectedSeries.spots.first.x, actualSeries.spots.last.x);
      expect(
        projectedSeries.spots.first.y,
        closeTo(actualSeries.spots.last.y, 0.01),
      );
    },
  );

  testWidgets(
    'shows a date + weight + series-name tooltip when a point is touched, '
    'not just a bare number',
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
      final actualSeries = _seriesWithColor(chart.data, AppColors.accentOrange);
      final tooltipItems = chart.data.lineTouchData.touchTooltipData
          .getTooltipItems([
            LineBarSpot(actualSeries, 0, actualSeries.spots.first),
          ]);

      expect(tooltipItems.single, isNotNull);
      expect(tooltipItems.single!.text, contains('Actual'));
      expect(tooltipItems.single!.text, contains('85'));
    },
  );

  testWidgets(
    'the tooltip is configured to stay within the chart bounds, so it '
    'doesn\'t clip off-screen for a point near the edge',
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
      expect(chart.data.lineTouchData.touchTooltipData.fitInsideHorizontally, isTrue);
      expect(chart.data.lineTouchData.touchTooltipData.fitInsideVertically, isTrue);
    },
  );

  testWidgets(
    'the actual series is painted on top of the projected series and with '
    'a larger dot, so it stays visible where the two meet at the same point',
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
      // fl_chart paints lineBarsData in list order — later entries paint on
      // top. The shared boundary point must show the actual (orange) dot,
      // not have it hidden underneath the projected (green) one.
      expect(chart.data.lineBarsData.last.color, AppColors.accentOrange);

      final actualSeries = _seriesWithColor(chart.data, AppColors.accentOrange);
      final projectedSeries = _seriesWithColor(chart.data, AppColors.brandGreen);
      final actualRadius = (actualSeries.dotData
              .getDotPainter(actualSeries.spots.first, 0, actualSeries, 0)
          as FlDotCirclePainter)
          .radius;
      final projectedRadius = (projectedSeries.dotData
              .getDotPainter(projectedSeries.spots.first, 0, projectedSeries, 0)
          as FlDotCirclePainter)
          .radius;
      expect(actualRadius, greaterThan(projectedRadius));
    },
  );

  testWidgets(
    'touching a point keeps its tooltip showing until tapping elsewhere, '
    'not just while the touch is held',
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

      // Tap the chart, then release — a real device tap is a quick
      // down-then-up, exactly what `tester.tap` simulates.
      await tester.tap(find.byType(LineChart));
      await tester.pump();

      var chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.showingTooltipIndicators, isNotEmpty);

      // Tapping elsewhere on the page (outside the chart) dismisses it.
      await tester.tap(find.text('Actual (weekly avg)'));
      await tester.pump();

      chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.showingTooltipIndicators, isEmpty);
    },
  );
}
