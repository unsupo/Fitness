import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import '../controllers/log_providers.dart';
import 'edit_workout_set_dialog.dart';
import 'log_exercise_card.dart';

/// The Log tab's active-session body: a date header with a "Finish
/// Workout" action, the list of exercises added so far (each an editable
/// [LogExerciseCard]), and an "Add Exercise" button.
///
/// [machines] is the locally-tracked, in-order list of machines added to
/// this session by `LogTab` — a machine only gets a persisted `workout_sets`
/// row once a set is logged against it, so it can appear here before
/// [sessionSetsProvider] has any rows for it. Once sets exist, they're
/// looked up from [sessionSetsProvider] and merged in by `machineId`.
///
/// Deviation from docs/features/workouts-log.md: the spec suggests reusing
/// `MachineSetGroup`/`groupSetsByMachine` from `domain/use_cases/` to shape
/// this list. That helper only produces one entry per machine that already
/// has at least one set, but this screen also needs to show a just-added
/// exercise with zero sets yet (so its inline add-set form has somewhere to
/// render) — so the grouping here is done directly against the explicit,
/// caller-tracked [machines] order instead, and only reaches into the flat
/// set list to filter each machine's own sets.
class LogActiveView extends ConsumerWidget {
  const LogActiveView({
    super.key,
    required this.session,
    required this.machines,
    required this.onFinish,
    required this.onAddExercise,
    required this.onLogSet,
  });

  final WorkoutSession session;
  final List<Machine> machines;
  final VoidCallback onFinish;
  final VoidCallback onAddExercise;
  final void Function(WorkoutSet draft) onLogSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(sessionSetsProvider(session.id));
    final dateLabel = DateFormat('MMM d, yyyy').format(session.sessionDate);

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
                      LogExerciseCard(
                        machine: machine,
                        sets:
                            sets
                                .where((s) => s.machineId == machine.id)
                                .toList()
                              ..sort(
                                (a, b) => a.setNumber.compareTo(b.setNumber),
                              ),
                        onAddSet: (input) => onLogSet(
                          _buildSet(
                            machine: machine,
                            existingSetsForSession: sets,
                            input: input,
                          ),
                        ),
                        onEditSet: (set) => showEditWorkoutSetDialog(
                          context,
                          ref,
                          set,
                          onChanged: () =>
                              ref.invalidate(sessionSetsProvider(session.id)),
                        ),
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

  WorkoutSet _buildSet({
    required Machine machine,
    required List<WorkoutSet> existingSetsForSession,
    required LogSetInput input,
  }) {
    final existingForMachine = existingSetsForSession.where(
      (s) => s.machineId == machine.id,
    );
    return WorkoutSet(
      id: 0, // ignored on insert — see WorkoutRepository.logSet contract.
      loggedAt: DateTime.now(),
      machineId: machine.id,
      machineName: machine.name,
      sessionId: session.id,
      setNumber: existingForMachine.length + 1,
      weight: input.weight,
      reps: input.reps,
      incline: input.incline,
      speed: input.speed,
      durationMinutes: input.durationMinutes,
    );
  }
}
