import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/main.dart';

void main() {
  testWidgets('NourishApp boots to the Home tab with bottom nav visible', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NourishApp());
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Nourish'), findsWidgets);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Recipes'), findsOneWidget);
    expect(find.text('Extras'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
