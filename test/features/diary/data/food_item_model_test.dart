import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/data/models/food_item_model.dart';

void main() {
  test('fromJson maps a foods table row, tolerating null optional fields', () {
    final json = {
      'id': 3,
      'name': 'BBQ Pringles',
      'brand': null,
      'serving_size': '28',
      'serving_unit': 'g',
      'calories': '150',
      'protein_g': '1',
      'carbs_g': '15',
      'fat_g': '9',
      'fiber_g': null,
      'sugar_g': '1',
      'sodium_mg': '210',
      'is_estimate': false,
      'image_url': null,
      'source_url': null,
    };

    final food = FoodItemModel.fromJson(json).toEntity();

    expect(food.id, 3);
    expect(food.name, 'BBQ Pringles');
    expect(food.brand, isNull);
    expect(food.servingSize, 28);
    expect(food.servingUnit, 'g');
    expect(food.calories, 150);
    expect(food.sugarG, 1);
    expect(food.fiberG, isNull);
    expect(food.isEstimate, false);
    expect(food.imageUrl, isNull);
    expect(food.sourceUrl, isNull);
  });

  test('fromJson maps image_url/source_url when present', () {
    final json = {
      'id': 9,
      'name': 'Some Bar',
      'calories': '200',
      'protein_g': '5',
      'carbs_g': '20',
      'fat_g': '8',
      'image_url': 'https://images.example.com/some-bar.jpg',
      'source_url': 'https://world.openfoodfacts.org/product/123',
    };

    final food = FoodItemModel.fromJson(json).toEntity();

    expect(food.imageUrl, 'https://images.example.com/some-bar.jpg');
    expect(food.sourceUrl, 'https://world.openfoodfacts.org/product/123');
  });
}
