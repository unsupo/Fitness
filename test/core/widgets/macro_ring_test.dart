import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/widgets/macro_ring.dart';

void main() {
  testWidgets('shows both the percent inside the ring and grams as a caption', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MacroRing(
            label: 'Protein',
            progress: 0.5,
            color: Colors.blue,
            actualGrams: 60,
            targetGrams: 120,
          ),
        ),
      ),
    );

    expect(find.text('50%'), findsOneWidget);
    expect(find.text('60g / 120g'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
  });

  testWidgets('omits the grams caption when actual/target grams are not given', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MacroRing(label: 'Protein', progress: 0.5, color: Colors.blue),
        ),
      ),
    );

    expect(find.textContaining('g /'), findsNothing);
  });
}
