import '../../../../core/network/open_food_facts_json.dart';
import '../../domain/entities/scanned_product.dart';

/// Maps an OpenFoodFacts `GET /api/v2/product/{barcode}.json` response body
/// onto the domain [ScannedProduct] entity.
class ScannedProductModel extends ScannedProduct {
  const ScannedProductModel({
    required super.barcode,
    required super.name,
    super.brand,
    super.servingWeightG,
    required super.calories,
    required super.proteinG,
    required super.carbsG,
    required super.sugarG,
    required super.fatG,
    super.imageUrl,
    super.sourceUrl,
  });

  factory ScannedProductModel.fromOpenFoodFactsJson(
    Map<String, dynamic> json,
  ) {
    final product = (json['product'] as Map<String, dynamic>?) ?? const {};
    final nutriments =
        (product['nutriments'] as Map<String, dynamic>?) ?? const {};

    // `serving_quantity` is the true per-serving weight; `product_quantity`
    // is the whole package (e.g. a 630g jar with 15g servings) and is only
    // a reasonable stand-in when no serving size is given at all.
    final servingWeightG =
        parseOffNum(product['serving_quantity']) ??
        parseOffNum(product['product_quantity']);
    // OpenFoodFacts nutriments are per-100g; scale to the actual serving
    // weight when known, else fall back to showing per-100g values.
    final scale = servingWeightG != null ? servingWeightG / 100.0 : 1.0;
    final displayWeightG = servingWeightG ?? 100.0;
    final code = json['code'] as String?;

    return ScannedProductModel(
      barcode: code ?? '',
      name: (product['product_name'] as String?) ?? 'Unknown product',
      brand: product['brands'] as String?,
      servingWeightG: displayWeightG,
      calories: perServingFromOffNutriment(nutriments['energy-kcal_100g'], scale),
      proteinG: perServingFromOffNutriment(nutriments['proteins_100g'], scale),
      carbsG: perServingFromOffNutriment(nutriments['carbohydrates_100g'], scale),
      sugarG: perServingFromOffNutriment(nutriments['sugars_100g'], scale),
      fatG: perServingFromOffNutriment(nutriments['fat_100g'], scale),
      imageUrl:
          (product['image_front_url'] as String?) ??
          (product['image_url'] as String?),
      sourceUrl: code != null
          ? 'https://world.openfoodfacts.org/product/$code'
          : null,
    );
  }
}
