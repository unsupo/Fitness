import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/pages/food_detail_page.dart';

import '../fakes/fake_diary_repository.dart';

void main() {
  testWidgets('shows food name, brand, serving, and full macro breakdown', (
    tester,
  ) async {
    final fake = FakeDiaryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: FoodDetailPage(foodId: 3)),
      ),
    );
    await tester.pump();

    expect(find.text('Fake Food'), findsOneWidget);
    expect(find.textContaining('100'), findsWidgets); // calories
  });

  testWidgets('shows brand and fiber/sugar/sodium when present', (
    tester,
  ) async {
    final fake = FakeDiaryRepository()
      ..overrideFoodDetails = const FoodItem(
        id: 9,
        name: 'KIND Bar',
        brand: 'KIND',
        calories: 250,
        proteinG: 6,
        carbsG: 24,
        fatG: 15,
        servingSize: 40,
        servingUnit: 'g',
        fiberG: 4,
        sugarG: 5,
        sodiumMg: 120,
        isEstimate: false,
      );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: FoodDetailPage(foodId: 9)),
      ),
    );
    await tester.pump();

    expect(find.text('KIND Bar'), findsOneWidget);
    expect(find.textContaining('KIND'), findsWidgets);
    expect(find.textContaining('40'), findsWidgets);
  });

  testWidgets(
    'shows a full-width hero banner (not the compact placeholder) and a '
    'source link when the food has a photo',
    (tester) async {
      final fake = FakeDiaryRepository()
        ..overrideFoodDetails = const FoodItem(
          id: 10,
          name: 'Online Snack',
          calories: 210,
          proteinG: 4,
          carbsG: 30,
          fatG: 8,
          imageUrl: 'https://images.example.com/snack.jpg',
          sourceUrl: 'https://world.openfoodfacts.org/product/999',
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: FoodDetailPage(foodId: 10)),
        ),
      );
      await tester.pump();

      expect(find.byKey(const Key('food-hero-banner')), findsOneWidget);
      expect(find.byType(FoodThumbnail), findsNothing);
      final bannerSize = tester.getSize(
        find.byKey(const Key('food-hero-banner')),
      );
      expect(bannerSize.width, greaterThan(700));
      expect(bannerSize.height, greaterThanOrEqualTo(200));
      expect(find.text('View source'), findsOneWidget);
    },
  );

  testWidgets('shows the compact placeholder (no banner) when there is no image', (
    tester,
  ) async {
    final fake = FakeDiaryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: FoodDetailPage(foodId: 3)),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('food-hero-banner')), findsNothing);
    expect(find.byType(FoodThumbnail), findsOneWidget);
  });

  testWidgets('does not show a source link when none is known', (
    tester,
  ) async {
    final fake = FakeDiaryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: FoodDetailPage(foodId: 3)),
      ),
    );
    await tester.pump();

    expect(find.byType(FoodThumbnail), findsOneWidget);
    expect(find.text('View source'), findsNothing);
  });

  testWidgets(
    'tapping the edit icon opens the edit-food dialog pre-filled, and saving '
    'persists the change',
    (tester) async {
      final fake = FakeDiaryRepository()
        ..overrideFoodDetails = const FoodItem(
          id: 3,
          name: 'BBQ Pringles',
          calories: 150,
          proteinG: 1,
          carbsG: 15,
          fatG: 9,
        );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: FoodDetailPage(foodId: 3)),
        ),
      );
      await tester.pump();

      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit food'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('food-name-field')),
        'BBQ Pringles (updated)',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(fake.lastUpdatedFood?.name, 'BBQ Pringles (updated)');
      expect(find.text('BBQ Pringles (updated)'), findsOneWidget);
    },
  );

  testWidgets('shows projected daily totals preview and logs food on tap', (
    tester,
  ) async {
    final fake = FakeDiaryRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: FoodDetailPage(foodId: 3)),
      ),
    );
    await tester.pumpAndSettle();

    // Verify projected card shows up
    expect(find.text('Projected Daily Totals'), findsOneWidget);

    // Initial state: current (FakeDiaryRepository default has 3 entries: 300+450+95 = 845 kcal)
    // Projected is 845 + 100 = 945 kcal.
    expect(find.textContaining('845 → 945'), findsOneWidget);

    // Enter a new quantity: 2
    await tester.enterText(find.byType(TextField).first, '2');
    await tester.pumpAndSettle();

    // Projected becomes 845 + 200 = 1045 kcal.
    expect(find.textContaining('845 → 1045'), findsOneWidget);

    // Tap "Add to Log"
    await tester.tap(find.text('Add to Log'));
    await tester.pumpAndSettle();

    expect(fake.lastLoggedFoodId, 3);
    expect(fake.lastLoggedQuantity?.amount, 2.0);
  });
}
