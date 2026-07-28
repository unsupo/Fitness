import 'package:arndt_fitness/features/analytics/domain/use_cases/compute_macro_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('computeMacroBreakdown', () {
    test('sums protein/carbs/fat grams across all entries', () {
      final entries = <({double proteinG, double carbsG, double fatG})>[
        (proteinG: 20, carbsG: 50, fatG: 10),
        (proteinG: 30, carbsG: 25, fatG: 15),
        (proteinG: 10, carbsG: 25, fatG: 5),
      ];

      final result = computeMacroBreakdown(entries);

      expect(result.proteinG, 60);
      expect(result.carbsG, 100);
      expect(result.fatG, 30);
    });

    test('percent getters reflect share of total grams, not calories', () {
      final entries = <({double proteinG, double carbsG, double fatG})>[
        (proteinG: 50, carbsG: 30, fatG: 20),
      ];

      final result = computeMacroBreakdown(entries);

      expect(result.proteinPercent, closeTo(0.5, 0.0001));
      expect(result.carbsPercent, closeTo(0.3, 0.0001));
      expect(result.fatPercent, closeTo(0.2, 0.0001));
    });

    test('returns zeroed breakdown for an empty list', () {
      final result = computeMacroBreakdown(
        const <({double proteinG, double carbsG, double fatG})>[],
      );

      expect(result.proteinG, 0);
      expect(result.carbsG, 0);
      expect(result.fatG, 0);
      expect(result.proteinPercent, 0);
    });
  });
}
