import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';

/// Removes duplicate [FoodItem]s by `id`, keeping the first occurrence of
/// each (callers must pass foods pre-sorted most-recent-first), and caps the
/// result to [limit] distinct foods.
List<FoodItem> dedupeRecentFoods(List<FoodItem> foods, {int limit = 8}) {
  final seen = <int>{};
  final result = <FoodItem>[];

  for (final food in foods) {
    if (!seen.add(food.id)) continue;
    result.add(food);
    if (result.length >= limit) break;
  }

  return result;
}
