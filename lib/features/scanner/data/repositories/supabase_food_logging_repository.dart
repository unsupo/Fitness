import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/supabase_tables.dart';
import '../../domain/entities/recognized_meal.dart';
import '../../domain/entities/scanned_product.dart';
import '../../domain/repositories/food_logging_repository.dart';

/// Supabase-backed [FoodLoggingRepository] — the shared write path for both
/// scanner flows.
class SupabaseFoodLoggingRepository implements FoodLoggingRepository {
  SupabaseFoodLoggingRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<void> logScannedProduct(
    ScannedProduct product,
    MealType mealType,
  ) async {
    // Simplest correct approach per spec: always insert a new `foods` row
    // per scan rather than de-duping against existing rows.
    final foodRow =
        await _client
            .from(SupabaseTables.foods)
            .insert({
              'name': product.name,
              'brand': product.brand,
              'serving_size': product.servingWeightG,
              'serving_unit': 'g',
              'calories': product.calories,
              'protein_g': product.proteinG,
              'carbs_g': product.carbsG,
              'fat_g': product.fatG,
              'sugar_g': product.sugarG,
              'image_url': product.imageUrl,
              'source_url': product.sourceUrl,
              'source': 'openfoodfacts',
              'is_estimate': false,
            })
            .select('id')
            .single();

    await _client.from(SupabaseTables.foodLog).insert({
      'logged_at': DateTime.now().toUtc().toIso8601String(),
      'food_id': foodRow['id'],
      'quantity': 1,
      'calories': product.calories,
      'protein_g': product.proteinG,
      'carbs_g': product.carbsG,
      'fat_g': product.fatG,
      'meal_type': mealType.name,
    });
  }

  @override
  Future<void> logRecognizedMeal(
    RecognizedMeal meal,
    MealType mealType,
  ) async {
    final foodRow =
        await _client
            .from(SupabaseTables.foods)
            .insert({
              'name': meal.name,
              'calories': meal.estimatedCalories,
              'protein_g': meal.proteinG,
              'carbs_g': meal.carbsG,
              'fat_g': meal.fatG,
              'source': 'ai_estimate',
              'is_estimate': true,
            })
            .select('id')
            .single();

    await _client.from(SupabaseTables.foodLog).insert({
      'logged_at': DateTime.now().toUtc().toIso8601String(),
      'food_id': foodRow['id'],
      'quantity': meal.servings,
      'calories': meal.estimatedCalories * meal.servings,
      'protein_g': meal.proteinG * meal.servings,
      'carbs_g': meal.carbsG * meal.servings,
      'fat_g': meal.fatG * meal.servings,
      'meal_type': mealType.name,
    });
  }
}
