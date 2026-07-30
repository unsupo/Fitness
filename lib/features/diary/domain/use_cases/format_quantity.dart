import '../entities/diary_entry.dart';

/// A human-readable description of how much was logged.
String formatQuantity(DiaryEntry entry) {
  final loggedQty = entry.quantity;

  if (loggedQty.unit == 'serving') {
    if (entry.servingSize != null && entry.servingUnit != null) {
      final units = loggedQty.amount * entry.servingSize!;
      return '${_formatNumber(units)} ${entry.servingUnit}';
    }
    final isWhole = loggedQty.amount == loggedQty.amount.roundToDouble();
    if (isWhole) return '${loggedQty.amount.round()}x';
    return '${_formatNumber(loggedQty.amount)}x';
  }

  return '${_formatNumber(loggedQty.amount)} ${loggedQty.unit}';
}

String _formatNumber(double value) {
  final isWhole = value == value.roundToDouble();
  if (isWhole) return value.round().toString();
  return ((value * 10).round() / 10).toString();
}
