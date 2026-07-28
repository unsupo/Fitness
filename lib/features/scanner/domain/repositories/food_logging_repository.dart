import '../../../../core/network/supabase_tables.dart';
import '../entities/recognized_meal.dart';
import '../entities/scanned_product.dart';

/// Shared write path for both scanner flows (barcode scan + AI recognition).
abstract class FoodLoggingRepository {
  /// Inserts into `foods` (source = 'openfoodfacts') then inserts a
  /// `food_log` row referencing it.
  Future<void> logScannedProduct(ScannedProduct product, MealType mealType);

  /// Inserts a `foods` row for the recognized meal (source = 'ai_estimate',
  /// is_estimate = true) then a `food_log` row referencing it, with
  /// quantities scaled by `meal.servings`.
  Future<void> logRecognizedMeal(RecognizedMeal meal, MealType mealType);
}
