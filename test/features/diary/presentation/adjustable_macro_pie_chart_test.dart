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
    'clamps at literal zero — no minimum floor, since a diet can '
    'legitimately want 0% of a macro (e.g. keto wants 0 carbs)',
    (tester) async {
      double? resultProtein, resultCarbs;

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
      // entire small slice, to try to shrink it below zero.
      final startPoint = topLeft + pointAt(0.001);
      final endPoint = topLeft + pointAt(pi); // 180°, way past protein's slice

      final gesture = await tester.startGesture(startPoint);
      await tester.pump();
      await gesture.moveTo(endPoint);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(resultProtein, closeTo(0, 0.01));
      expect(resultCarbs, isNotNull);
    },
  );

  testWidgets(
    'a macro already at exactly zero (keto: 0 carbs) can still be grabbed '
    'and dragged back out via its always-present handle',
    (tester) async {
      double? resultCarbs;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdjustableMacroPieChart(
              proteinG: 100,
              carbsG: 0,
              fatG: 100,
              onChanged: ({
                required proteinG,
                required carbsG,
                required fatG,
              }) {
                resultCarbs = carbsG;
              },
            ),
          ),
        ),
      );

      final topLeft = tester.getTopLeft(find.byType(AdjustableMacroPieChart));
      // proteinCarbs and carbsFat boundaries coincide at the same angle
      // when carbs is 0 (400/1300 * 2π) — that shared point is exactly
      // where carbs' handle sits. Dragging counter-clockwise from there
      // encroaches into protein's territory (drawn just before this angle),
      // pulling kcal out of protein and into carbs.
      final zeroCarbsAngle = 400 / 1300 * 2 * pi;
      final startPoint = topLeft + pointAt(zeroCarbsAngle - 0.02);
      final endPoint = topLeft + pointAt(zeroCarbsAngle - 0.3);

      final gesture = await tester.startGesture(startPoint);
      await tester.pump();
      await gesture.moveTo(endPoint);
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(resultCarbs, isNotNull);
      expect(resultCarbs! > 0, isTrue);
    },
  );
}
