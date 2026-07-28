/// PostgREST does not consistently serialize Postgres `numeric` columns as
/// JSON strings — some values arrive as JSON numbers (`num`), others as
/// strings, depending on the value/driver path. Every numeric field read
/// from a Supabase row must go through this instead of a raw
/// `double.parse(json['x'] as String)`, which throws whenever a row happens
/// to arrive as a native `num`.
double parseSupabaseNum(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.parse(value);
  throw FormatException('Expected num or String, got ${value.runtimeType}: $value');
}
