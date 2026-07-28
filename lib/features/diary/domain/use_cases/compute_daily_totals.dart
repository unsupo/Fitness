import 'package:arndt_fitness/features/diary/domain/entities/daily_totals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';

/// Sums calories/protein/carbs/fat across a list of logged entries.
/// An empty list produces all-zero totals.
DailyTotals computeDailyTotals(List<DiaryEntry> entries) {
  var calories = 0.0;
  var proteinG = 0.0;
  var carbsG = 0.0;
  var fatG = 0.0;

  for (final entry in entries) {
    calories += entry.calories;
    proteinG += entry.proteinG;
    carbsG += entry.carbsG;
    fatG += entry.fatG;
  }

  return DailyTotals(
    calories: calories,
    proteinG: proteinG,
    carbsG: carbsG,
    fatG: fatG,
  );
}
