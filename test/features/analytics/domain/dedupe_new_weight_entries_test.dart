import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/weight_entry.dart';
import 'package:arndt_fitness/features/analytics/domain/use_cases/dedupe_new_weight_entries.dart';

void main() {
  test('keeps parsed entries whose timestamp has no match in existing history', () {
    final parsed = [
      (loggedAt: DateTime(2026, 7, 12, 21, 47), weightKg: 112.6),
      (loggedAt: DateTime(2026, 7, 19, 21, 40), weightKg: 113.8),
    ];

    final result = dedupeNewWeightEntries(parsed, const []);

    expect(result, parsed);
  });

  test('drops parsed entries with a timestamp already present in history', () {
    final parsed = [
      (loggedAt: DateTime(2026, 7, 12, 21, 47), weightKg: 112.6),
      (loggedAt: DateTime(2026, 7, 19, 21, 40), weightKg: 113.8),
    ];
    final existing = [
      WeightEntry(
        id: 1,
        loggedAt: DateTime(2026, 7, 12, 21, 47),
        weightKg: 112.6,
        goalType: 'lose',
      ),
    ];

    final result = dedupeNewWeightEntries(parsed, existing);

    expect(result, [parsed[1]]);
  });

  test('drops every entry when the whole file was already imported', () {
    final parsed = [
      (loggedAt: DateTime(2026, 7, 12, 21, 47), weightKg: 112.6),
    ];
    final existing = [
      WeightEntry(
        id: 1,
        loggedAt: DateTime(2026, 7, 12, 21, 47),
        weightKg: 112.6,
        goalType: 'lose',
      ),
    ];

    final result = dedupeNewWeightEntries(parsed, existing);

    expect(result, isEmpty);
  });

  test('matching is by timestamp alone, not weight', () {
    // Same instant re-exported with a slightly different rounded weight
    // should still count as the same reading, not a new one.
    final parsed = [
      (loggedAt: DateTime(2026, 7, 12, 21, 47), weightKg: 112.7),
    ];
    final existing = [
      WeightEntry(
        id: 1,
        loggedAt: DateTime(2026, 7, 12, 21, 47),
        weightKg: 112.6,
        goalType: 'lose',
      ),
    ];

    final result = dedupeNewWeightEntries(parsed, existing);

    expect(result, isEmpty);
  });
}
