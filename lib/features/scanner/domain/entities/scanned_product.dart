/// A food product looked up via barcode (OpenFoodFacts today, swappable for
/// another provider later). Pure Dart — no Flutter/Supabase imports.
class ScannedProduct {
  const ScannedProduct({
    required this.barcode,
    required this.name,
    this.brand,
    this.servingWeightG,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.sugarG,
    required this.fatG,
    this.imageUrl,
    this.sourceUrl,
  });

  final String barcode;
  final String name;
  final String? brand;
  final double? servingWeightG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double sugarG;
  final double fatG;
  final String? imageUrl;
  final String? sourceUrl;
}
