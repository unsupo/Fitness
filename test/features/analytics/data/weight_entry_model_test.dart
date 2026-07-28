import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/data/models/weight_entry_model.dart';

void main() {
  test('fromJson converts logged_at (a UTC instant) to local time', () {
    final json = {
      'id': 1,
      'logged_at': '2026-07-22T00:51:46.750045+00:00',
      'weight_kg': '80.1',
      'goal_type': 'maintain',
    };

    final entry = WeightEntryModel.fromJson(json);

    expect(entry.loggedAt.isUtc, isFalse);
    expect(entry.weightKg, 80.1);
  });
}
