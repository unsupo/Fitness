/// OpenFoodFacts JSON values are inconsistently numeric-vs-string, similar
/// to Supabase's PostgREST responses (see `supabase_json.dart`) — parse
/// defensively rather than assuming one shape.
double? parseOffNum(Object? value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// OpenFoodFacts nutriments are per-100g; scale to the actual serving
/// weight when known (see callers' `scale` computation), defaulting a
/// missing nutriment to 0 rather than throwing.
double perServingFromOffNutriment(Object? per100gRaw, double scale) {
  final value = parseOffNum(per100gRaw) ?? 0;
  return value * scale;
}
