import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/domain/use_cases/generate_overload_recommendation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('generateOverloadRecommendation', () {
    final mockSetKg = WorkoutSet(
      id: 1,
      loggedAt: DateTime.now(),
      machineId: 10,
      machineName: 'Chest Press',
      sessionId: 100,
      setNumber: 1,
      weight: 60.0,
      reps: 8,
      unit: 'kg',
    );

    test('returns null if previousSet is null', () {
      expect(
        generateOverloadRecommendation(previousSet: null, trainingFocus: 'hypertrophy'),
        isNull,
      );
    });

    test('hypertrophy focus: increases reps by 1 if reps < 12', () {
      final rec = generateOverloadRecommendation(
        previousSet: mockSetKg, // 60kg x 8 reps
        trainingFocus: 'hypertrophy',
      );
      expect(rec?.weight, equals(60.0));
      expect(rec?.reps, equals(9));
    });

    test('hypertrophy focus: increases weight and resets reps to 8 if reps >= 12', () {
      final prevSet = WorkoutSet(
        id: 3,
        loggedAt: DateTime.now(),
        machineId: 10,
        machineName: 'Chest Press',
        sessionId: 100,
        setNumber: 1,
        weight: 60.0,
        reps: 12,
        unit: 'kg',
      );
      final rec = generateOverloadRecommendation(
        previousSet: prevSet,
        trainingFocus: 'hypertrophy',
      );
      expect(rec?.weight, equals(62.5));
      expect(rec?.reps, equals(8));
    });

    test('strength focus: increases reps by 1 if reps < 6', () {
      final prevSet = WorkoutSet(
        id: 4,
        loggedAt: DateTime.now(),
        machineId: 10,
        machineName: 'Chest Press',
        sessionId: 100,
        setNumber: 1,
        weight: 100.0,
        reps: 4,
        unit: 'lb',
      );
      final rec = generateOverloadRecommendation(
        previousSet: prevSet,
        trainingFocus: 'strength',
      );
      expect(rec?.weight, equals(100.0));
      expect(rec?.reps, equals(5));
    });

    test('strength focus: increases weight by 5 lbs and resets reps to 3 if reps >= 6', () {
      final prevSet = WorkoutSet(
        id: 5,
        loggedAt: DateTime.now(),
        machineId: 10,
        machineName: 'Chest Press',
        sessionId: 100,
        setNumber: 1,
        weight: 100.0,
        reps: 6,
        unit: 'lb',
      );
      final rec = generateOverloadRecommendation(
        previousSet: prevSet,
        trainingFocus: 'strength',
      );
      expect(rec?.weight, equals(105.0));
      expect(rec?.reps, equals(3));
    });
  });
}
