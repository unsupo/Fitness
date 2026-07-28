import 'package:arndt_fitness/features/workouts/domain/entities/machine.dart';
import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/presentation/widgets/log_exercise_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _benchPress = Machine(id: 1, name: 'Bench Press', muscleGroup: 'chest');
const _treadmill = Machine(id: 2, name: 'Treadmill', muscleGroup: 'cardio');

WorkoutSet _strengthSet({
  required int id,
  required int sessionId,
  required int setNumber,
  required DateTime loggedAt,
  double? weight,
  int? reps,
}) {
  return WorkoutSet(
    id: id,
    loggedAt: loggedAt,
    machineId: _benchPress.id,
    machineName: _benchPress.name,
    sessionId: sessionId,
    setNumber: setNumber,
    weight: weight,
    reps: reps,
  );
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('LogExerciseCard', () {
    testWidgets(
      'shows one row per persisted set, pre-filled with its own values, '
      'plus one trailing blank row',
      (tester) async {
        final sets = [
          _strengthSet(
            id: 1,
            sessionId: 99,
            setNumber: 1,
            loggedAt: DateTime(2026, 7, 27),
            weight: 135,
            reps: 8,
          ),
        ];

        await tester.pumpWidget(
          _wrap(
            LogExerciseCard(
              machine: _benchPress,
              sets: sets,
              history: const [],
              currentSessionId: 99,
              onConfirmSet: (_, _) {},
              onDeleteSet: (_) {},
            ),
          ),
        );

        // Persisted row 1 pre-filled.
        expect(
          tester
              .widget<TextField>(
                find.byKey(const Key('weight-field-1-1')),
              )
              .controller!
              .text,
          '135',
        );
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('reps-field-1-1')))
              .controller!
              .text,
          '8',
        );
        // Trailing blank row 2, empty.
        expect(find.byKey(const Key('weight-field-1-2')), findsOneWidget);
        expect(
          tester
              .widget<TextField>(
                find.byKey(const Key('weight-field-1-2')),
              )
              .controller!
              .text,
          '',
        );
      },
    );

    testWidgets(
      'shows the previous session\'s value for the same set number as a hint',
      (tester) async {
        final history = [
          _strengthSet(
            id: 10,
            sessionId: 1,
            setNumber: 1,
            loggedAt: DateTime(2026, 7, 20),
            weight: 130,
            reps: 10,
          ),
        ];

        await tester.pumpWidget(
          _wrap(
            LogExerciseCard(
              machine: _benchPress,
              sets: const [],
              history: history,
              currentSessionId: 99,
              onConfirmSet: (_, _) {},
              onDeleteSet: (_) {},
            ),
          ),
        );

        // Previous-value label text; the field's hint text separately also
        // shows "130", which is expected (that's the fallback value).
        expect(find.text('130 lb x 10'), findsOneWidget);
      },
    );

    testWidgets('tapping "Add Set" appends another blank row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LogExerciseCard(
            machine: _benchPress,
            sets: const [],
            history: const [],
            currentSessionId: 99,
            onConfirmSet: (_, _) {},
            onDeleteSet: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('weight-field-1-1')), findsOneWidget);
      expect(find.byKey(const Key('weight-field-1-2')), findsNothing);

      await tester.tap(find.byKey(const Key('add-set-row-button')));
      await tester.pump();

      expect(find.byKey(const Key('weight-field-1-2')), findsOneWidget);
    });

    testWidgets(
      'confirming a blank row with typed values calls onConfirmSet with them',
      (tester) async {
        int? confirmedSetNumber;
        double? confirmedWeight;
        int? confirmedReps;

        await tester.pumpWidget(
          _wrap(
            LogExerciseCard(
              machine: _benchPress,
              sets: const [],
              history: const [],
              currentSessionId: 99,
              onConfirmSet: (setNumber, input) {
                confirmedSetNumber = setNumber;
                confirmedWeight = input.weight;
                confirmedReps = input.reps;
              },
              onDeleteSet: (_) {},
            ),
          ),
        );

        await tester.enterText(
          find.byKey(const Key('weight-field-1-1')),
          '145',
        );
        await tester.enterText(find.byKey(const Key('reps-field-1-1')), '6');
        await tester.tap(find.byKey(const Key('confirm-set-button-1-1')));

        expect(confirmedSetNumber, 1);
        expect(confirmedWeight, 145);
        expect(confirmedReps, 6);
      },
    );

    testWidgets(
      'confirming a blank row with empty fields falls back to the previous value',
      (tester) async {
        double? confirmedWeight;
        int? confirmedReps;

        final history = [
          _strengthSet(
            id: 10,
            sessionId: 1,
            setNumber: 1,
            loggedAt: DateTime(2026, 7, 20),
            weight: 130,
            reps: 10,
          ),
        ];

        await tester.pumpWidget(
          _wrap(
            LogExerciseCard(
              machine: _benchPress,
              sets: const [],
              history: history,
              currentSessionId: 99,
              onConfirmSet: (setNumber, input) {
                confirmedWeight = input.weight;
                confirmedReps = input.reps;
              },
              onDeleteSet: (_) {},
            ),
          ),
        );

        await tester.tap(find.byKey(const Key('confirm-set-button-1-1')));

        expect(confirmedWeight, 130);
        expect(confirmedReps, 10);
      },
    );

    testWidgets('swiping a persisted row away calls onDeleteSet with its id', (
      tester,
    ) async {
      int? deletedId;
      final sets = [
        _strengthSet(
          id: 7,
          sessionId: 99,
          setNumber: 1,
          loggedAt: DateTime(2026, 7, 27),
          weight: 135,
          reps: 8,
        ),
      ];

      await tester.pumpWidget(
        _wrap(
          LogExerciseCard(
            machine: _benchPress,
            sets: sets,
            history: const [],
            currentSessionId: 99,
            onConfirmSet: (_, _) {},
            onDeleteSet: (id) => deletedId = id,
          ),
        ),
      );

      // Drag from the non-interactive "Set 1" label — dragging a TextField
      // itself is consumed by text-selection handling, not the ancestor
      // Dismissible.
      await tester.drag(find.text('Set 1'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(deletedId, 7);
    });

    testWidgets(
      'swiping away an unconfirmed blank row removes it locally without '
      'calling onDeleteSet',
      (tester) async {
        var deleteCalled = false;

        await tester.pumpWidget(
          _wrap(
            LogExerciseCard(
              machine: _benchPress,
              sets: const [],
              history: const [],
              currentSessionId: 99,
              onConfirmSet: (_, _) {},
              onDeleteSet: (_) => deleteCalled = true,
            ),
          ),
        );

        await tester.drag(find.text('Set 1'), const Offset(-500, 0));
        await tester.pumpAndSettle();

        expect(deleteCalled, isFalse);
        // A trailing blank row always remains available.
        expect(find.byKey(const Key('weight-field-1-1')), findsOneWidget);
      },
    );

    testWidgets('cardio machine shows incline/speed/duration fields instead', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          LogExerciseCard(
            machine: _treadmill,
            sets: const [],
            history: const [],
            currentSessionId: 99,
            onConfirmSet: (_, _) {},
            onDeleteSet: (_) {},
          ),
        ),
      );

      expect(find.byKey(const Key('incline-field-2-1')), findsOneWidget);
      expect(find.byKey(const Key('speed-field-2-1')), findsOneWidget);
      expect(find.byKey(const Key('duration-field-2-1')), findsOneWidget);
      expect(find.byKey(const Key('weight-field-2-1')), findsNothing);
    });
  });
}
