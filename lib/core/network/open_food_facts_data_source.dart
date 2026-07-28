import 'package:dio/dio.dart';

/// Thin wrapper around the OpenFoodFacts REST API. No API key required.
/// Lives in core (not a single feature's data layer) because it's used by
/// both the scanner feature (barcode lookup) and the diary feature (live
/// text search for foods with no local match).
class OpenFoodFactsDataSource {
  OpenFoodFactsDataSource({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const _productUrl = 'https://world.openfoodfacts.org/api/v2/product';
  static const _searchUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

  /// Returns the raw decoded JSON, or `null` if the product wasn't found
  /// (non-200 response, or a `status: 0` body meaning "not found").
  Future<Map<String, dynamic>?> fetchProduct(String barcode) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_productUrl/$barcode.json',
    );
    if (response.statusCode != 200) return null;
    final data = response.data;
    if (data == null) return null;
    if (data['status'] == 0) return null;
    return data;
  }

  /// Text search by product name. Returns up to [pageSize] raw product JSON
  /// maps (the response's `products` array), or an empty list on a
  /// non-200 response or a missing `products` key.
  Future<List<Map<String, dynamic>>> searchProductsByName(
    String query, {
    int pageSize = 10,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      _searchUrl,
      queryParameters: {
        'search_terms': query,
        'json': 1,
        'page_size': pageSize,
      },
    );
    if (response.statusCode != 200) return [];
    final products = response.data?['products'] as List<dynamic>?;
    if (products == null) return [];
    return products.cast<Map<String, dynamic>>();
  }
}
