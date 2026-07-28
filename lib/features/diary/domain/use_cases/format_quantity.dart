import '../entities/diary_entry.dart';

/// A human-readable description of how much was logged.
///
/// `quantity` on a [DiaryEntry] is a serving *multiplier* (e.g. `0.5` for
/// half a serving), not a raw unit count — showing "1x" for someone who ate
/// 14 Pringles (1 serving of a 14-crisp serving size) is technically
/// correct but reads as meaningless. When the underlying food's serving
/// size/unit is known, show the real amount instead: "14 crisps",
/// "7 crisps" for half. Falls back to "Nx" for recipe-based entries (no
/// single serving unit) or foods with no recorded serving size.
String formatQuantity(DiaryEntry entry) {
  if (entry.servingSize != null && entry.servingUnit != null) {
    final units = entry.quantity * entry.servingSize!;
    return '${_formatNumber(units)} ${entry.servingUnit}';
  }

  final isWhole = entry.quantity == entry.quantity.roundToDouble();
  if (isWhole) return '${entry.quantity.round()}x';
  return '${_formatNumber(entry.quantity)}x';
}

String _formatNumber(double value) {
  final isWhole = value == value.roundToDouble();
  if (isWhole) return value.round().toString();
  return ((value * 10).round() / 10).toString();
}
