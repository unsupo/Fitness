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
  });

  final String label;

  /// 0.0-1.0. Values above 1.0 are clamped for display.
  final double progress;
  final Color color;
  final double size;

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
      ],
    );
  }
}
