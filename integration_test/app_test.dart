// Full-app integration test: runs against a real simulator/device/emulator,
// not just a synthetic widget tree, and hits the real live Supabase backend.
// This is the deep end of the closed loop.

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:arndt_fitness/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('boots to Diary with live Supabase data and navigates to Trends', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const NourishApp());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Nourish'), findsWidgets);

    await tester.tap(find.text('Extras'));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    expect(find.text('Weekly Calories'), findsOneWidget);
    expect(find.textContaining('Macro Breakdown'), findsOneWidget);
  });
}
