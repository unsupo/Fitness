/// Height is always stored/computed in cm internally (Mifflin-St Jeor takes
/// cm). These conversions exist solely for display/input at the UI
/// boundary, when the user's unit system preference is 'us'.
const _cmPerInch = 2.54;

/// Splits a cm height into whole feet + remaining inches (0-11.99...).
({int feet, double inches}) cmToFeetInches(double cm) {
  final totalInches = cm / _cmPerInch;
  final feet = (totalInches / 12).floor();
  final inches = totalInches - feet * 12;
  return (feet: feet, inches: inches);
}

double feetInchesToCm({required int feet, required double inches}) =>
    (feet * 12 + inches) * _cmPerInch;
