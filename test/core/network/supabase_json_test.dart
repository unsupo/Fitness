import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/core/network/supabase_json.dart';

void main() {
  test(
    'parseSupabaseTimestamp converts a UTC timestamptz string to local time',
    () {
      final result = parseSupabaseTimestamp('2026-07-28T00:02:36.157162+00:00');

      expect(result.isUtc, isFalse);
    },
  );
}
