import '../../../../core/entities/logged_quantity.dart';

/// Converts between a [LoggedQuantity] and a raw serving multiplier.
class LoggedQuantityConverter {
  /// Converts a user-selected quantity to a serving multiplier.
  static double toServingMultiplier(
    LoggedQuantity loggedQuantity, {
    required double? servingSize,
    required String? servingUnit,
  }) {
    final amount = loggedQuantity.amount;
    final unit = loggedQuantity.unit;

    if (unit == 'serving') {
      return amount;
    }

    if (servingUnit != null && unit == servingUnit) {
      final size = servingSize ?? 1.0;
      return size == 0.0 ? 0.0 : amount / size;
    }

    return amount;
  }

  /// Converts a serving multiplier back to a friendly [LoggedQuantity].
  ///
  /// [knownUnit] is the actual unit the user picked, when it was persisted
  /// (`food_log.quantity_unit` / `recipe_ingredients.quantity_unit`). It's
  /// the only way to tell "0.5" (servings) apart from "50" (grams, on a
  /// 100g-serving food) when both units are legitimately available —
  /// without it, this always assumed [servingUnit], which silently
  /// mislabeled entries logged in plain servings. Null for legacy rows
  /// logged before that column existed, which fall back to the old
  /// assume-servingUnit-if-known behavior.
  static LoggedQuantity fromServingMultiplier(
    double multiplier, {
    required double? servingSize,
    required String? servingUnit,
    String? knownUnit,
  }) {
    final unit =
        knownUnit ??
        (servingUnit != null && servingSize != null && servingSize > 0
            ? servingUnit
            : 'serving');

    if (unit == 'serving') {
      return LoggedQuantity(amount: multiplier, unit: 'serving');
    }

    final size = servingSize ?? 1.0;
    return LoggedQuantity(amount: multiplier * size, unit: unit);
  }

  /// Returns the list of units the user can choose from.
  static List<String> getAvailableUnits({
    required double? servingSize,
    required String? servingUnit,
  }) {
    final units = <String>['serving'];
    if (servingUnit != null && servingUnit.isNotEmpty) {
      units.add(servingUnit);
    }
    return units;
  }
}
