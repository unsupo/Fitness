import 'package:flutter_test/flutter_test.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/logged_quantity_converter.dart';

void main() {
  group('LoggedQuantityConverter', () {
    test('toServingMultiplier with serving unit returns amount verbatim', () {
      final mult = LoggedQuantityConverter.toServingMultiplier(
        const LoggedQuantity(amount: 1.5, unit: 'serving'),
        servingSize: 100,
        servingUnit: 'g',
      );
      expect(mult, equals(1.5));
    });

    test('toServingMultiplier with custom servingUnit scales by servingSize', () {
      final mult = LoggedQuantityConverter.toServingMultiplier(
        const LoggedQuantity(amount: 50, unit: 'g'),
        servingSize: 100,
        servingUnit: 'g',
      );
      expect(mult, equals(0.5));
    });

    test('fromServingMultiplier with custom servingUnit scales to amount', () {
      final qty = LoggedQuantityConverter.fromServingMultiplier(
        0.5,
        servingSize: 100,
        servingUnit: 'g',
      );
      expect(qty.amount, equals(50.0));
      expect(qty.unit, equals('g'));
    });

    test('fromServingMultiplier fallback when serving size or unit is missing', () {
      final qty = LoggedQuantityConverter.fromServingMultiplier(
        2.0,
        servingSize: null,
        servingUnit: null,
      );
      expect(qty.amount, equals(2.0));
      expect(qty.unit, equals('serving'));
    });

    test(
      'fromServingMultiplier with knownUnit "serving" reconstructs as '
      'servings even when a servingUnit is available — resolves the '
      'otherwise-ambiguous case where both are valid choices',
      () {
        final qty = LoggedQuantityConverter.fromServingMultiplier(
          2.0,
          servingSize: 100,
          servingUnit: 'g',
          knownUnit: 'serving',
        );
        expect(qty.amount, equals(2.0));
        expect(qty.unit, equals('serving'));
      },
    );

    test(
      'fromServingMultiplier with knownUnit matching servingUnit scales to amount',
      () {
        final qty = LoggedQuantityConverter.fromServingMultiplier(
          0.5,
          servingSize: 100,
          servingUnit: 'g',
          knownUnit: 'g',
        );
        expect(qty.amount, equals(50.0));
        expect(qty.unit, equals('g'));
      },
    );

    test('getAvailableUnits includes serving and servingUnit, but not g if non-gram native', () {
      final units = LoggedQuantityConverter.getAvailableUnits(
        servingSize: 14,
        servingUnit: 'crisps',
      );
      expect(units, containsAll(['serving', 'crisps']));
      expect(units, isNot(contains('g')));
    });
  });
}
