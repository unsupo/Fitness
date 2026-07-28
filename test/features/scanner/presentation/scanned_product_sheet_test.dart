import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/features/scanner/domain/entities/scanned_product.dart';
import 'package:arndt_fitness/features/scanner/presentation/widgets/scanned_product_sheet.dart';

void main() {
  const product = ScannedProduct(
    barcode: '0687456101018',
    name: 'Dark Chocolate Nuts & Sea Salt',
    brand: 'KIND',
    servingWeightG: 40,
    calories: 200,
    proteinG: 4,
    carbsG: 18,
    sugarG: 8,
    fatG: 12,
  );

  Future<void> pumpSheet(
    WidgetTester tester, {
    required VoidCallback onAddToDiary,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScannedProductSheet(
            product: product,
            onAddToDiary: onAddToDiary,
          ),
        ),
      ),
    );
  }

  testWidgets('renders product name, weight, and macro stats', (
    tester,
  ) async {
    await pumpSheet(tester, onAddToDiary: () {});

    expect(find.text('Dark Chocolate Nuts & Sea Salt'), findsOneWidget);
    expect(find.text('KIND'), findsOneWidget);
    expect(find.text('Weight: 40g'), findsOneWidget);
    expect(find.text('200'), findsOneWidget); // calories
    expect(find.text('4g'), findsOneWidget); // protein
    expect(find.text('8g'), findsOneWidget); // sugar
    expect(find.text('12g'), findsOneWidget); // fat
    expect(find.text('Add to Diary'), findsOneWidget);
  });

  testWidgets('tapping Add to Diary invokes the callback', (tester) async {
    var tapped = false;
    await pumpSheet(tester, onAddToDiary: () => tapped = true);

    await tester.tap(find.text('Add to Diary'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('shows a thumbnail, and a source link when the product has one', (
    tester,
  ) async {
    const productWithSource = ScannedProduct(
      barcode: '0687456101018',
      name: 'Dark Chocolate Nuts & Sea Salt',
      brand: 'KIND',
      servingWeightG: 40,
      calories: 200,
      proteinG: 4,
      carbsG: 18,
      sugarG: 8,
      fatG: 12,
      imageUrl: 'https://images.example.com/kind-bar.jpg',
      sourceUrl: 'https://world.openfoodfacts.org/product/0687456101018',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScannedProductSheet(
            product: productWithSource,
            onAddToDiary: () {},
          ),
        ),
      ),
    );

    expect(find.byType(FoodThumbnail), findsOneWidget);
    expect(find.text('View source'), findsOneWidget);
  });

  testWidgets('does not show a source link when the product has none', (
    tester,
  ) async {
    await pumpSheet(tester, onAddToDiary: () {});

    expect(find.byType(FoodThumbnail), findsOneWidget);
    expect(find.text('View source'), findsNothing);
  });
}
