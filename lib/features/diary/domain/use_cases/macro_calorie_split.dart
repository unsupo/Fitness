/// Standard Atwater factors — calories per gram for each macronutrient.
const kcalPerGramProtein = 4.0;
const kcalPerGramCarbs = 4.0;
const kcalPerGramFat = 9.0;

/// Each macro's calorie contribution. The three always sum to the fixed
/// calorie total a macro pie chart represents — resizing one slice (via
/// [adjustMacroSliceBoundary]) always borrows from/gives to its neighbor,
/// never changes the total.
class MacroCalorieSplit {
  const MacroCalorieSplit({
    required this.proteinKcal,
    required this.carbsKcal,
    required this.fatKcal,
  });

  final double proteinKcal;
  final double carbsKcal;
  final double fatKcal;

  double get totalKcal => proteinKcal + carbsKcal + fatKcal;

  /// Share of [totalKcal], in `0.0-1.0` — the pie chart's slice angles are
  /// `fraction * 2π`. `0` for all three when the total is `0` (avoids a
  /// divide-by-zero rather than throwing).
  double get proteinFraction => totalKcal == 0 ? 0 : proteinKcal / totalKcal;
  double get carbsFraction => totalKcal == 0 ? 0 : carbsKcal / totalKcal;
  double get fatFraction => totalKcal == 0 ? 0 : fatKcal / totalKcal;
}

MacroCalorieSplit macroCalorieSplitFromGrams({
  required double proteinG,
  required double carbsG,
  required double fatG,
}) => MacroCalorieSplit(
  proteinKcal: proteinG * kcalPerGramProtein,
  carbsKcal: carbsG * kcalPerGramCarbs,
  fatKcal: fatG * kcalPerGramFat,
);

({double proteinG, double carbsG, double fatG}) macroGramsFromCalorieSplit(
  MacroCalorieSplit split,
) => (
  proteinG: split.proteinKcal / kcalPerGramProtein,
  carbsG: split.carbsKcal / kcalPerGramCarbs,
  fatG: split.fatKcal / kcalPerGramFat,
);

/// The three draggable boundaries of a 3-slice macro pie chart, named
/// `xY` for "the edge between slice x and slice y, going clockwise from
/// x to y".
enum MacroSliceBoundary { proteinCarbs, carbsFat, fatProtein }

/// The smallest share of the total any single slice may hold. Without a
/// floor, a slice dragged down to literal zero collapses its two
/// boundaries onto the same angle — indistinguishable to touch, and
/// impossible to grab and drag back out. Keeping a real minimum sliver
/// means every boundary is always a real, separately-selectable target.
const minSliceFraction = 0.05;

/// Moves one boundary of the pie by [deltaKcal], transferring calories
/// between exactly the two slices that boundary separates — the third
/// slice, and the pie's total, are always left untouched. Positive
/// [deltaKcal] grows the first-named slice at the second-named slice's
/// expense (e.g. for [MacroSliceBoundary.proteinCarbs], positive moves
/// kcal from carbs to protein); negative does the reverse. Clamped at
/// [minSliceFraction] of the total, not zero — see there for why. A slice
/// that starts out already below the floor (stale/imported data) can
/// still be grown back out; it just can't be shrunk further.
MacroCalorieSplit adjustMacroSliceBoundary(
  MacroCalorieSplit current,
  MacroSliceBoundary boundary,
  double deltaKcal,
) {
  final floor = current.totalKcal * minSliceFraction;
  double lowerBound(double giving) => -(giving - floor).clamp(0.0, double.infinity);
  double upperBound(double giving) => (giving - floor).clamp(0.0, double.infinity);

  switch (boundary) {
    case MacroSliceBoundary.proteinCarbs:
      final clamped = deltaKcal.clamp(
        lowerBound(current.proteinKcal),
        upperBound(current.carbsKcal),
      );
      return MacroCalorieSplit(
        proteinKcal: current.proteinKcal + clamped,
        carbsKcal: current.carbsKcal - clamped,
        fatKcal: current.fatKcal,
      );
    case MacroSliceBoundary.carbsFat:
      final clamped = deltaKcal.clamp(
        lowerBound(current.carbsKcal),
        upperBound(current.fatKcal),
      );
      return MacroCalorieSplit(
        proteinKcal: current.proteinKcal,
        carbsKcal: current.carbsKcal + clamped,
        fatKcal: current.fatKcal - clamped,
      );
    case MacroSliceBoundary.fatProtein:
      final clamped = deltaKcal.clamp(
        lowerBound(current.fatKcal),
        upperBound(current.proteinKcal),
      );
      return MacroCalorieSplit(
        proteinKcal: current.proteinKcal - clamped,
        carbsKcal: current.carbsKcal,
        fatKcal: current.fatKcal + clamped,
      );
  }
}
