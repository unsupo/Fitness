import '../entities/macro_breakdown.dart';

/// Sums protein/carbs/fat grams across `food_log`-shaped entries into one
/// [MacroBreakdown]. An empty list yields a zeroed breakdown.
MacroBreakdown computeMacroBreakdown(
  List<({double proteinG, double carbsG, double fatG})> entries,
) {
  var proteinG = 0.0;
  var carbsG = 0.0;
  var fatG = 0.0;

  for (final entry in entries) {
    proteinG += entry.proteinG;
    carbsG += entry.carbsG;
    fatG += entry.fatG;
  }

  return MacroBreakdown(proteinG: proteinG, carbsG: carbsG, fatG: fatG);
}
