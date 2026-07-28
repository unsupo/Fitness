import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/use_cases/height_unit.dart';

void main() {
  group('cm <-> feet/inches conversion', () {
    test('cmToFeetInches converts correctly', () {
      // 180 cm = 70.866... in = 5 ft 10.87 in
      final result = cmToFeetInches(180);
      expect(result.feet, 5);
      expect(result.inches, closeTo(10.87, 0.01));
    });

    test('feetInchesToCm converts correctly', () {
      expect(feetInchesToCm(feet: 5, inches: 11), closeTo(180.34, 0.01));
    });

    test('round trip is stable', () {
      final result = cmToFeetInches(175);
      final cm = feetInchesToCm(feet: result.feet, inches: result.inches);
      expect(cm, closeTo(175, 0.01));
    });
  });
}
