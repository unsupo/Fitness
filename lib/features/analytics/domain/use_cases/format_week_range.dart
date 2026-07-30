import 'package:intl/intl.dart';

/// "Jul 27-2" (same month) or "Jul 27 - Aug 2" (spanning months) for the
/// 7-day window starting at [weekStart]. Shared by every section on Trends
/// that needs to show which week's data it's summarizing — sections that
/// aggregate over the whole week (like Macro Breakdown) must say so
/// explicitly, or a per-day dip/spike reads as "wrong" when it's actually
/// just diluted by the rest of the week.
String formatWeekRange(DateTime weekStart) {
  final weekEnd = weekStart.add(const Duration(days: 6));
  return weekStart.month == weekEnd.month
      ? '${DateFormat('MMM d').format(weekStart)}-${DateFormat('d').format(weekEnd)}'
      : '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';
}
