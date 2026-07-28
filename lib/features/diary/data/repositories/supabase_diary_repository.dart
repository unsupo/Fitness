import 'package:arndt_fitness/core/network/open_food_facts_data_source.dart';
import 'package:arndt_fitness/core/network/supabase_json.dart';
import 'package:arndt_fitness/features/diary/data/data_sources/diary_remote_data_source.dart';
import 'package:arndt_fitness/features/diary/data/models/diary_entry_model.dart';
import 'package:arndt_fitness/features/diary/data/models/online_food_candidate_model.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/data/models/food_item_model.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/domain/entities/online_food_candidate.dart';
import 'package:arndt_fitness/features/diary/domain/repositories/diary_repository.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/dedupe_recent_foods.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The Supabase adapter implementation of [DiaryRepository] — the concrete
/// backend the app defaults to. Delegates to [DiaryRemoteDataSource] and maps
/// raw JSON/models to domain entities.
class SupabaseDiaryRepository implements DiaryRepository {
  SupabaseDiaryRepository(SupabaseClient client, {OpenFoodFactsDataSource? offDataSource})
    : _dataSource = DiaryRemoteDataSource(client),
      _offDataSource = offDataSource ?? OpenFoodFactsDataSource();

  final DiaryRemoteDataSource _dataSource;
  final OpenFoodFactsDataSource _offDataSource;

  @override
  Future<List<DiaryEntry>> getEntriesForDate(DateTime date) async {
    final rows = await _dataSource.getEntriesForDate(date);
    return rows.map((row) => DiaryEntryModel.fromJson(row).toEntity()).toList();
  }

  @override
  Future<DailyGoals> getDailyGoals() async {
    final row = await _dataSource.getDailyGoals();
    return DailyGoals(
      calorieGoal: parseSupabaseNum(row['calorie_goal']),
      proteinGoalG: parseSupabaseNum(row['protein_goal_g']),
      carbsGoalG: parseSupabaseNum(row['carbs_goal_g']),
      fatGoalG: parseSupabaseNum(row['fat_goal_g']),
    );
  }

  @override
  Future<void> updateDailyGoals(DailyGoals goals) => _dataSource.updateDailyGoals({
    'calorie_goal': goals.calorieGoal,
    'protein_goal_g': goals.proteinGoalG,
    'carbs_goal_g': goals.carbsGoalG,
    'fat_goal_g': goals.fatGoalG,
  });

  @override
  Future<FoodItem> getFoodDetails(int foodId) async {
    final row = await _dataSource.getFoodDetails(foodId);
    return FoodItemModel.fromJson(row).toEntity();
  }

  @override
  Future<void> updateFood(FoodItem food) => _dataSource.updateFood(food.id, {
    'name': food.name,
    'brand': food.brand,
    'serving_size': food.servingSize,
    'serving_unit': food.servingUnit,
    'calories': food.calories,
    'protein_g': food.proteinG,
    'carbs_g': food.carbsG,
    'fat_g': food.fatG,
    'fiber_g': food.fiberG,
    'sugar_g': food.sugarG,
    'sodium_mg': food.sodiumMg,
    'image_url': food.imageUrl,
    'source_url': food.sourceUrl,
  });

  @override
  Future<void> updateEntry(DiaryEntry entry) => _dataSource.updateEntry(
    id: entry.id,
    quantity: entry.quantity,
    mealType: entry.mealType.name,
    loggedAt: entry.loggedAt,
    calories: entry.calories,
    proteinG: entry.proteinG,
    carbsG: entry.carbsG,
    fatG: entry.fatG,
  );

  @override
  Future<void> deleteEntry(int id) => _dataSource.deleteEntry(id);

  @override
  Future<List<FoodItem>> getRecentFoods({int limit = 8}) async {
    final rows = await _dataSource.getRecentFoodLogRows();
    final foods = <FoodItem>[];
    for (final row in rows) {
      final foodJson = row['foods'] as Map<String, dynamic>?;
      if (foodJson == null) continue; // recipe-only entries have no linked food
      foods.add(FoodItemModel.fromJson(foodJson).toEntity());
    }
    return dedupeRecentFoods(foods, limit: limit);
  }

  @override
  Future<List<OnlineFoodCandidate>> searchOnlineFoods(String query) async {
    if (query.trim().isEmpty) return [];
    try {
      final products = await _offDataSource.searchProductsByName(query);
      return products.map(OnlineFoodCandidateModel.fromOpenFoodFactsJson).toList();
    } on DioException {
      return []; // best-effort — a broken OFF API must never block local search
    }
  }

  @override
  Future<FoodItem> importOnlineFood(OnlineFoodCandidate candidate) async {
    final row = await _dataSource.insertFood({
      'name': candidate.name,
      'brand': candidate.brand,
      'serving_size': candidate.servingSize,
      'serving_unit': candidate.servingUnit,
      'calories': candidate.calories,
      'protein_g': candidate.proteinG,
      'carbs_g': candidate.carbsG,
      'fat_g': candidate.fatG,
      'image_url': candidate.imageUrl,
      'source_url': candidate.sourceUrl,
      'source': 'openfoodfacts',
      'is_estimate': false,
    });
    return FoodItemModel.fromJson(row).toEntity();
  }
}
