import '../entities/user_profile.dart';

/// Standard activity-level multipliers applied to BMR to estimate TDEE.
const activityMultipliers = {
  'sedentary': 1.2,
  'light': 1.375,
  'moderate': 1.55,
  'active': 1.725,
  'extra_active': 1.9,
};

/// Estimates Total Daily Energy Expenditure via the Mifflin-St Jeor formula.
/// This is an estimate, not a measurement — real TDEE varies by individual;
/// treat the resulting weight projection as directional, not exact.
double estimateTdee({required UserProfile profile, required double weightKg}) {
  if (!profile.isCompleteForTdee) {
    throw StateError(
      'estimateTdee requires sex, age, heightCm, and activityLevel',
    );
  }

  final bmr = profile.sex == 'male'
      ? 10 * weightKg + 6.25 * profile.heightCm! - 5 * profile.age! + 5
      : 10 * weightKg + 6.25 * profile.heightCm! - 5 * profile.age! - 161;

  final multiplier = activityMultipliers[profile.activityLevel]!;
  return bmr * multiplier;
}
