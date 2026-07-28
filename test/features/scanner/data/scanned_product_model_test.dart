import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/scanner/data/models/scanned_product_model.dart';

void main() {
  group('ScannedProductModel.fromOpenFoodFactsJson', () {
    test('scales per-100g nutriments to product_quantity when present', () {
      const json = {
        'code': '0687456101018',
        'status': 1,
        'product': {
          'product_name': 'Dark Chocolate Nuts & Sea Salt',
          'brands': 'KIND',
          'product_quantity': '40',
          'image_front_url': 'https://images.example.com/front.jpg',
          'nutriments': {
            'energy-kcal_100g': 500,
            'proteins_100g': 10,
            'carbohydrates_100g': 45,
            'sugars_100g': 20,
            'fat_100g': 30,
          },
        },
      };

      final product = ScannedProductModel.fromOpenFoodFactsJson(json);

      expect(product.barcode, '0687456101018');
      expect(product.name, 'Dark Chocolate Nuts & Sea Salt');
      expect(product.brand, 'KIND');
      expect(product.servingWeightG, 40);
      expect(product.calories, closeTo(200, 0.001));
      expect(product.proteinG, closeTo(4, 0.001));
      expect(product.carbsG, closeTo(18, 0.001));
      expect(product.sugarG, closeTo(8, 0.001));
      expect(product.fatG, closeTo(12, 0.001));
      expect(product.imageUrl, 'https://images.example.com/front.jpg');
      expect(
        product.sourceUrl,
        'https://world.openfoodfacts.org/product/0687456101018',
      );
    });

    test(
      'defaults to per-100g values and servingWeightG=100 when '
      'product_quantity is absent, and defaults missing nutriments to 0',
      () {
        const json = {
          'code': '5000159407236',
          'status': 1,
          'product': {
            'product_name': 'Mystery Bar',
            'nutriments': {
              'energy-kcal_100g': 250,
              'proteins_100g': 5,
              // carbohydrates_100g, sugars_100g, fat_100g intentionally
              // missing to exercise the default-to-0 path.
            },
          },
        };

        final product = ScannedProductModel.fromOpenFoodFactsJson(json);

        expect(product.barcode, '5000159407236');
        expect(product.name, 'Mystery Bar');
        expect(product.brand, isNull);
        expect(product.servingWeightG, 100);
        expect(product.calories, closeTo(250, 0.001));
        expect(product.proteinG, closeTo(5, 0.001));
        expect(product.carbsG, 0);
        expect(product.sugarG, 0);
        expect(product.fatG, 0);
        // No image_front_url/image_url present in the fixture.
        expect(product.imageUrl, isNull);
        // `code` is present, so a source link is still derivable.
        expect(
          product.sourceUrl,
          'https://world.openfoodfacts.org/product/5000159407236',
        );
      },
    );

    test(
      'prefers serving_quantity over product_quantity for scaling (the '
      'latter is the whole package, e.g. a 630g jar with 15g servings)',
      () {
        const json = {
          'code': '59032823',
          'status': 1,
          'product': {
            'product_name': 'Nutella',
            'product_quantity': '630',
            'serving_quantity': '15',
            'nutriments': {
              'energy-kcal_100g': 539,
              'proteins_100g': 6.3,
              'carbohydrates_100g': 57.5,
              'sugars_100g': 56.3,
              'fat_100g': 30.9,
            },
          },
        };

        final product = ScannedProductModel.fromOpenFoodFactsJson(json);

        expect(product.servingWeightG, 15);
        expect(product.calories, closeTo(80.85, 0.01));
      },
    );

    test('sourceUrl is null when code is absent', () {
      const json = {
        'status': 1,
        'product': {
          'product_name': 'No Code Item',
          'nutriments': {'energy-kcal_100g': 100},
        },
      };

      final product = ScannedProductModel.fromOpenFoodFactsJson(json);

      expect(product.sourceUrl, isNull);
    });
  });
}
