import 'package:arndt_fitness/core/network/supabase_tables.dart';

/// One logged food — mirrors a `food_log` row joined with its `foods` name.
class DiaryEntry {
  const DiaryEntry({
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
    this.servingSize,
    this.servingUnit,
    this.imageUrl,
  });

  final int id;
  final DateTime loggedAt;
  final MealType mealType;
  final String foodName;

  /// Number of servings logged (e.g. `0.5` for half a serving) — not a raw
  /// unit count. See `formatQuantity` to turn this into something
  /// human-readable like "7 crisps".
  final double quantity;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Null for recipe-based entries (no single underlying `foods` row).
  final int? foodId;

  /// The underlying food's serving size/unit (e.g. `14`/`'crisps'`), from
  /// the joined `foods` row. Null for recipe-based entries, or foods with
  /// no serving size recorded.
  final double? servingSize;
  final String? servingUnit;

  /// The underlying food's photo, from the joined `foods` row. Null for
  /// recipe-based entries, or foods with no image known.
  final String? imageUrl;
}
