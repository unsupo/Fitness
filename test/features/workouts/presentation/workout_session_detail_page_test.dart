import 'package:arndt_fitness/features/workouts/presentation/controllers/workout_repository_provider.dart';
import 'package:arndt_fitness/features/workouts/presentation/pages/workout_session_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_workout_repository.dart';

void main() {
  group('WorkoutSessionDetailPage', () {
    testWidgets('groups sets by machine and renders set details', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: WorkoutSessionDetailPage(sessionId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Session 1 fixture: Bench Press (2 sets) then Squat (1 set).
      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);

      // Set 2 of Bench Press: 145 lb x 6.
      expect(find.textContaining('145'), findsOneWidget);
      expect(find.textContaining('225'), findsOneWidget);

      // Title is the formatted session date.
      expect(find.text('Jul 20, 2026'), findsOneWidget);
    });

    testWidgets('renders cardio set details distinctly from strength sets', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: WorkoutSessionDetailPage(sessionId: 2),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Treadmill'), findsOneWidget);
      expect(find.textContaining('12'), findsOneWidget);
      expect(find.textContaining('5.5'), findsOneWidget);
    });
  });
}
