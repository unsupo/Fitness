import '../../../../core/network/supabase_json.dart';
import '../../domain/entities/user_profile.dart';

/// Maps the profile/target-weight columns of the single `daily_goals` row.
class UserProfileModel {
  static UserProfile fromJson(Map<String, dynamic> json) {
    double? parseOptionalNum(Object? value) =>
        value == null ? null : parseSupabaseNum(value);

    return UserProfile(
      targetWeightKg: parseOptionalNum(json['target_weight_kg']),
      sex: json['sex'] as String?,
      age: json['age'] as int?,
      heightCm: parseOptionalNum(json['height_cm']),
      activityLevel: json['activity_level'] as String?,
      unitSystem: json['unit_system'] as String? ?? 'metric',
    );
  }

  static Map<String, dynamic> toUpdateJson(UserProfile profile) => {
    'target_weight_kg': profile.targetWeightKg,
    'sex': profile.sex,
    'age': profile.age,
    'height_cm': profile.heightCm,
    'activity_level': profile.activityLevel,
    'unit_system': profile.unitSystem,
  };
}
