import 'package:arndt_fitness/core/network/supabase_tables.dart';
import '../../../../core/entities/logged_quantity.dart';

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
    this.recipeId,
    this.servingSize,
    this.servingUnit,
    this.imageUrl,
  });

  final int id;
  final DateTime loggedAt;
  final MealType mealType;
  final String foodName;

  /// Quantity logged. Exposes amount and unit.
  final LoggedQuantity quantity;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Null for recipe-based entries (no single underlying `foods` row).
  final int? foodId;

  /// Null for food-based entries. Set for entries logged from a recipe —
  /// lets the UI navigate to that recipe's detail view.
  final int? recipeId;

  /// The underlying food's serving size/unit (e.g. `14`/`'crisps'`), from
  /// the joined `foods` row. Null for recipe-based entries, or foods with
  /// no serving size recorded.
  final double? servingSize;
  final String? servingUnit;

  /// The underlying food's photo, from the joined `foods` row. Null for
  /// recipe-based entries, or foods with no image known.
  final String? imageUrl;
}
