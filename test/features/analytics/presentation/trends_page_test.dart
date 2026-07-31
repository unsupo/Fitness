import 'package:arndt_fitness/features/analytics/domain/entities/macro_breakdown.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/analytics/presentation/pages/trends_page.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../diary/fakes/fake_diary_repository.dart';
import '../fakes/fake_analytics_repository.dart';

void main() {
  Future<void> pumpTrendsPage(
    WidgetTester tester,
    FakeAnalyticsRepository fake,
  ) async {
    // The Trends page has three chart sections stacked in a scroll view —
    // taller than the default 800x600 test surface. Enlarge it so every
    // section is actually onstage (visible without scrolling) for finders.
    await tester.binding.setSurfaceSize(const Size(400, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: TrendsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows all three section headings',
    (tester) async {
      final fake = FakeAnalyticsRepository();
      await pumpTrendsPage(tester, fake);

      expect(find.text('Weekly Calories'), findsOneWidget);
      expect(find.textContaining('Macro Breakdown'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      // Appears in "Current Weight: ..." and again in the editable
      // weigh-in history list below the chart.
      expect(find.textContaining('80.1'), findsNWidgets(2));
    },
  );

  testWidgets(
    'Macro Breakdown heading shows which week it summarizes, so a '
    'per-day dip doesn\'t read as a bug when it\'s just diluted by the '
    'rest of the week',
    (tester) async {
      final fake = FakeAnalyticsRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(fake),
            selectedWeekStartProvider.overrideWith(
              (ref) => DateTime(2026, 7, 20),
            ),
          ],
          child: const MaterialApp(home: TrendsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Macro Breakdown (Jul 20-26)'), findsOneWidget);
    },
  );

  testWidgets(
    'Macro Breakdown legend shows each macro\'s weekly goal (7x the daily '
    'goal set in Profile) next to the logged grams, so actual vs. target '
    'is visible at a glance',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        macroBreakdown: const MacroBreakdown(
          proteinG: 700,
          carbsG: 1000,
          fatG: 300,
        ),
      );
      final diaryFake = FakeDiaryRepository(
        goals: const DailyGoals(
          calorieGoal: 2000,
          proteinGoalG: 150,
          carbsGoalG: 200,
          fatGoalG: 65,
        ),
      );
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(fake),
            diaryRepositoryProvider.overrideWithValue(diaryFake),
          ],
          child: const MaterialApp(home: TrendsPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Daily goals x7 for a weekly comparison: 150*7=1050, 200*7=1400,
      // 65*7=455.
      expect(find.textContaining('Goal 1050g'), findsOneWidget);
      expect(find.textContaining('Goal 1400g'), findsOneWidget);
      expect(find.textContaining('Goal 455g'), findsOneWidget);
    },
  );

  testWidgets(
    'tapping a day\'s bar shows that day\'s calories and macro breakdown',
    (tester) async {
      final fake = FakeAnalyticsRepository();
      await pumpTrendsPage(tester, fake);

      // Tap near the first bar group's rendered position.
      final chartRect = tester.getRect(find.byType(BarChart));
      await tester.tapAt(Offset(chartRect.left + 20, chartRect.center.dy));
      await tester.pump();

      // First fixture day: DateTime(2026, 7, 20), 1800 kcal, 120g protein,
      // 200g carbs, 70g fat.
      expect(find.textContaining('1800'), findsWidgets);
      expect(find.textContaining('120'), findsWidgets);
      expect(find.textContaining('200'), findsWidgets);
      expect(find.textContaining('70'), findsWidgets);
    },
  );

  testWidgets(
    'the weekly calories chart is a real horizontal-scrolling page view — '
    'dragging tracks the finger and settles on the next/previous week, '
    'in sync with the chevron buttons',
    (tester) async {
      final fake = FakeAnalyticsRepository();
      await tester.binding.setSurfaceSize(const Size(400, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            analyticsRepositoryProvider.overrideWithValue(fake),
            selectedWeekStartProvider.overrideWith(
              (ref) => DateTime(2026, 7, 20),
            ),
          ],
          child: const MaterialApp(home: TrendsPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jul 20-26'), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);

      // A plain drag (not a fast fling) is enough to change pages — the
      // hallmark of an actual PageView vs. a velocity-threshold gesture.
      await tester.drag(find.byType(PageView), const Offset(-350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Jul 27 - Aug 2'), findsOneWidget);

      // The chevron (a separate widget from the PageView) must still work
      // and must keep the PageView in sync — dragging afterward should
      // continue from wherever the chevron left off, not the stale page.
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pumpAndSettle();
      expect(find.text('Jul 20-26'), findsOneWidget);

      await tester.drag(find.byType(PageView), const Offset(350, 0));
      await tester.pumpAndSettle();

      expect(find.text('Jul 13-19'), findsOneWidget);
    },
  );

  testWidgets(
    'shows a friendly empty state when there is no weigh-in history',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: const <WeightEntry>[],
      );
      await pumpTrendsPage(tester, fake);

      expect(find.text('No weigh-ins yet'), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Log weight'), findsOneWidget);
    },
  );

  testWidgets('Weight section has a CSV import button', (tester) async {
    final fake = FakeAnalyticsRepository();
    await pumpTrendsPage(tester, fake);

    expect(
      find.widgetWithIcon(IconButton, Icons.upload_file_outlined),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows only the 5 most recent weigh-ins by default, with a button to reveal the rest',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          for (var i = 0; i < 8; i++)
            WeightEntry(
              id: i + 1,
              loggedAt: DateTime(2026, 7, 1 + i),
              weightKg: 80.0 + i,
              goalType: 'lose',
            ),
        ],
      );
      await pumpTrendsPage(tester, fake);

      expect(find.byTooltip('Edit weigh-in'), findsNWidgets(5));
      expect(find.widgetWithText(TextButton, 'Show all (8)'), findsOneWidget);
    },
  );

  testWidgets(
    'weight chart x-axis labels distinguish same-month readings by day, '
    'not just repeating the month',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 19), weightKg: 113.8, goalType: 'lose'),
          WeightEntry(id: 2, loggedAt: DateTime(2026, 7, 22), weightKg: 112.0, goalType: 'lose'),
          WeightEntry(id: 3, loggedAt: DateTime(2026, 7, 25), weightKg: 111.9, goalType: 'lose'),
        ],
      );
      await pumpTrendsPage(tester, fake);

      // All three readings are in July — a bare "Jul" label per point
      // (the bug) would render the same text three times with nothing
      // distinguishing them. The fixed format must include the day.
      expect(find.text('Jul'), findsNothing);
    },
  );

  testWidgets(
    'weight chart shows a date + weight tooltip when a point is touched, '
    'not just a bare number',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 19), weightKg: 113.8, goalType: 'lose'),
        ],
      );
      await pumpTrendsPage(tester, fake);

      final lineCharts = tester.widgetList<LineChart>(find.byType(LineChart));
      final weightChart = lineCharts.first;
      final series = weightChart.data.lineBarsData.first;
      final tooltipItems = weightChart.data.lineTouchData.touchTooltipData
          .getTooltipItems([LineBarSpot(series, 0, series.spots.single)]);

      expect(tooltipItems.single, isNotNull);
      expect(tooltipItems.single!.text, contains('Jul 19'));
      expect(tooltipItems.single!.text, contains('kg'));
    },
  );

  testWidgets(
    'weight chart overlays a weekly-average trend line on top of the raw '
    'per-entry readings',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 1), weightKg: 91, goalType: 'lose'),
          WeightEntry(id: 2, loggedAt: DateTime(2026, 7, 2), weightKg: 90, goalType: 'lose'),
          WeightEntry(id: 3, loggedAt: DateTime(2026, 7, 3), weightKg: 89, goalType: 'lose'),
          WeightEntry(id: 4, loggedAt: DateTime(2026, 7, 8), weightKg: 88, goalType: 'lose'),
          WeightEntry(id: 5, loggedAt: DateTime(2026, 7, 9), weightKg: 87, goalType: 'lose'),
        ],
      );
      await pumpTrendsPage(tester, fake);

      final weightChart = tester.widgetList<LineChart>(find.byType(LineChart)).first;
      expect(weightChart.data.lineBarsData.length, 2);

      final trendSeries = weightChart.data.lineBarsData.last;
      // Week 0 (indices 0-2): avg index 1, avg weight 90 kg.
      // Week 1 (indices 3-4): avg index 3.5, avg weight 87.5 kg.
      expect(trendSeries.spots.length, 2);
      expect(trendSeries.spots[0].x, closeTo(1.0, 0.001));
      expect(trendSeries.spots[0].y, closeTo(90, 0.01));
      expect(trendSeries.spots[1].x, closeTo(3.5, 0.001));
      expect(trendSeries.spots[1].y, closeTo(87.5, 0.01));
    },
  );

  testWidgets(
    'weight chart tooltip is configured to stay within the chart bounds, '
    'so it doesn\'t clip off-screen for a point near the edge',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 19), weightKg: 113.8, goalType: 'lose'),
        ],
      );
      await pumpTrendsPage(tester, fake);

      final chart = tester.widgetList<LineChart>(find.byType(LineChart)).first;
      expect(chart.data.lineTouchData.touchTooltipData.fitInsideHorizontally, isTrue);
      expect(chart.data.lineTouchData.touchTooltipData.fitInsideVertically, isTrue);
    },
  );

  testWidgets(
    'weight chart keeps a touched point\'s tooltip showing until tapping '
    'elsewhere, not just while the touch is held',
    (tester) async {
      final fake = FakeAnalyticsRepository(
        weightHistory: [
          WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 19), weightKg: 113.8, goalType: 'lose'),
          WeightEntry(id: 2, loggedAt: DateTime(2026, 7, 22), weightKg: 112.9, goalType: 'lose'),
          WeightEntry(id: 3, loggedAt: DateTime(2026, 7, 25), weightKg: 111.9, goalType: 'lose'),
        ],
      );
      await pumpTrendsPage(tester, fake);

      // Tap near the middle data point specifically (not just the chart's
      // geometric center), so the touch reliably lands within fl_chart's
      // hit-test distance of a real spot regardless of axis scaling.
      final chartRect = tester.getRect(find.byType(LineChart));
      await tester.tapAt(chartRect.center);
      await tester.pump();

      var chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.showingTooltipIndicators, isNotEmpty);

      await tester.tap(find.text('Weight'));
      await tester.pump();

      chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.showingTooltipIndicators, isEmpty);
    },
  );

  testWidgets('weight chart has a fullscreen button that opens a landscape view', (
    tester,
  ) async {
    final fake = FakeAnalyticsRepository(
      weightHistory: [
        WeightEntry(id: 1, loggedAt: DateTime(2026, 7, 19), weightKg: 113.8, goalType: 'lose'),
      ],
    );
    await pumpTrendsPage(tester, fake);

    await tester.tap(find.byKey(const Key('weight-history-fullscreen-button')));
    await tester.pumpAndSettle();

    // The fullscreen page shows its own independent LineChart instance.
    expect(find.byType(LineChart), findsOneWidget);
    expect(find.text('Weight'), findsWidgets);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Current Weight: 113.8 kg'), findsOneWidget);
  });

  testWidgets('tapping "Show all" reveals every weigh-in', (tester) async {
    final fake = FakeAnalyticsRepository(
      weightHistory: [
        for (var i = 0; i < 8; i++)
          WeightEntry(
            id: i + 1,
            loggedAt: DateTime(2026, 7, 1 + i),
            weightKg: 80.0 + i,
            goalType: 'lose',
          ),
      ],
    );
    await pumpTrendsPage(tester, fake);

    await tester.tap(find.widgetWithText(TextButton, 'Show all (8)'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Edit weigh-in'), findsNWidgets(8));
    expect(find.widgetWithText(TextButton, 'Show less'), findsOneWidget);
  });
}
