import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/data/models/online_food_candidate_model.dart';

void main() {
  group('OnlineFoodCandidateModel.fromOpenFoodFactsJson', () {
    test('scales per-100g nutriments to product_quantity and derives image/source url', () {
      final product = {
        'code': '0687456101018',
        'product_name': 'Dark Chocolate Nuts & Sea Salt',
        'brands': 'KIND',
        'product_quantity': '40',
        'image_front_url': 'https://images.example.com/front.jpg',
        'nutriments': {
          'energy-kcal_100g': 500,
          'proteins_100g': 10,
          'carbohydrates_100g': 45,
          'fat_100g': 30,
        },
      };

      final candidate = OnlineFoodCandidateModel.fromOpenFoodFactsJson(product);

      expect(candidate.name, 'Dark Chocolate Nuts & Sea Salt');
      expect(candidate.brand, 'KIND');
      expect(candidate.servingSize, 40);
      expect(candidate.servingUnit, 'g');
      expect(candidate.calories, closeTo(200, 0.001));
      expect(candidate.proteinG, closeTo(4, 0.001));
      expect(candidate.carbsG, closeTo(18, 0.001));
      expect(candidate.fatG, closeTo(12, 0.001));
      expect(candidate.imageUrl, 'https://images.example.com/front.jpg');
      expect(
        candidate.sourceUrl,
        'https://world.openfoodfacts.org/product/0687456101018',
      );
    });

    test(
      'falls back to image_url when image_front_url absent, defaults to '
      'per-100g/100g weight and null image/source when code/images missing',
      () {
        final product = {
          'product_name': 'Mystery Bar',
          'nutriments': {'energy-kcal_100g': 250, 'proteins_100g': 5},
        };

        final candidate = OnlineFoodCandidateModel.fromOpenFoodFactsJson(product);

        expect(candidate.name, 'Mystery Bar');
        expect(candidate.brand, isNull);
        expect(candidate.servingSize, 100);
        expect(candidate.calories, closeTo(250, 0.001));
        expect(candidate.carbsG, 0);
        expect(candidate.fatG, 0);
        expect(candidate.imageUrl, isNull);
        expect(candidate.sourceUrl, isNull);
      },
    );

    test(
      'prefers serving_quantity over product_quantity for scaling (the '
      'latter is the whole package, e.g. a 630g jar with 15g servings)',
      () {
        final product = {
          'code': '59032823',
          'product_name': 'Nutella',
          'product_quantity': '630',
          'serving_quantity': '15',
          'nutriments': {
            'energy-kcal_100g': 539,
            'proteins_100g': 6.3,
            'carbohydrates_100g': 57.5,
            'fat_100g': 30.9,
          },
        };

        final candidate = OnlineFoodCandidateModel.fromOpenFoodFactsJson(product);

        expect(candidate.servingSize, 15);
        expect(candidate.calories, closeTo(80.85, 0.01));
      },
    );

    test('uses image_url when image_front_url is absent', () {
      final product = {
        'code': '123',
        'product_name': 'Thing',
        'image_url': 'https://images.example.com/plain.jpg',
        'nutriments': <String, dynamic>{},
      };

      final candidate = OnlineFoodCandidateModel.fromOpenFoodFactsJson(product);

      expect(candidate.imageUrl, 'https://images.example.com/plain.jpg');
    });
  });
}
