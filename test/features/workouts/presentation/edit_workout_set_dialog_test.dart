import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/presentation/controllers/workout_repository_provider.dart';
import 'package:arndt_fitness/features/workouts/presentation/widgets/edit_workout_set_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes/fake_workout_repository.dart';

void main() {
  WorkoutSet strengthSet({String? notes}) => WorkoutSet(
    id: 1,
    loggedAt: DateTime(2026, 7, 20, 9, 0),
    machineId: 1,
    machineName: 'Bench Press',
    sessionId: 1,
    setNumber: 1,
    weight: 135,
    reps: 8,
    unit: 'lb',
    notes: notes,
  );

  Future<FakeWorkoutRepository> pumpDialog(
    WidgetTester tester,
    WorkoutSet set,
  ) async {
    final fake = FakeWorkoutRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () => showEditWorkoutSetDialog(
                context,
                ref,
                set,
                onChanged: () {},
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('pre-fills the notes field from the set\'s existing notes', (
    tester,
  ) async {
    await pumpDialog(tester, strengthSet(notes: 'Took everything I had'));

    final notesField = tester.widget<TextField>(
      find.byKey(const Key('edit-set-notes-field')),
    );
    expect(notesField.controller!.text, 'Took everything I had');
  });

  testWidgets('leaves the notes field blank when the set has no notes', (
    tester,
  ) async {
    await pumpDialog(tester, strengthSet());

    final notesField = tester.widget<TextField>(
      find.byKey(const Key('edit-set-notes-field')),
    );
    expect(notesField.controller!.text, '');
  });

  testWidgets('saving with edited notes calls updateSet with the new notes', (
    tester,
  ) async {
    final fake = await pumpDialog(tester, strengthSet(notes: 'Old note'));

    await tester.enterText(
      find.byKey(const Key('edit-set-notes-field')),
      'New note',
    );
    await tester.tap(find.byKey(const Key('save-set-button')));
    await tester.pumpAndSettle();

    expect(fake.lastUpdateSetCall?.notes, 'New note');
  });

  testWidgets(
    'saving with an empty notes field clears a previously-set note',
    (tester) async {
      final fake = await pumpDialog(tester, strengthSet(notes: 'Old note'));

      await tester.enterText(
        find.byKey(const Key('edit-set-notes-field')),
        '',
      );
      await tester.tap(find.byKey(const Key('save-set-button')));
      await tester.pumpAndSettle();

      expect(fake.lastUpdateSetCall?.notes, isNull);
    },
  );
}
