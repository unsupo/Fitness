import 'package:arndt_fitness/features/workouts/domain/entities/machine.dart';
import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/presentation/controllers/workout_repository_provider.dart';
import 'package:arndt_fitness/features/workouts/presentation/pages/exercise_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_workout_repository.dart';

const _machines = <Machine>[
  Machine(id: 1, name: 'Bench Press', muscleGroup: 'chest'),
];

final _fixtureSetsByMachine = <int, List<WorkoutSet>>{
  1: [
    WorkoutSet(
      id: 1,
      loggedAt: DateTime(2026, 7, 1, 9, 0),
      machineId: 1,
      machineName: 'Bench Press',
      sessionId: 10,
      setNumber: 1,
      weight: 100,
      reps: 10,
      unit: 'lb',
    ),
    WorkoutSet(
      id: 2,
      loggedAt: DateTime(2026, 7, 10, 9, 0),
      machineId: 1,
      machineName: 'Bench Press',
      sessionId: 11,
      setNumber: 1,
      weight: 120, // the max-weight set — this one is the PR
      reps: 8,
      unit: 'lb',
    ),
    WorkoutSet(
      id: 3,
      loggedAt: DateTime(2026, 7, 15, 9, 0),
      machineId: 1,
      machineName: 'Bench Press',
      sessionId: 12,
      setNumber: 1,
      weight: 110,
      reps: 12,
      unit: 'lb',
    ),
  ],
};

Future<void> _pumpDetail(
  WidgetTester tester,
  FakeWorkoutRepository fake, {
  int machineId = 1,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(home: ExerciseDetailPage(machineId: machineId)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ExerciseDetailPage', () {
    testWidgets(
      'shows the personal record and every fixture set in the history',
      (tester) async {
        final fake = FakeWorkoutRepository(
          machines: _machines,
          setsBySession: {
            10: [_fixtureSetsByMachine[1]![0]],
            11: [_fixtureSetsByMachine[1]![1]],
            12: [_fixtureSetsByMachine[1]![2]],
          },
        );

        await _pumpDetail(tester, fake);

        // AppBar title is the machine's name.
        expect(find.text('Bench Press'), findsOneWidget);

        // Personal Record section: the max-weight set (120 lb x 8, logged
        // Jul 10) formatted as a single dashed line.
        expect(find.text('Personal Record'), findsOneWidget);
        expect(find.text('120 lb x 8 — Jul 10, 2026'), findsOneWidget);

        // Full history includes every fixture set.
        expect(find.text('100 lb x 10'), findsOneWidget);
        expect(find.text('120 lb x 8'), findsOneWidget);
        expect(find.text('110 lb x 12'), findsOneWidget);
        expect(find.text('Jul 1, 2026'), findsOneWidget);
        expect(find.text('Jul 10, 2026'), findsOneWidget);
        expect(find.text('Jul 15, 2026'), findsOneWidget);
      },
    );

    testWidgets('shows "no PR yet" / "not logged yet" when no sets exist', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository(
        machines: _machines,
        setsBySession: const {},
      );

      await _pumpDetail(tester, fake);

      expect(find.text('No PR yet'), findsOneWidget);
      expect(find.text('Not logged yet'), findsOneWidget);
    });
  });
}
