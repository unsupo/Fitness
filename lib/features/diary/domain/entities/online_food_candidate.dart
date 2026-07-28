/// A food found via a live OpenFoodFacts text search — not yet a row in the
/// local `foods` table (no `id`). Kept as its own type rather than a
/// sentinel-id [FoodItem] so "not yet persisted" can't be silently misused
/// as real, storable data; see `DiaryRepository.importOnlineFood`.
class OnlineFoodCandidate {
  const OnlineFoodCandidate({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.brand,
    this.servingSize,
    this.servingUnit,
    this.imageUrl,
    this.sourceUrl,
  });

  final String name;
  final String? brand;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double? servingSize;
  final String? servingUnit;
  final String? imageUrl;
  final String? sourceUrl;
}
