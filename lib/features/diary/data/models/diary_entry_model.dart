import 'package:arndt_fitness/core/network/supabase_json.dart';
import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/logged_quantity_converter.dart';

/// Maps a `food_log` row (joined with `foods(name)` and `recipes(name)`) to
/// a [DiaryEntry]. An entry references exactly one of `food_id`/`recipe_id`
/// — the other join comes back null.
///
/// Numeric Postgres columns (`numeric` type) don't consistently arrive as
/// `String` over PostgREST, so every numeric field goes through
/// [parseSupabaseNum] rather than a raw cast.
class DiaryEntryModel {
  const DiaryEntryModel({
    required this.id,
    required this.loggedAt,
    required this.mealType,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.foodId,
    this.recipeId,
    this.quantityUnit,
    this.servingSize,
    this.servingUnit,
    this.imageUrl,
  });

  final int id;
  final DateTime loggedAt;
  final MealType mealType;
  final String foodName;
  final double quantity;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final int? foodId;
  final int? recipeId;

  /// The unit the user actually picked when logging (e.g. `'g'`), persisted
  /// verbatim in `food_log.quantity_unit`. Null for rows logged before this
  /// column existed — those fall back to reconstructing a unit from serving
  /// size in [toEntity].
  final String? quantityUnit;
  final double? servingSize;
  final String? servingUnit;
  final String? imageUrl;

  factory DiaryEntryModel.fromJson(Map<String, dynamic> json) {
    final mealTypeRaw = json['meal_type'] as String?;
    final joinedFood = json['foods'] as Map<String, dynamic>?;
    final joinedRecipe = json['recipes'] as Map<String, dynamic>?;
    final rawServingSize = joinedFood?['serving_size'];

    return DiaryEntryModel(
      id: json['id'] as int,
      loggedAt: DateTime.parse(json['logged_at'] as String).toLocal(),
      mealType: mealTypeRaw == null
          ? MealType.snack
          : MealType.fromString(mealTypeRaw),
      foodName:
          (joinedFood?['name'] as String?) ??
          (joinedRecipe?['name'] as String?) ??
          'Unknown food',
      quantity: parseSupabaseNum(json['quantity']),
      calories: parseSupabaseNum(json['calories']),
      proteinG: parseSupabaseNum(json['protein_g']),
      carbsG: parseSupabaseNum(json['carbs_g']),
      fatG: parseSupabaseNum(json['fat_g']),
      foodId: json['food_id'] as int?,
      recipeId: json['recipe_id'] as int?,
      quantityUnit: json['quantity_unit'] as String?,
      servingSize: rawServingSize == null ? null : parseSupabaseNum(rawServingSize),
      servingUnit: joinedFood?['serving_unit'] as String?,
      imageUrl: joinedFood?['image_url'] as String?,
    );
  }

  DiaryEntry toEntity() => DiaryEntry(
    id: id,
    loggedAt: loggedAt,
    mealType: mealType,
    foodName: foodName,
    quantity: LoggedQuantityConverter.fromServingMultiplier(
      quantity,
      servingSize: servingSize,
      servingUnit: servingUnit,
      knownUnit: quantityUnit,
    ),
    calories: calories,
    proteinG: proteinG,
    carbsG: carbsG,
    fatG: fatG,
    foodId: foodId,
    recipeId: recipeId,
    servingSize: servingSize,
    servingUnit: servingUnit,
    imageUrl: imageUrl,
  );
}
