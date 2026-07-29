import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/presentation/widgets/fullscreen_chart_page.dart';

void main() {
  testWidgets('shows the title and chart, and closes on tapping the close icon', (
    tester,
  ) async {
    final navigatorKey = GlobalKey<NavigatorState>();

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FullScreenChartPage(
                      title: 'Weight',
                      chart: Text('chart content'),
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('chart content'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('chart content'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
