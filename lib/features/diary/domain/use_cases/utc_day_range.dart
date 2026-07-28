/// Converts a local calendar day into the correct `[start, end)` UTC instant
/// range for querying `timestamptz` columns.
///
/// `DateTime(y, m, d).toIso8601String()` on a local (non-UTC) `DateTime`
/// omits the timezone offset, so PostgREST/Postgres reads the string as a UTC
/// instant — silently shifting the day boundary by the local UTC offset and
/// misattributing entries logged near midnight to the wrong day. Always
/// convert to UTC before building query boundaries.
({DateTime start, DateTime end}) utcDayRange(DateTime localDate) {
  final start = DateTime(
    localDate.year,
    localDate.month,
    localDate.day,
  ).toUtc();
  return (start: start, end: start.add(const Duration(days: 1)));
}
