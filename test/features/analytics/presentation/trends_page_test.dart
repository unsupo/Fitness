import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/analytics/presentation/pages/trends_page.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
    'defaults to the Trends tab, showing all three section headings',
    (tester) async {
      final fake = FakeAnalyticsRepository();
      await pumpTrendsPage(tester, fake);

      expect(find.text('Weekly Calories'), findsOneWidget);
      expect(find.text('Macro Breakdown'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      // Appears in "Current Weight: ..." and again in the editable
      // weigh-in history list below the chart.
      expect(find.textContaining('80.1'), findsNWidgets(2));
    },
  );

  testWidgets('Weekly tab shows only the calories chart', (tester) async {
    final fake = FakeAnalyticsRepository();
    await pumpTrendsPage(tester, fake);

    await tester.tap(find.text('Weekly'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Calories'), findsOneWidget);
    expect(find.text('Macro Breakdown'), findsNothing);
    expect(find.text('Weight'), findsNothing);
  });

  testWidgets('Progress tab shows macro breakdown and weight, not calories', (
    tester,
  ) async {
    final fake = FakeAnalyticsRepository();
    await pumpTrendsPage(tester, fake);

    await tester.tap(find.text('Progress'));
    await tester.pumpAndSettle();

    expect(find.text('Weekly Calories'), findsNothing);
    expect(find.text('Macro Breakdown'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
  });

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
      final series = weightChart.data.lineBarsData.single;
      final tooltipItems = weightChart.data.lineTouchData.touchTooltipData
          .getTooltipItems([LineBarSpot(series, 0, series.spots.single)]);

      expect(tooltipItems.single, isNotNull);
      expect(tooltipItems.single!.text, contains('Jul 19'));
      expect(tooltipItems.single!.text, contains('kg'));
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
