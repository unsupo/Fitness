import 'package:dio/dio.dart';

import '../../domain/entities/scanned_product.dart';
import '../../domain/repositories/barcode_lookup_repository.dart';
import '../../../../core/network/open_food_facts_data_source.dart';
import '../models/scanned_product_model.dart';

/// The adapter: OpenFoodFacts-backed [BarcodeLookupRepository]. Swappable for
/// FatSecret/Edamam later without touching scanner UI/domain code.
class OpenFoodFactsBarcodeRepository implements BarcodeLookupRepository {
  OpenFoodFactsBarcodeRepository({OpenFoodFactsDataSource? dataSource})
    : _dataSource = dataSource ?? OpenFoodFactsDataSource();

  final OpenFoodFactsDataSource _dataSource;

  @override
  Future<ScannedProduct?> lookup(String barcode) async {
    try {
      final json = await _dataSource.fetchProduct(barcode);
      if (json == null) return null;
      return ScannedProductModel.fromOpenFoodFactsJson(json);
    } on DioException {
      return null;
    }
  }
}
