import '../entities/workout_set.dart';

/// Suggests the target weight and reps to achieve progressive overload
/// based on the training focus and the user's previous set performance.
({double weight, int reps})? generateOverloadRecommendation({
  required WorkoutSet? previousSet,
  required String trainingFocus,
}) {
  if (previousSet == null) return null;
  final prevWeight = previousSet.weight ?? 0.0;
  final prevReps = previousSet.reps ?? 0;

  final isStrength = trainingFocus == 'strength';
  final minReps = isStrength ? 3 : 8;
  final maxReps = isStrength ? 6 : 12;

  // Standard progressive overload increments: 5 lb or 2.5 kg
  final double weightIncrement = previousSet.unit.toLowerCase() == 'lb' ? 5.0 : 2.5;

  if (prevReps >= maxReps) {
    return (
      weight: prevWeight + weightIncrement,
      reps: minReps,
    );
  } else {
    return (
      weight: prevWeight,
      reps: prevReps + 1,
    );
  }
}
