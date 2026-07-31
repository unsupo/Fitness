import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/use_cases/macro_calorie_split.dart';

/// A donut chart of the three macros' share of [DailyGoals.calorieGoal] —
/// slice angles are each macro's kcal contribution (protein/carbs at 4
/// kcal/g, fat at 9 kcal/g) as a fraction of the fixed total, so the whole
/// ring always represents the calorie goal itself, not an independent 100%.
///
/// Draggable: touching anywhere and dragging moves whichever of the three
/// slice boundaries is angularly nearest to the touch, transferring kcal
/// between the two slices that boundary separates (converted back to grams
/// via [macroGramsFromCalorieSplit]) while the third slice and the total
/// stay fixed — see [adjustMacroSliceBoundary].
class AdjustableMacroPieChart extends StatefulWidget {
  const AdjustableMacroPieChart({
    super.key,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.onChanged,
    this.size = 220,
  });

  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Called continuously during a drag with the updated grams (protein and
  /// carbs, or carbs and fat, or fat and protein change together; the third
  /// is always passed through unchanged).
  final void Function({
    required double proteinG,
    required double carbsG,
    required double fatG,
  })
  onChanged;

  final double size;

  @override
  State<AdjustableMacroPieChart> createState() =>
      _AdjustableMacroPieChartState();
}

class _AdjustableMacroPieChartState extends State<AdjustableMacroPieChart> {
  MacroSliceBoundary? _draggingBoundary;

  MacroCalorieSplit get _split => macroCalorieSplitFromGrams(
    proteinG: widget.proteinG,
    carbsG: widget.carbsG,
    fatG: widget.fatG,
  );

  /// This boundary's angle, in radians clockwise from 12 o'clock — matches
  /// [_touchAngle]'s convention so the two are directly comparable.
  double _angleFor(MacroSliceBoundary boundary) {
    final split = _split;
    switch (boundary) {
      case MacroSliceBoundary.proteinCarbs:
        return split.proteinFraction * 2 * pi;
      case MacroSliceBoundary.carbsFat:
        return (split.proteinFraction + split.carbsFraction) * 2 * pi;
      case MacroSliceBoundary.fatProtein:
        return 0;
    }
  }

  double _touchAngle(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final vector = localPosition - center;
    var angle = atan2(vector.dx, -vector.dy);
    if (angle < 0) angle += 2 * pi;
    return angle;
  }

  /// Shortest signed angular distance from [a] to [b], in `(-π, π]`.
  double _angleDelta(double a, double b) {
    var delta = (b - a) % (2 * pi);
    if (delta > pi) delta -= 2 * pi;
    if (delta < -pi) delta += 2 * pi;
    return delta;
  }

  MacroSliceBoundary _nearestBoundary(double touchAngle) {
    return MacroSliceBoundary.values.reduce((a, b) {
      final distA = _angleDelta(_angleFor(a), touchAngle).abs();
      final distB = _angleDelta(_angleFor(b), touchAngle).abs();
      return distA <= distB ? a : b;
    });
  }

  void _handleDrag(Offset localPosition, Size size) {
    final touchAngle = _touchAngle(localPosition, size);
    final boundary = _draggingBoundary ??= _nearestBoundary(touchAngle);

    final deltaAngle = _angleDelta(_angleFor(boundary), touchAngle);
    final deltaKcal = deltaAngle / (2 * pi) * _split.totalKcal;

    final updated = adjustMacroSliceBoundary(_split, boundary, deltaKcal);
    final grams = macroGramsFromCalorieSplit(updated);
    widget.onChanged(
      proteinG: grams.proteinG,
      carbsG: grams.carbsG,
      fatG: grams.fatG,
    );
  }

  @override
  Widget build(BuildContext context) {
    final split = _split;
    final size = Size(widget.size, widget.size);

    // Listener (raw pointer events) rather than GestureDetector's onPan* —
    // this widget is typically hosted inside a scrollable dialog, and a
    // PanGestureRecognizer there loses the gesture arena to the ancestor
    // Scrollable's own drag recognizer for any touch with a vertical
    // component. Listener bypasses the arena entirely, so dragging the pie
    // always wins over scrolling the dialog behind it.
    return Listener(
      onPointerDown: (event) => _draggingBoundary = _nearestBoundary(
        _touchAngle(event.localPosition, size),
      ),
      onPointerMove: (event) => _handleDrag(event.localPosition, size),
      onPointerUp: (_) => _draggingBoundary = null,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: CustomPaint(
          painter: _MacroPiePainter(split: split),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${split.totalKcal.round()}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text(
                  'cal',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MacroPiePainter extends CustomPainter {
  _MacroPiePainter({required this.split});

  final MacroCalorieSplit split;

  static const _strokeWidth = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;
    final rect = Rect.fromCircle(
      center: center,
      radius: radius - _strokeWidth / 2,
    );

    void drawArc(double startFraction, double sweepFraction, Color color) {
      if (sweepFraction <= 0) return;
      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth;
      canvas.drawArc(
        rect,
        -pi / 2 + startFraction * 2 * pi,
        sweepFraction * 2 * pi,
        false,
        paint,
      );
    }

    drawArc(0, split.proteinFraction, AppColors.proteinRing);
    drawArc(split.proteinFraction, split.carbsFraction, AppColors.carbsRing);
    drawArc(
      split.proteinFraction + split.carbsFraction,
      split.fatFraction,
      AppColors.fatRing,
    );
  }

  @override
  bool shouldRepaint(covariant _MacroPiePainter oldDelegate) =>
      oldDelegate.split.proteinKcal != split.proteinKcal ||
      oldDelegate.split.carbsKcal != split.carbsKcal ||
      oldDelegate.split.fatKcal != split.fatKcal;
}
