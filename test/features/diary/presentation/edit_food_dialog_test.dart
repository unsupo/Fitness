import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/edit_food_dialog.dart';

import '../fakes/fake_diary_repository.dart';

void main() {
  const startingFood = FoodItem(
    id: 3,
    name: 'BBQ Pringles',
    brand: 'Pringles',
    calories: 150,
    proteinG: 1,
    carbsG: 15,
    fatG: 9,
    servingSize: 28,
    servingUnit: 'g',
    imageUrl: 'https://images.example.com/pringles.jpg',
    sourceUrl: 'https://world.openfoodfacts.org/product/123',
  );

  Future<FakeDiaryRepository> pumpDialog(WidgetTester tester) async {
    final fake = FakeDiaryRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [diaryRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showEditFoodDialog(context, ref, startingFood),
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

  testWidgets('pre-fills fields from the current food', (tester) async {
    await pumpDialog(tester);

    expect(
      tester.widget<TextField>(find.byKey(const Key('food-name-field'))).controller!.text,
      'BBQ Pringles',
    );
    expect(
      tester.widget<TextField>(find.byKey(const Key('food-calories-field'))).controller!.text,
      '150',
    );
    expect(
      tester.widget<TextField>(find.byKey(const Key('food-image-url-field'))).controller!.text,
      'https://images.example.com/pringles.jpg',
    );
    expect(
      tester.widget<TextField>(find.byKey(const Key('food-source-url-field'))).controller!.text,
      'https://world.openfoodfacts.org/product/123',
    );
  });

  testWidgets('saving calls updateFood with the edited values', (tester) async {
    final fake = await pumpDialog(tester);

    await tester.enterText(
      find.byKey(const Key('food-name-field')),
      'BBQ Pringles (Family Size)',
    );
    await tester.enterText(
      find.byKey(const Key('food-image-url-field')),
      'https://images.example.com/new.jpg',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.lastUpdatedFood, isNotNull);
    expect(fake.lastUpdatedFood!.name, 'BBQ Pringles (Family Size)');
    expect(fake.lastUpdatedFood!.imageUrl, 'https://images.example.com/new.jpg');
    expect(fake.lastUpdatedFood!.calories, 150);
    expect(fake.lastUpdatedFood!.sourceUrl, startingFood.sourceUrl);
  });

  testWidgets('does not save when name or calories is invalid/empty', (
    tester,
  ) async {
    final fake = await pumpDialog(tester);

    await tester.enterText(find.byKey(const Key('food-name-field')), '');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.lastUpdatedFood, isNull);
  });

  testWidgets('Cancel closes without saving', (tester) async {
    final fake = await pumpDialog(tester);

    await tester.enterText(
      find.byKey(const Key('food-name-field')),
      'Should not save',
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(fake.lastUpdatedFood, isNull);
  });
}
