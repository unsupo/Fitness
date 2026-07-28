/// Aggregate protein/carbs/fat grams over some date range, plus each macro's
/// share of total grams (not calories) for the donut chart legend.
class MacroBreakdown {
  const MacroBreakdown({
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;

  double get _totalG => proteinG + carbsG + fatG;

  /// Share of total grams contributed by protein, in the range `0.0-1.0`.
  /// `0` when there are no grams logged at all (avoids a divide-by-zero).
  double get proteinPercent => _totalG == 0 ? 0 : proteinG / _totalG;

  double get carbsPercent => _totalG == 0 ? 0 : carbsG / _totalG;

  double get fatPercent => _totalG == 0 ? 0 : fatG / _totalG;
}
