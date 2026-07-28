import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../../domain/use_cases/group_sets_by_machine.dart';
import '../../domain/use_cases/summarize_session.dart';
import '../controllers/log_providers.dart';
import '../controllers/workout_repository_provider.dart';

/// Idle-state summary card: the most recent session's date plus a
/// comma-joined list of its distinct exercises (e.g. "Bench Press, Squat"),
/// from [summarizeSession], or "No workouts yet" if there's no history at
/// all. Also offers "Repeat this workout" (see
/// docs/features/workouts-log-redesign.md), which starts a new session
/// pre-loaded with the same exercises.
class LogLastWorkoutCard extends ConsumerWidget {
  const LogLastWorkoutCard({super.key, required this.onRepeat});

  /// Starts a new session pre-loaded with these machines (in the last
  /// session's first-seen order).
  final void Function(List<Machine> machines) onRepeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSessionAsync = ref.watch(lastSessionProvider);

    return SectionCard(
      child: lastSessionAsync.when(
        loading: () => const SizedBox(
          height: 40,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (error, stackTrace) =>
            Text('Could not load last workout: $error'),
        data: (session) {
          if (session == null) {
            return const Text(
              'No workouts yet',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            );
          }
          return _LastSessionSummary(
            sessionId: session.id,
            date: session.sessionDate,
            onRepeat: onRepeat,
          );
        },
      ),
    );
  }
}

class _LastSessionSummary extends ConsumerWidget {
  const _LastSessionSummary({
    required this.sessionId,
    required this.date,
    required this.onRepeat,
  });

  final int sessionId;
  final DateTime date;
  final void Function(List<Machine> machines) onRepeat;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(sessionSetsProvider(sessionId));
    final machinesAsync = ref.watch(machinesProvider);
    final dateLabel = DateFormat('MMM d, yyyy').format(date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Last workout',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          dateLabel,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 4),
        setsAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stackTrace) => Text('Could not load: $error'),
          data: (sets) {
            final summary = summarizeSession(sets);
            final groups = groupSetsByMachine(sets);
            final machines = machinesAsync.maybeWhen(
              data: (m) => m,
              orElse: () => const <Machine>[],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary.isEmpty ? 'No exercises logged' : summary,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                if (groups.isNotEmpty && machines.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      key: const Key('repeat-workout-button'),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      onPressed: () {
                        final repeatMachines = [
                          for (final group in groups)
                            ..._findMachine(machines, group.machineId),
                        ];
                        onRepeat(repeatMachines);
                      },
                      child: const Text('Repeat this workout'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Iterable<Machine> _findMachine(List<Machine> machines, int machineId) sync* {
    for (final machine in machines) {
      if (machine.id == machineId) {
        yield machine;
        return;
      }
    }
  }
}
