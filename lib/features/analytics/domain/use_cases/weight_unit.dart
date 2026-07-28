/// Weight is always stored/computed in kg internally — every other domain
/// use case (TDEE, trajectory projection) works in kg only. These
/// conversions exist solely for display/input at the UI boundary, keyed by
/// the user's `weight_unit` preference ('kg' or 'lb').
const _kgPerLb = 0.45359237;

double kgToLb(double kg) => kg / _kgPerLb;

double lbToKg(double lb) => lb * _kgPerLb;

/// Converts a stored kg value to the given display [unit].
double displayWeight(double kg, {required String unit}) =>
    unit == 'lb' ? kgToLb(kg) : kg;

/// Converts a user-entered value (in [unit]) back to kg for storage.
double parseDisplayWeight(double value, {required String unit}) =>
    unit == 'lb' ? lbToKg(value) : value;

/// The weight unit ('kg'/'lb') implied by a `UserProfile.unitSystem`
/// ('metric'/'us').
String weightUnitFor(String unitSystem) => unitSystem == 'us' ? 'lb' : 'kg';

/// "80" instead of "80.0", "187.39" instead of "187.39292285714595" — a
/// friendlier display of a unit-converted value than raw
/// `double.toString()`. Shared by every dialog that shows a converted
/// weight/height value.
String formatNumberForDisplay(double value) {
  var text = value.toStringAsFixed(2);
  if (text.contains('.')) {
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
  }
  return text;
}
