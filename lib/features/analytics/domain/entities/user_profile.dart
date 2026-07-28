/// Biometric profile + weight goal — the inputs needed to estimate TDEE
/// (Mifflin-St Jeor) and project a weight trajectory. All fields are
/// optional because the single `daily_goals` row starts out without them;
/// the projection graph prompts the user to fill these in.
class UserProfile {
  const UserProfile({
    this.sex,
    this.age,
    this.heightCm,
    this.activityLevel,
    this.targetWeightKg,
    this.unitSystem = 'metric',
  });

  /// 'male' or 'female'.
  final String? sex;
  final int? age;
  final double? heightCm;

  /// One of: sedentary, light, moderate, active, extra_active.
  final String? activityLevel;
  final double? targetWeightKg;

  /// Display/input unit system — 'metric' (kg, cm) or 'us' (lb, ft+in).
  /// Weight and height are always stored/computed in kg/cm; this only
  /// affects what the UI shows and accepts.
  final String unitSystem;

  /// Enough to estimate TDEE — doesn't require [targetWeightKg], which only
  /// matters once you're projecting a trajectory *to* a target.
  bool get isCompleteForTdee =>
      sex != null && age != null && heightCm != null && activityLevel != null;

  /// Enough for the full weight-trajectory projection (TDEE inputs + a
  /// target to project toward).
  bool get isCompleteForProjection =>
      isCompleteForTdee && targetWeightKg != null;
}
