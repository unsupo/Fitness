import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/dedupe_recent_foods.dart';

FoodItem _food(int id, String name) => FoodItem(
  id: id,
  name: name,
  calories: 100,
  proteinG: 5,
  carbsG: 10,
  fatG: 2,
);

void main() {
  group('dedupeRecentFoods', () {
    test('keeps only the first occurrence of each food id', () {
      final foods = [_food(1, 'A'), _food(2, 'B'), _food(1, 'A again')];

      final result = dedupeRecentFoods(foods);

      expect(result.length, 2);
      expect(result[0].name, 'A');
      expect(result[1].name, 'B');
    });

    test('caps the result at limit', () {
      final foods = [for (var i = 0; i < 20; i++) _food(i, 'Food $i')];

      final result = dedupeRecentFoods(foods, limit: 3);

      expect(result.length, 3);
    });

    test('empty input produces empty output', () {
      expect(dedupeRecentFoods(const []), isEmpty);
    });
  });
}
