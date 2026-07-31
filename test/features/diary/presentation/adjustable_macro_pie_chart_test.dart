import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/presentation/widgets/adjustable_macro_pie_chart.dart';

void main() {
  const chartSize = 220.0;
  const center = Offset(chartSize / 2, chartSize / 2);
  const radius = chartSize / 2;

  /// The on-screen point at [angle] radians clockwise from 12 o'clock, at
  /// the chart's outer radius — matches the widget's own touch-angle
  /// convention, so tests can target an exact boundary precisely.
  Offset pointAt(double angle) => center +
      Offset(radius * 0.8 * sin(angle), -radius * 0.8 * cos(angle));

  testWidgets('renders the calorie total in the center', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AdjustableMacroPieChart(
            proteinG: 150,
            carbsG: 200,
            fatG: 65,
            onChanged: ({
              required proteinG,
              required carbsG,
              required fatG,
            }) {},
          ),
        ),
      ),
    );

    // 150*4 + 200*4 + 65*9 = 1985.
    expect(find.text('1985'), findsOneWidget);
    expect(find.text('cal'), findsOneWidget);
  });

  testWidgets(
    'dragging clockwise from the protein/carbs boundary grows protein '
    'and shrinks carbs by the same amount, leaving fat untouched',
    (tester) async {
      double? resultProtein, resultCarbs, resultFat;

      // Equal thirds: 400 kcal each -> protein 100g, carbs 100g,
      // fat 400/9 g. Boundary is exactly at 1/3 * 2π (120°).
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustableMacroPieChart(
              proteinG: 100,
              carbsG: 100,
              fatG: 400 / 9,
              onChanged: ({
                required proteinG,
                required carbsG,
                required fatG,
              }) {
                resultProtein = proteinG;
                resultCarbs = carbsG;
                resultFat = fatG;
              },
            ),
          ),
        ),
      );

      final topLeft = tester.getTopLeft(find.byType(AdjustableMacroPieChart));
      final boundaryAngle = 2 * pi / 3; // 120°, proteinCarbs boundary
      final startPoint = topLeft + pointAt(boundaryAngle);
      // Drag 30° further clockwise (into carbs' territory) — grows protein.
      final endPoint = topLeft + pointAt(boundaryAngle + pi / 6);

      final gesture = await tester.startGesture(startPoint);
      await tester.pump();
      await gesture.moveTo(endPoint);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(resultProtein, isNotNull);
      // 30° of a 400kcal-per-slice pie == (30/360)*1200kcal total == 100kcal
      // moved, i.e. 25g at 4 kcal/g.
      expect(resultProtein, closeTo(125, 0.5));
      expect(resultCarbs, closeTo(75, 0.5));
      expect(resultFat, closeTo(400 / 9, 0.01));
    },
  );

  testWidgets(
    'dragging counter-clockwise across the fat/protein wraparound '
    'boundary shrinks fat and grows protein',
    (tester) async {
      double? resultProtein, resultFat;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustableMacroPieChart(
              proteinG: 100,
              carbsG: 100,
              fatG: 400 / 9,
              onChanged: ({
                required proteinG,
                required carbsG,
                required fatG,
              }) {
                resultProtein = proteinG;
                resultFat = fatG;
              },
            ),
          ),
        ),
      );

      final topLeft = tester.getTopLeft(find.byType(AdjustableMacroPieChart));
      // fatProtein boundary sits at angle 0 (12 o'clock).
      final startPoint = topLeft + pointAt(0.001);
      // Drag counter-clockwise (negative angle, wrapping below 0) — shrinks
      // fat, grows protein.
      final endPoint = topLeft + pointAt(-pi / 6);

      final gesture = await tester.startGesture(startPoint);
      await tester.pump();
      await gesture.moveTo(endPoint);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(resultFat, lessThan(400 / 9));
      expect(resultProtein, greaterThan(100));
    },
  );

  testWidgets(
    'clamps at the minimum floor, not zero — a slice already below the '
    'floor can\'t be shrunk further, so it always stays grabbable',
    (tester) async {
      double? resultProtein, resultCarbs;

      // Protein has only 40 kcal (10g) of 1690 total (2.4%) — already
      // below the 5% floor (84.5 kcal), same as stale/imported data might
      // be.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustableMacroPieChart(
              proteinG: 10,
              carbsG: 300,
              fatG: 50,
              onChanged: ({
                required proteinG,
                required carbsG,
                required fatG,
              }) {
                resultProtein = proteinG;
                resultCarbs = carbsG;
              },
            ),
          ),
        ),
      );

      final topLeft = tester.getTopLeft(find.byType(AdjustableMacroPieChart));
      // fatProtein boundary (angle 0) — drag deep clockwise, past protein's
      // entire small slice, trying to shrink it further.
      final startPoint = topLeft + pointAt(0.001);
      final endPoint = topLeft + pointAt(pi); // 180°, way past protein's slice

      final gesture = await tester.startGesture(startPoint);
      await tester.pump();
      await gesture.moveTo(endPoint);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Already below the floor, so the shrink is blocked entirely —
      // protein stays exactly where it started.
      expect(resultProtein, closeTo(10, 0.01));
      expect(resultCarbs, closeTo(300, 0.01));
    },
  );
}
