import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/use_cases/format_week_range.dart';

void main() {
  test('formats a week within the same month as "MMM d-d"', () {
    expect(formatWeekRange(DateTime(2026, 7, 20)), 'Jul 20-26');
  });

  test('formats a week spanning two months as "MMM d - MMM d"', () {
    expect(formatWeekRange(DateTime(2026, 7, 27)), 'Jul 27 - Aug 2');
  });
}
