import '../../../../core/entities/logged_quantity.dart';

/// One ingredient line of a [Recipe] — a quantity of a `foods` row, with its
/// macro contribution to the recipe already computed (`quantity * food.macro`).
class RecipeIngredient {
  const RecipeIngredient({
    required this.foodId,
    required this.foodName,
    required this.quantity,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.servingSize,
    this.servingUnit,
  });

  final int foodId;
  final String foodName;
  final LoggedQuantity quantity;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? servingSize;
  final String? servingUnit;
}
