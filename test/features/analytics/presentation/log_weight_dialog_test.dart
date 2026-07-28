import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/analytics/presentation/widgets/log_weight_dialog.dart';

import '../fakes/fake_analytics_repository.dart';

void main() {
  final existingEntry = WeightEntry(
    id: 5,
    loggedAt: DateTime(2026, 7, 20),
    weightKg: 82,
    goalType: 'lose',
  );

  Future<FakeAnalyticsRepository> pumpDialog(
    WidgetTester tester, {
    WeightEntry? entryToEdit,
  }) async {
    final fake = FakeAnalyticsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () =>
                  showLogWeightDialog(context, ref, entryToEdit: entryToEdit),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('create mode (no entry) shows "Log weight" title, no delete button', (
    tester,
  ) async {
    await pumpDialog(tester);

    expect(find.text('Log weight'), findsOneWidget);
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('edit mode pre-fills the weight and shows a Delete button', (
    tester,
  ) async {
    await pumpDialog(tester, entryToEdit: existingEntry);

    expect(find.text('Edit weigh-in'), findsOneWidget);
    expect(find.text('82'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('saving in edit mode calls updateWeightEntry with the same id', (
    tester,
  ) async {
    final fake = await pumpDialog(tester, entryToEdit: existingEntry);

    await tester.enterText(find.byType(TextField), '83');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.lastUpdatedWeightEntry?.id, 5);
    expect(fake.lastUpdatedWeightEntry?.weightKg, 83);
  });

  testWidgets('tapping Delete in edit mode calls deleteWeightEntry', (
    tester,
  ) async {
    final fake = await pumpDialog(tester, entryToEdit: existingEntry);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(fake.lastDeletedWeightEntryId, 5);
  });
}
