import 'package:arndt_fitness/features/workouts/presentation/controllers/workout_repository_provider.dart';
import 'package:arndt_fitness/features/workouts/presentation/pages/log_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_workout_repository.dart';

void main() {
  group('LogTab', () {
    testWidgets('idle state shows the last workout summary and Start Workout button', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: Scaffold(body: LogTab())),
        ),
      );
      await tester.pumpAndSettle();

      // Most recent default session (id 1, 2026-07-20) has Bench Press then
      // Squat sets — distinct machine names, first-seen order.
      expect(find.textContaining('Bench Press, Squat'), findsOneWidget);
      expect(find.text('Start Workout'), findsOneWidget);
      expect(find.text('Add Exercise'), findsNothing);
    });

    testWidgets('idle state shows "No workouts yet" when there is no history', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository(
        sessions: const [],
        setsBySession: const {},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: Scaffold(body: LogTab())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No workouts yet'), findsOneWidget);
      expect(find.text('Start Workout'), findsOneWidget);
    });

    testWidgets('tapping Start Workout calls startSession and shows the active session', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: Scaffold(body: LogTab())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();

      expect(fake.lastStartSessionCall, isNotNull);
      expect(find.text('Add Exercise'), findsOneWidget);
      expect(find.text('Finish Workout'), findsOneWidget);
      expect(find.text('Start Workout'), findsNothing);
    });

    testWidgets(
      'adding an exercise then logging a set calls logSet with the right '
      'sessionId/machineId/setNumber and shows the new set',
      (tester) async {
        final fake = FakeWorkoutRepository();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
            child: const MaterialApp(home: Scaffold(body: LogTab())),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Workout'));
        await tester.pumpAndSettle();
        final startedSession = fake.sessions.first;

        await tester.tap(find.text('Add Exercise'));
        await tester.pumpAndSettle();

        // Bottom sheet lists the canned machines; Bench Press is a strength
        // machine (muscleGroup 'chest').
        await tester.tap(find.text('Bench Press').last);
        await tester.pumpAndSettle();

        // The exercise card is now showing with its inline add-set form.
        expect(find.text('Bench Press'), findsOneWidget);
        const benchPressId = 1;
        expect(
          find.byKey(const Key('weight-field-$benchPressId')),
          findsOneWidget,
        );

        await tester.enterText(
          find.byKey(const Key('weight-field-$benchPressId')),
          '135',
        );
        await tester.enterText(
          find.byKey(const Key('reps-field-$benchPressId')),
          '8',
        );
        await tester.tap(find.byKey(const Key('add-set-button-$benchPressId')));
        await tester.pumpAndSettle();

        expect(fake.lastLogSetCall, isNotNull);
        expect(fake.lastLogSetCall!.sessionId, startedSession.id);
        expect(fake.lastLogSetCall!.machineId, benchPressId);
        expect(fake.lastLogSetCall!.setNumber, 1);
        expect(fake.lastLogSetCall!.weight, 135);
        expect(fake.lastLogSetCall!.reps, 8);

        expect(find.textContaining('135'), findsWidgets);
      },
    );

    testWidgets('tapping Finish Workout returns to the idle state', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: Scaffold(body: LogTab())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Start Workout'));
      await tester.pumpAndSettle();
      expect(find.text('Finish Workout'), findsOneWidget);

      await tester.tap(find.text('Finish Workout'));
      await tester.pumpAndSettle();

      expect(find.text('Start Workout'), findsOneWidget);
      expect(find.text('Finish Workout'), findsNothing);
    });
  });
}
