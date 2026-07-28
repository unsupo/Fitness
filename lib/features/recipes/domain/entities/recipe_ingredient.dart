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
  });

  final int foodId;
  final String foodName;
  final double quantity;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
}
