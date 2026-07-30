import '../entities/diary_entry.dart';

/// A human-readable description of how much was logged.
String formatQuantity(DiaryEntry entry) {
  final loggedQty = entry.quantity;

  if (loggedQty.unit == 'serving') {
    if (entry.servingSize != null && entry.servingUnit != null) {
      final units = loggedQty.amount * entry.servingSize!;
      return '${formatAmount(units)} ${entry.servingUnit}';
    }
    final isWhole = loggedQty.amount == loggedQty.amount.roundToDouble();
    if (isWhole) return '${loggedQty.amount.round()}x';
    return '${formatAmount(loggedQty.amount)}x';
  }

  return '${formatAmount(loggedQty.amount)} ${loggedQty.unit}';
}

/// Trims a whole number to "2" instead of "2.0", and rounds a messy
/// floating-point amount (e.g. from a serving-size conversion) to one
/// decimal place — shared with any inline-editable quantity field that
/// needs to seed its initial text from a raw `double`.
String formatAmount(double value) {
  final isWhole = value == value.roundToDouble();
  if (isWhole) return value.round().toString();
  return ((value * 10).round() / 10).toString();
}
