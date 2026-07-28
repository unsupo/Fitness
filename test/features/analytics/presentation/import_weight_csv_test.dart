import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/analytics/presentation/widgets/import_weight_csv.dart';

import '../fakes/fake_analytics_repository.dart';

void main() {
  const csv =
      'Time,Weight,BMI\n'
      '7/12/2026 9:47 PM,248.2lb,30.2\n'
      '7/19/2026 9:40 PM,250.9lb,30.6\n';

  Future<FakeAnalyticsRepository> pumpAndImport(
    WidgetTester tester, {
    List<WeightEntry>? weightHistory,
  }) async {
    final fake = FakeAnalyticsRepository(weightHistory: weightHistory);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => importWeightCsvContent(context, ref, csv),
                child: const Text('import'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('import'));
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('shows a confirmation dialog with the reading count and date range', (
    tester,
  ) async {
    await pumpAndImport(tester);

    expect(find.text('Import weigh-ins?'), findsOneWidget);
    expect(find.textContaining('2 readings'), findsOneWidget);
    expect(find.textContaining('Jul 12, 2026'), findsOneWidget);
    expect(find.textContaining('Jul 19, 2026'), findsOneWidget);
  });

  testWidgets('does not import when cancelled', (tester) async {
    final fake = await pumpAndImport(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fake.lastImportedEntries, isNull);
  });

  testWidgets('imports all parsed entries using the latest existing goalType', (
    tester,
  ) async {
    final fake = await pumpAndImport(
      tester,
      weightHistory: [
        WeightEntry(
          id: 1,
          loggedAt: DateTime(2026, 7, 1),
          weightKg: 100,
          goalType: 'gain',
        ),
      ],
    );

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(fake.lastImportedEntries, isNotNull);
    expect(fake.lastImportedEntries!.length, 2);
    expect(fake.lastImportedGoalType, 'gain');
  });

  testWidgets('defaults to maintain when there is no existing history', (
    tester,
  ) async {
    final fake = await pumpAndImport(tester, weightHistory: const []);

    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(fake.lastImportedGoalType, 'maintain');
  });

  testWidgets(
    'skips readings already present in history and says so in the dialog',
    (tester) async {
      final fake = await pumpAndImport(
        tester,
        weightHistory: [
          WeightEntry(
            id: 1,
            loggedAt: DateTime(2026, 7, 12, 21, 47),
            weightKg: 112.6,
            goalType: 'lose',
          ),
        ],
      );

      expect(find.textContaining('1 new readings'), findsOneWidget);
      expect(find.textContaining('1 already imported'), findsOneWidget);

      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();

      expect(fake.lastImportedEntries!.length, 1);
      expect(fake.lastImportedEntries!.single.loggedAt, DateTime(2026, 7, 19, 21, 40));
    },
  );

  testWidgets(
    'shows a message and does not open a dialog when every reading is already imported',
    (tester) async {
      final fake = await pumpAndImport(
        tester,
        weightHistory: [
          WeightEntry(
            id: 1,
            loggedAt: DateTime(2026, 7, 12, 21, 47),
            weightKg: 112.6,
            goalType: 'lose',
          ),
          WeightEntry(
            id: 2,
            loggedAt: DateTime(2026, 7, 19, 21, 40),
            weightKg: 113.8,
            goalType: 'lose',
          ),
        ],
      );

      expect(find.text('Import weigh-ins?'), findsNothing);
      expect(find.textContaining('already imported'), findsOneWidget);
      expect(fake.lastImportedEntries, isNull);
    },
  );

  testWidgets('shows a message and does not open a dialog for an empty file', (
    tester,
  ) async {
    final fake = FakeAnalyticsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => ElevatedButton(
                onPressed: () => importWeightCsvContent(context, ref, 'Time,Weight\n'),
                child: const Text('import'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('import'));
    await tester.pumpAndSettle();

    expect(find.text('Import weigh-ins?'), findsNothing);
    expect(find.textContaining('No readings found'), findsOneWidget);
    expect(fake.lastImportedEntries, isNull);
  });
}
