import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/domain/use_cases/utc_day_range.dart';

void main() {
  test('converts a local calendar day into a correct UTC instant range', () {
    // A local date with no explicit timezone — DateTime(...) constructs this
    // in the current system-local zone, same as the app does with
    // `DateTime.now()`-derived dates.
    final localDate = DateTime(2026, 7, 20);

    final range = utcDayRange(localDate);

    // Regardless of the host's local UTC offset, the returned range must be
    // real UTC instants (isUtc == true) so PostgREST compares them correctly
    // against timestamptz columns, and must span exactly 24 hours starting
    // at local midnight.
    expect(range.start.isUtc, isTrue);
    expect(range.end.isUtc, isTrue);
    expect(range.end.difference(range.start), const Duration(days: 1));

    final expectedStartUtc = DateTime(2026, 7, 20).toUtc();
    expect(range.start, expectedStartUtc);
  });
}
