import '../entities/scanned_product.dart';

/// Adapter seam for barcode lookup. OpenFoodFacts is today's implementation;
/// swappable for FatSecret/Edamam later without touching scanner UI/domain.
abstract class BarcodeLookupRepository {
  /// Returns `null` when the barcode isn't found by the provider.
  Future<ScannedProduct?> lookup(String barcode);
}
