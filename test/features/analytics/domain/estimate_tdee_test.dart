import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';
import 'package:arndt_fitness/features/analytics/domain/use_cases/estimate_tdee.dart';

void main() {
  group('estimateTdee (Mifflin-St Jeor)', () {
    test('male, sedentary', () {
      // BMR = 10*80 + 6.25*180 - 5*30 + 5 = 800 + 1125 - 150 + 5 = 1780
      // TDEE = 1780 * 1.2 = 2136
      final tdee = estimateTdee(
        profile: const UserProfile(
          sex: 'male',
          age: 30,
          heightCm: 180,
          activityLevel: 'sedentary',
        ),
        weightKg: 80,
      );
      expect(tdee, closeTo(2136, 0.5));
    });

    test('female, moderate activity', () {
      // BMR = 10*65 + 6.25*165 - 5*28 - 161 = 650 + 1031.25 - 140 - 161 = 1380.25
      // TDEE = 1380.25 * 1.55 = 2139.3875
      final tdee = estimateTdee(
        profile: const UserProfile(
          sex: 'female',
          age: 28,
          heightCm: 165,
          activityLevel: 'moderate',
        ),
        weightKg: 65,
      );
      expect(tdee, closeTo(2139.39, 0.1));
    });

    test('throws if the profile is incomplete', () {
      expect(
        () => estimateTdee(
          profile: const UserProfile(sex: 'male'),
          weightKg: 80,
        ),
        throwsStateError,
      );
    });
  });
}
