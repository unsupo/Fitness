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

/// Every `timestamptz` column read from a Supabase row must go through this
/// instead of a raw `DateTime.parse(json['x'] as String)`. PostgREST returns
/// these with a UTC offset, so parsing without `.toLocal()` leaves the
/// result UTC-flagged — correct as an instant, but every display site in
/// this app formats dates/times assuming local time, so an evening entry
/// that crosses UTC midnight silently shows under the wrong calendar day.
/// This exact bug has recurred independently in three features (diary,
/// weight log, workouts) as an easy-to-forget inline `.toLocal()` — this
/// helper makes the correct behavior the only way to call it.
DateTime parseSupabaseTimestamp(String value) => DateTime.parse(value).toLocal();
