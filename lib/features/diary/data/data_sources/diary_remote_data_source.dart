import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/utc_day_range.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper around [SupabaseClient] — one method per query. Returns raw
/// decoded JSON; mapping to domain entities happens in the repository/model
/// layer, not here.
class DiaryRemoteDataSource {
  DiaryRemoteDataSource(this._client);

  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> getEntriesForDate(DateTime date) async {
    final range = utcDayRange(date);

    final rows = await _client
        .from(SupabaseTables.foodLog)
        .select('*, foods(name, serving_size, serving_unit, image_url), recipes(name)')
        .gte('logged_at', range.start.toIso8601String())
        .lt('logged_at', range.end.toIso8601String())
        .order('logged_at', ascending: true);

    return List<Map<String, dynamic>>.from(rows);
  }

  Future<Map<String, dynamic>> getDailyGoals() async {
    return await _client
        .from(SupabaseTables.dailyGoals)
        .select()
        .limit(1)
        .single();
  }

  Future<void> updateDailyGoals(Map<String, dynamic> fields) async {
    final row = await _client.from(SupabaseTables.dailyGoals).select('id').single();
    await _client
        .from(SupabaseTables.dailyGoals)
        .update(fields)
        .eq('id', row['id']);
  }

  Future<Map<String, dynamic>> getFoodDetails(int foodId) async {
    return await _client.from(SupabaseTables.foods).select().eq('id', foodId).single();
  }

  Future<void> updateFood(int foodId, Map<String, dynamic> fields) async {
    await _client.from(SupabaseTables.foods).update(fields).eq('id', foodId);
  }

  Future<void> updateEntry({
    required int id,
    required double quantity,
    required String quantityUnit,
    required String mealType,
    required DateTime loggedAt,
    required double calories,
    required double proteinG,
    required double carbsG,
    required double fatG,
  }) async {
    await _client
        .from(SupabaseTables.foodLog)
        .update({
          'quantity': quantity,
          'quantity_unit': quantityUnit,
          'meal_type': mealType,
          'logged_at': loggedAt.toUtc().toIso8601String(),
          'calories': calories,
          'protein_g': proteinG,
          'carbs_g': carbsG,
          'fat_g': fatG,
        })
        .eq('id', id);
  }

  Future<void> deleteEntry(int id) async {
    await _client.from(SupabaseTables.foodLog).delete().eq('id', id);
  }

  /// Raw joined food_log rows for the most-recently-logged foods (the same
  /// food_id may repeat across different log times); deduped by the
  /// repository, not here.
  Future<List<Map<String, dynamic>>> getRecentFoodLogRows({
    int rawLimit = 30,
  }) async {
    final rows = await _client
        .from(SupabaseTables.foodLog)
        .select('food_id, logged_at, foods(*)')
        .not('food_id', 'is', null)
        .order('logged_at', ascending: false)
        .limit(rawLimit);

    return List<Map<String, dynamic>>.from(rows);
  }

  /// Inserts a full `foods` row and returns every column back (not just
  /// `id`), so the caller can build a complete `FoodItem` without a second
  /// round trip.
  Future<Map<String, dynamic>> insertFood(Map<String, dynamic> row) async {
    return await _client
        .from(SupabaseTables.foods)
        .insert(row)
        .select()
        .single();
  }

  Future<void> insertFoodLog(Map<String, dynamic> row) async {
    await _client.from(SupabaseTables.foodLog).insert(row);
  }
}
