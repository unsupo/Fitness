import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/edit_diary_entry_dialog.dart';

import '../fakes/fake_diary_repository.dart';

void main() {
  DiaryEntry entry() => DiaryEntry(
    id: 7,
    loggedAt: DateTime(2026, 7, 21, 8, 36),
    mealType: MealType.breakfast,
    foodName: 'BBQ Pringles',
    quantity: const LoggedQuantity(amount: 0.5, unit: 'serving'),
    calories: 75,
    proteinG: 0.5,
    carbsG: 7.5,
    fatG: 4.5,
    foodId: 3,
  );

  Future<FakeDiaryRepository> pumpDialog(WidgetTester tester) async {
    final fake = FakeDiaryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showEditDiaryEntryDialog(context, ref, entry()),
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

  testWidgets(
    'changing quantity rescales calories/macros proportionally on save',
    (tester) async {
      final fake = await pumpDialog(tester);

      await tester.enterText(find.byKey(const Key('edit-quantity-field')), '1');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fake.lastUpdatedEntry, isNotNull);
      expect(fake.lastUpdatedEntry!.id, 7);
      expect(fake.lastUpdatedEntry!.quantity.amount, 1.0);
      expect(fake.lastUpdatedEntry!.quantity.unit, 'serving');
      expect(fake.lastUpdatedEntry!.calories, 150);
      expect(fake.lastUpdatedEntry!.proteinG, 1.0);
    },
  );

  testWidgets('changing the meal type saves the new meal type', (
    tester,
  ) async {
    final fake = await pumpDialog(tester);

    await tester.tap(find.byKey(const Key('edit-meal-type-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dinner').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.lastUpdatedEntry!.mealType, MealType.dinner);
    // Quantity/macros unchanged when only meal type is edited.
    expect(fake.lastUpdatedEntry!.quantity.amount, 0.5);
    expect(fake.lastUpdatedEntry!.quantity.unit, 'serving');
    expect(fake.lastUpdatedEntry!.calories, 75);
  });

  testWidgets('Delete entry button deletes and closes the dialog', (
    tester,
  ) async {
    final fake = await pumpDialog(tester);

    await tester.tap(find.text('Delete entry'));
    await tester.pumpAndSettle();

    expect(fake.lastDeletedId, 7);
    expect(find.byType(AlertDialog), findsNothing);
  });
}
