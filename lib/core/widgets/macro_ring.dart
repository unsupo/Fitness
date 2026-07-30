import 'package:flutter/material.dart';

/// A circular progress indicator with a centered percentage label and a
/// caption underneath — used for the Protein/Carbs/Fat rings on the
/// dashboard. Shared so every feature that needs a macro ring (diary,
/// analytics) instantiates the same widget instead of re-implementing it.
class MacroRing extends StatelessWidget {
  const MacroRing({
    super.key,
    required this.label,
    required this.progress,
    required this.color,
    this.size = 64,
    this.actualGrams,
    this.targetGrams,
  });

  final String label;

  /// 0.0-1.0. Values above 1.0 are clamped for display.
  final double progress;
  final Color color;
  final double size;

  /// When both are given, shown as a "64g / 120g" caption under [label] —
  /// the percent alone doesn't say how much that actually is. Omitted
  /// entirely (no caption) when either is null.
  final double? actualGrams;
  final double? targetGrams;

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: clamped,
                  strokeWidth: 6,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${(clamped * 100).round()}%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        if (actualGrams != null && targetGrams != null)
          Text(
            '${actualGrams!.round()}g / ${targetGrams!.round()}g',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
      ],
    );
  }
}
