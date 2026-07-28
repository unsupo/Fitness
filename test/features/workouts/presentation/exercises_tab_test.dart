import 'package:arndt_fitness/features/workouts/domain/entities/machine.dart';
import 'package:arndt_fitness/features/workouts/presentation/controllers/workout_repository_provider.dart';
import 'package:arndt_fitness/features/workouts/presentation/pages/exercises_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_workout_repository.dart';

const _fixtureMachines = <Machine>[
  Machine(
    id: 1,
    name: 'Bench Press',
    aliases: ['Chest Press'],
    muscleGroup: 'chest',
  ),
  Machine(
    id: 2,
    name: 'Incline Press',
    aliases: ['Incline Bench'],
    muscleGroup: 'chest',
  ),
  Machine(id: 3, name: 'Squat', aliases: ['Barbell Squat'], muscleGroup: 'legs'),
  Machine(id: 4, name: 'Treadmill', aliases: ['Cardio Run']),
];

Future<void> _pumpTab(WidgetTester tester, FakeWorkoutRepository fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
      child: const MaterialApp(home: Scaffold(body: ExercisesTab())),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ExercisesTab', () {
    testWidgets('groups machines by muscle group, titled and with an Other '
        'group for null muscleGroup', (tester) async {
      final fake = FakeWorkoutRepository(machines: _fixtureMachines);

      await _pumpTab(tester, fake);

      expect(find.text('Chest'), findsOneWidget);
      expect(find.text('Legs'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);

      expect(find.text('Bench Press'), findsOneWidget);
      expect(find.text('Incline Press'), findsOneWidget);
      expect(find.text('Squat'), findsOneWidget);
      expect(find.text('Treadmill'), findsOneWidget);
    });

    testWidgets('search filters by alias even when the name does not match', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository(machines: _fixtureMachines);

      await _pumpTab(tester, fake);

      await tester.enterText(find.byType(TextField), 'Cardio Run');
      await tester.pumpAndSettle();

      expect(find.text('Treadmill'), findsOneWidget);
      expect(find.text('Bench Press'), findsNothing);
      expect(find.text('Incline Press'), findsNothing);
      expect(find.text('Squat'), findsNothing);
    });

    testWidgets('shows a friendly empty state when there are no machines at '
        'all', (tester) async {
      final fake = FakeWorkoutRepository(machines: const []);

      await _pumpTab(tester, fake);

      expect(find.text('No exercises yet'), findsOneWidget);
    });

    testWidgets('pulling to refresh re-fetches the machine list', (
      tester,
    ) async {
      final fake = FakeWorkoutRepository(machines: _fixtureMachines);

      await _pumpTab(tester, fake);

      final callsBefore = fake.getMachinesCallCount;
      expect(callsBefore, greaterThan(0));

      await tester.fling(find.byType(ListView), const Offset(0, 300), 1000);
      await tester.pumpAndSettle();

      expect(fake.getMachinesCallCount, greaterThan(callsBefore));
    });
  });
}
