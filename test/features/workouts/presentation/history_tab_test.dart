import 'package:arndt_fitness/features/workouts/presentation/controllers/workout_repository_provider.dart';
import 'package:arndt_fitness/features/workouts/presentation/pages/history_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../fakes/fake_workout_repository.dart';

void main() {
  group('HistoryTab', () {
    testWidgets('renders each session date and a machine-name summary', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: HistoryTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jul 20, 2026'), findsOneWidget);
      expect(find.text('Jul 15, 2026'), findsOneWidget);
      expect(find.text('Jul 10, 2026'), findsOneWidget);

      // Session 1's sets are Bench Press (x2) then Squat (x1), first-seen
      // order, distinct names only.
      expect(find.text('Bench Press, Squat'), findsOneWidget);
      // Session 2 is a single cardio machine.
      expect(find.text('Treadmill'), findsOneWidget);
    });

    testWidgets('shows an empty state when there are no sessions', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository(sessions: const [], setsBySession: const {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(home: HistoryTab()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No workouts logged yet'), findsOneWidget);
    });

    testWidgets('tapping a session row navigates to its detail route', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository();

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const HistoryTab()),
          GoRoute(
            path: '/workouts/session/:id',
            builder: (context, state) =>
                Scaffold(body: Text('Session ${state.pathParameters['id']}')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jul 20, 2026'));
      await tester.pumpAndSettle();

      expect(find.text('Session 1'), findsOneWidget);
    });
  });
}
