import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/domain/entities/online_food_candidate.dart';
import 'package:arndt_fitness/features/diary/domain/repositories/diary_repository.dart';

import 'package:arndt_fitness/core/entities/logged_quantity.dart';

/// A canned [DiaryRepository] for widget tests — no real network/Supabase
/// calls. Returns fixed entries across two meal types and a fixed goals row.
class FakeDiaryRepository implements DiaryRepository {
  FakeDiaryRepository({
    List<DiaryEntry>? entries,
    DailyGoals? goals,
    List<FoodItem>? recentFoods,
    List<OnlineFoodCandidate>? onlineFoods,
  }) : entries = List.of(entries ?? defaultEntries),
       goals = goals ?? defaultGoals,
       recentFoods = recentFoods ?? const [],
       onlineFoods = onlineFoods ?? const [];

  final List<DiaryEntry> entries;
  DailyGoals goals;
  final List<FoodItem> recentFoods;
  final List<OnlineFoodCandidate> onlineFoods;

  static final defaultEntries = <DiaryEntry>[
    DiaryEntry(
      id: 1,
      loggedAt: DateTime(2026, 7, 21, 8, 0),
      mealType: MealType.breakfast,
      foodName: 'Oatmeal',
      quantity: const LoggedQuantity(amount: 1.0, unit: 'serving'),
      calories: 300,
      proteinG: 10,
      carbsG: 50,
      fatG: 5,
    ),
    DiaryEntry(
      id: 2,
      loggedAt: DateTime(2026, 7, 21, 12, 30),
      mealType: MealType.lunch,
      foodName: 'Chicken Salad',
      quantity: const LoggedQuantity(amount: 1.0, unit: 'serving'),
      calories: 450,
      proteinG: 35,
      carbsG: 20,
      fatG: 18,
    ),
    DiaryEntry(
      id: 3,
      loggedAt: DateTime(2026, 7, 21, 12, 45),
      mealType: MealType.lunch,
      foodName: 'Apple',
      quantity: const LoggedQuantity(amount: 1.0, unit: 'serving'),
      calories: 95,
      proteinG: 0,
      carbsG: 25,
      fatG: 0,
    ),
  ];

  static const defaultGoals = DailyGoals(
    calorieGoal: 2000,
    proteinGoalG: 150,
    carbsGoalG: 200,
    fatGoalG: 65,
  );

  /// Counts calls so tests can assert a refetch happened after invalidation.
  int getEntriesForDateCallCount = 0;

  @override
  Future<List<DiaryEntry>> getEntriesForDate(DateTime date) async {
    getEntriesForDateCallCount++;
    return entries;
  }

  @override
  Future<DailyGoals> getDailyGoals() async => goals;

  @override
  Future<void> updateDailyGoals(DailyGoals newGoals) async {
    goals = newGoals;
  }

  /// Widget tests can set this to control what `getFoodDetails` returns.
  FoodItem? overrideFoodDetails;

  @override
  Future<FoodItem> getFoodDetails(int foodId) async =>
      overrideFoodDetails ??
      FoodItem(
        id: foodId,
        name: 'Fake Food',
        calories: 100,
        proteinG: 5,
        carbsG: 10,
        fatG: 2,
      );

  /// Records the last food passed to `updateFood`.
  FoodItem? lastUpdatedFood;

  @override
  Future<void> updateFood(FoodItem food) async {
    lastUpdatedFood = food;
    overrideFoodDetails = food;
  }

  /// Records the last entry passed to `updateEntry`, and the last id passed
  /// to `deleteEntry`, so tests can assert the presentation layer called the
  /// adapter with the right arguments.
  DiaryEntry? lastUpdatedEntry;
  int? lastDeletedId;

  @override
  Future<void> updateEntry(DiaryEntry entry) async {
    lastUpdatedEntry = entry;
    final index = entries.indexWhere((e) => e.id == entry.id);
    if (index != -1) entries[index] = entry;
  }

  @override
  Future<void> deleteEntry(int id) async {
    lastDeletedId = id;
    entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<FoodItem>> getRecentFoods({int limit = 8}) async =>
      recentFoods.take(limit).toList();

  /// Records the last query passed to `searchOnlineFoods`.
  String? lastSearchOnlineFoodsQuery;

  @override
  Future<List<OnlineFoodCandidate>> searchOnlineFoods(String query) async {
    lastSearchOnlineFoodsQuery = query;
    return onlineFoods;
  }

  /// Records the last candidate passed to `importOnlineFood`.
  OnlineFoodCandidate? lastImportedCandidate;

  @override
  Future<FoodItem> importOnlineFood(OnlineFoodCandidate candidate) async {
    lastImportedCandidate = candidate;
    return FoodItem(
      id: 999,
      name: candidate.name,
      brand: candidate.brand,
      calories: candidate.calories,
      proteinG: candidate.proteinG,
      carbsG: candidate.carbsG,
      fatG: candidate.fatG,
      servingSize: candidate.servingSize,
      servingUnit: candidate.servingUnit,
      imageUrl: candidate.imageUrl,
      sourceUrl: candidate.sourceUrl,
    );
  }

  int? lastLoggedFoodId;
  LoggedQuantity? lastLoggedQuantity;
  MealType? lastLoggedMealType;
  DateTime? lastLoggedAt;

  @override
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
  }) async {
    lastLoggedFoodId = foodId;
    lastLoggedQuantity = quantity;
    lastLoggedMealType = mealType;
    lastLoggedAt = loggedAt;

    entries.add(DiaryEntry(
      id: entries.length + 1,
      loggedAt: loggedAt,
      mealType: mealType,
      foodName: 'Food $foodId',
      quantity: quantity,
      calories: calories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      foodId: foodId,
      servingSize: servingSize,
      servingUnit: servingUnit,
    ));
  }
}
