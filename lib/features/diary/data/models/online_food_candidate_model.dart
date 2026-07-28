import 'package:arndt_fitness/core/network/open_food_facts_json.dart';
import 'package:arndt_fitness/features/diary/domain/entities/online_food_candidate.dart';

/// Maps one entry of an OpenFoodFacts `cgi/search.pl` `products` array (a
/// raw product JSON map, not a `{code, status, product}` envelope like the
/// single-product `fetchProduct` response) to an [OnlineFoodCandidate].
class OnlineFoodCandidateModel extends OnlineFoodCandidate {
  const OnlineFoodCandidateModel({
    required super.name,
    required super.calories,
    required super.proteinG,
    required super.carbsG,
    required super.fatG,
    super.brand,
    super.servingSize,
    super.servingUnit,
    super.imageUrl,
    super.sourceUrl,
  });

  factory OnlineFoodCandidateModel.fromOpenFoodFactsJson(
    Map<String, dynamic> product,
  ) {
    final nutriments =
        (product['nutriments'] as Map<String, dynamic>?) ?? const {};

    // `serving_quantity` is the true per-serving weight; `product_quantity`
    // is the whole package (e.g. a 630g jar with 15g servings) and is only
    // a reasonable stand-in when no serving size is given at all.
    final servingWeightG =
        parseOffNum(product['serving_quantity']) ??
        parseOffNum(product['product_quantity']);
    final scale = servingWeightG != null ? servingWeightG / 100.0 : 1.0;
    final code = product['code'] as String?;

    return OnlineFoodCandidateModel(
      name: (product['product_name'] as String?) ?? 'Unknown product',
      brand: product['brands'] as String?,
      calories: perServingFromOffNutriment(nutriments['energy-kcal_100g'], scale),
      proteinG: perServingFromOffNutriment(nutriments['proteins_100g'], scale),
      carbsG: perServingFromOffNutriment(nutriments['carbohydrates_100g'], scale),
      fatG: perServingFromOffNutriment(nutriments['fat_100g'], scale),
      servingSize: servingWeightG ?? 100.0,
      servingUnit: 'g',
      imageUrl:
          (product['image_front_url'] as String?) ??
          (product['image_url'] as String?),
      sourceUrl: code != null
          ? 'https://world.openfoodfacts.org/product/$code'
          : null,
    );
  }
}
