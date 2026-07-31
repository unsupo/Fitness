import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import '../controllers/exercises_providers.dart';
import '../controllers/log_providers.dart';
import '../controllers/overload_providers.dart';
import '../controllers/workout_repository_provider.dart';
import 'log_exercise_card.dart';

/// The Log tab's active-session body: a date header with a "Finish
/// Workout" action, the list of exercises added so far (each a Strong-style
/// [LogExerciseCard] — see docs/features/workouts-log-redesign.md), and an
/// "Add Exercise" button.
///
/// [machines] is the locally-tracked, in-order list of machines added to
/// this session by `LogTab` — a machine only gets a persisted `workout_sets`
/// row once a set is confirmed against it, so it can appear here before
/// [sessionSetsProvider] has any rows for it.
///
/// Unlike the previous design, this widget talks to
/// [workoutRepositoryProvider] directly (logSet/updateSet/deleteSet) rather
/// than delegating through a callback prop — each [LogExerciseCard] row can
/// independently be a new set (logSet) or an edit of an already-persisted
/// one (updateSet), which the card itself doesn't know or need to know.
class LogActiveView extends ConsumerWidget {
  const LogActiveView({
    super.key,
    required this.session,
    required this.machines,
    required this.onFinish,
    required this.onAddExercise,
  });

  final WorkoutSession session;
  final List<Machine> machines;
  final VoidCallback onFinish;
  final VoidCallback onAddExercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(sessionSetsProvider(session.id));
    final dateLabel = DateFormat('MMM d, yyyy').format(session.sessionDate);
    final trainingFocus = ref.watch(trainingFocusProvider);

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateLabel,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandGreen,
                  ),
                ),
                TextButton(
                  key: const Key('finish-workout-button'),
                  onPressed: onFinish,
                  child: const Text('Finish Workout'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => Future.wait([
                ref.refresh(sessionSetsProvider(session.id).future),
              ]),
              child: setsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Could not load sets: $error')),
                data: (sets) => ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (machines.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Add an exercise to get started.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    for (final machine in machines) ...[
                      Consumer(
                        builder: (context, ref, _) {
                          final historyAsync = ref.watch(
                            setsForMachineProvider(machine.id),
                          );
                          final machineSets =
                              sets
                                  .where((s) => s.machineId == machine.id)
                                  .toList()
                                ..sort(
                                  (a, b) =>
                                      a.setNumber.compareTo(b.setNumber),
                                );

                          return LogExerciseCard(
                            machine: machine,
                            sets: machineSets,
                            history: historyAsync.maybeWhen(
                              data: (history) => history,
                              orElse: () => const [],
                            ),
                            trainingFocus: trainingFocus,
                            currentSessionId: session.id,
                            onConfirmSet: (setNumber, input) => _confirmSet(
                              ref: ref,
                              machine: machine,
                              existingSets: machineSets,
                              setNumber: setNumber,
                              input: input,
                            ),
                            onDeleteSet: (setId) => _deleteSet(
                              ref: ref,
                              machineId: machine.id,
                              setId: setId,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    FilledButton.icon(
                      key: const Key('add-exercise-button'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: onAddExercise,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Exercise'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSet({
    required WidgetRef ref,
    required Machine machine,
    required List<WorkoutSet> existingSets,
    required int setNumber,
    required LogSetInput input,
  }) async {
    final repository = ref.read(workoutRepositoryProvider);
    WorkoutSet? existing;
    for (final set in existingSets) {
      if (set.setNumber == setNumber) {
        existing = set;
        break;
      }
    }

    if (existing != null) {
      await repository.updateSet(
        WorkoutSet(
          id: existing.id,
          loggedAt: existing.loggedAt,
          machineId: machine.id,
          machineName: machine.name,
          sessionId: session.id,
          setNumber: setNumber,
          machineOrder: existing.machineOrder,
          weight: input.weight,
          reps: input.reps,
          unit: existing.unit,
          incline: input.incline,
          speed: input.speed,
          durationMinutes: input.durationMinutes,
          seatPosition: existing.seatPosition,
          restSeconds: existing.restSeconds,
          notes: existing.notes,
        ),
      );
    } else {
      await repository.logSet(
        WorkoutSet(
          id: 0, // ignored on insert — see WorkoutRepository.logSet contract.
          loggedAt: DateTime.now(),
          machineId: machine.id,
          machineName: machine.name,
          sessionId: session.id,
          setNumber: setNumber,
          weight: input.weight,
          reps: input.reps,
          incline: input.incline,
          speed: input.speed,
          durationMinutes: input.durationMinutes,
        ),
      );
    }

    ref.invalidate(sessionSetsProvider(session.id));
    ref.invalidate(setsForMachineProvider(machine.id));
  }

  Future<void> _deleteSet({
    required WidgetRef ref,
    required int machineId,
    required int setId,
  }) async {
    await ref.read(workoutRepositoryProvider).deleteSet(setId);
    ref.invalidate(sessionSetsProvider(session.id));
    ref.invalidate(setsForMachineProvider(machineId));
  }
}
