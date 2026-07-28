import 'package:arndt_fitness/core/widgets/macro_ring.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/pages/diary_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_diary_repository.dart';

void main() {
  group('DiaryPage', () {
    // The dashboard is taller than the default 800x600 test surface, so
    // widgets below the fold would otherwise be treated as "offstage" by
    // default finders. Use a tall surface so the whole page is on-screen.
    testWidgets('shows meal sections, totals, and macro rings', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fake = FakeDiaryRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: DiaryPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Meal section headers for meal types that have entries.
      expect(find.text('Breakfast'), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);

      // A food name from the fixtures.
      expect(find.text('Oatmeal'), findsOneWidget);
      expect(find.text('Chicken Salad'), findsOneWidget);

      // Computed daily total: 300 + 450 + 95 = 845, goal 2000.
      expect(find.text('845 / 2000 cal'), findsOneWidget);

      // Three macro rings (protein/carbs/fat).
      expect(find.byType(MacroRing), findsNWidgets(3));

      // Date selector is always shown — there's no filtered variant anymore
      // (the old "Breakfast tab" was a separate DiaryPage(mealTypeFilter:)
      // mode; the Breakfast nav tab was replaced with Recipes since it was
      // redundant with Home already showing every meal).
      expect(find.textContaining('Date:'), findsOneWidget);
    });

    testWidgets('shows a friendly empty state when no meals are logged', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final fake = FakeDiaryRepository(entries: const []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: DiaryPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No meals logged yet'), findsOneWidget);
      expect(find.text('Breakfast'), findsNothing);
    });
  });
}
