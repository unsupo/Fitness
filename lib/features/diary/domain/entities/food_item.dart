/// A food that can be logged — mirrors a row in the `foods` table.
class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.brand,
    this.servingSize,
    this.servingUnit,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.isEstimate,
    this.imageUrl,
    this.sourceUrl,
  });

  final int id;
  final String name;
  final String? brand;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? servingSize;
  final String? servingUnit;
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final bool? isEstimate;

  /// Remote product photo URL (e.g. an OpenFoodFacts image). Null when no
  /// image is known for this food.
  final String? imageUrl;

  /// Link to the real external product page this food came from. Null for
  /// foods with no known external source (hand-typed, AI-estimated, etc).
  final String? sourceUrl;
}
