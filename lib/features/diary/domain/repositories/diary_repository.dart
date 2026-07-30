import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/domain/entities/online_food_candidate.dart';

abstract class DiaryRepository {
  Future<List<DiaryEntry>> getEntriesForDate(DateTime date);
  Future<DailyGoals> getDailyGoals();

  /// Persists new calorie/macro targets to the single `daily_goals` row.
  Future<void> updateDailyGoals(DailyGoals goals);

  Future<FoodItem> getFoodDetails(int foodId);

  /// Persists edited details (name, macros, image, source link, etc.) for
  /// the underlying `foods` row — distinct from `updateEntry`, which only
  /// edits a `food_log` row's quantity/mealType/loggedAt. Editing a food's
  /// name here changes what already-logged diary entries display too, since
  /// their name is joined live from `foods`, not frozen at log time.
  Future<void> updateFood(FoodItem food);

  /// Persists [entry]'s current field values (quantity, mealType, loggedAt,
  /// and the already-computed calories/macros — see `rescaleDiaryEntry`) to
  /// the underlying log row identified by `entry.id`.
  Future<void> updateEntry(DiaryEntry entry);

  Future<void> deleteEntry(int id);

  /// Logs a food item to the food_log table.
  Future<void> logFood({
    required int foodId,
    required LoggedQuantity quantity,
    required MealType mealType,
    required DateTime loggedAt,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
    double? servingSize,
    String? servingUnit,
  });

  /// Recently logged distinct foods, most-recently-logged first — shown
  /// wherever a food search's query box is empty (e.g. the recipe
  /// ingredient picker).
  Future<List<FoodItem>> getRecentFoods({int limit = 8});

  /// Live OpenFoodFacts text search for real product matches (image +
  /// source link) to offer alongside local `foods` table matches.
  Future<List<OnlineFoodCandidate>> searchOnlineFoods(String query);

  /// Persists [candidate] as a new `foods` row (mirrors
  /// `FoodLoggingRepository.logScannedProduct`'s insert-then-reference
  /// pattern) and returns it as a real [FoodItem] with a real `id`, usable
  /// as a `recipe_ingredients.food_id` / `food_log.food_id`.
  Future<FoodItem> importOnlineFood(OnlineFoodCandidate candidate);
}
