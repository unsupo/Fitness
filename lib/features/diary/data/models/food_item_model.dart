import 'package:arndt_fitness/core/network/supabase_json.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';

/// Maps a `foods` table row to a [FoodItem].
class FoodItemModel {
  const FoodItemModel({
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
  final String? imageUrl;
  final String? sourceUrl;

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    double? parseOptionalNum(Object? value) =>
        value == null ? null : parseSupabaseNum(value);

    return FoodItemModel(
      id: json['id'] as int,
      name: json['name'] as String,
      brand: json['brand'] as String?,
      calories: parseSupabaseNum(json['calories']),
      proteinG: parseSupabaseNum(json['protein_g']),
      carbsG: parseSupabaseNum(json['carbs_g']),
      fatG: parseSupabaseNum(json['fat_g']),
      servingSize: parseOptionalNum(json['serving_size']),
      servingUnit: json['serving_unit'] as String?,
      fiberG: parseOptionalNum(json['fiber_g']),
      sugarG: parseOptionalNum(json['sugar_g']),
      sodiumMg: parseOptionalNum(json['sodium_mg']),
      isEstimate: json['is_estimate'] as bool?,
      imageUrl: json['image_url'] as String?,
      sourceUrl: json['source_url'] as String?,
    );
  }

  FoodItem toEntity() => FoodItem(
    id: id,
    name: name,
    brand: brand,
    calories: calories,
    proteinG: proteinG,
    carbsG: carbsG,
    fatG: fatG,
    servingSize: servingSize,
    servingUnit: servingUnit,
    fiberG: fiberG,
    sugarG: sugarG,
    sodiumMg: sodiumMg,
    isEstimate: isEstimate,
    imageUrl: imageUrl,
    sourceUrl: sourceUrl,
  );
}
