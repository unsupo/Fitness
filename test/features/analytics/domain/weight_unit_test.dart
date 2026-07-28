import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/use_cases/weight_unit.dart';

void main() {
  group('kg <-> lb conversion', () {
    test('kgToLb converts correctly', () {
      expect(kgToLb(1), closeTo(2.20462, 0.0001));
      expect(kgToLb(80), closeTo(176.37, 0.01));
    });

    test('lbToKg converts correctly', () {
      expect(lbToKg(2.20462), closeTo(1, 0.0001));
      expect(lbToKg(176.37), closeTo(80, 0.01));
    });

    test('round trip is stable', () {
      expect(lbToKg(kgToLb(72.5)), closeTo(72.5, 0.0001));
    });
  });

  group('displayWeight / parseDisplayWeight', () {
    test('displayWeight converts a stored kg value to the given unit', () {
      expect(displayWeight(80, unit: 'kg'), 80);
      expect(displayWeight(80, unit: 'lb'), closeTo(176.37, 0.01));
    });

    test('parseDisplayWeight converts a user-entered value back to kg', () {
      expect(parseDisplayWeight(80, unit: 'kg'), 80);
      expect(parseDisplayWeight(176.37, unit: 'lb'), closeTo(80, 0.01));
    });
  });

  group('formatNumberForDisplay', () {
    test('trims a whole number to no decimal places', () {
      expect(formatNumberForDisplay(80), '80');
    });

    test('rounds messy floating-point conversions to 2 decimal places', () {
      expect(formatNumberForDisplay(187.39292285714595), '187.39');
    });

    test('trims a trailing zero after rounding', () {
      expect(formatNumberForDisplay(176.30), '176.3');
    });
  });
}
