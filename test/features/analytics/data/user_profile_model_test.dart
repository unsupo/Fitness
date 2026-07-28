import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/data/models/user_profile_model.dart';
import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';

void main() {
  test('fromJson maps a complete daily_goals profile row', () {
    final profile = UserProfileModel.fromJson({
      'target_weight_kg': '75.0',
      'sex': 'male',
      'age': 30,
      'height_cm': '180.0',
      'activity_level': 'moderate',
      'unit_system': 'us',
    });

    expect(profile.targetWeightKg, 75.0);
    expect(profile.sex, 'male');
    expect(profile.age, 30);
    expect(profile.heightCm, 180.0);
    expect(profile.activityLevel, 'moderate');
    expect(profile.unitSystem, 'us');
    expect(profile.isCompleteForProjection, isTrue);
  });

  test('fromJson tolerates all-null columns (profile not set up yet), defaulting unit_system to metric', () {
    final profile = UserProfileModel.fromJson({
      'target_weight_kg': null,
      'sex': null,
      'age': null,
      'height_cm': null,
      'activity_level': null,
      'unit_system': null,
    });

    expect(profile.isCompleteForProjection, isFalse);
    expect(profile.targetWeightKg, isNull);
    expect(profile.unitSystem, 'metric');
  });

  test('toUpdateJson writes every field from the full profile, nulls included', () {
    const profile = UserProfile(
      targetWeightKg: 72,
      sex: 'female',
      age: null,
      heightCm: null,
      activityLevel: null,
      unitSystem: 'us',
    );

    final json = UserProfileModel.toUpdateJson(profile);

    expect(json, {
      'target_weight_kg': 72.0,
      'sex': 'female',
      'age': null,
      'height_cm': null,
      'activity_level': null,
      'unit_system': 'us',
    });
  });
}
