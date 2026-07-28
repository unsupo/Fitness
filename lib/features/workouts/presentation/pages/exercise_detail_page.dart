import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/use_cases/compute_personal_record.dart';
import '../controllers/exercises_providers.dart';
import '../controllers/workout_repository_provider.dart';
import '../widgets/edit_workout_set_dialog.dart';

/// One machine's detail page: a "Personal Record" callout (max weight, via
/// `computePersonalRecord`) plus the full set history, reverse-chronological.
/// Reached via `/workouts/exercise/:id` (wired centrally by the router).
class ExerciseDetailPage extends ConsumerWidget {
  const ExerciseDetailPage({super.key, required this.machineId});

  final int machineId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final machinesAsync = ref.watch(machinesProvider);
    final setsAsync = ref.watch(setsForMachineProvider(machineId));

    final title =
        machinesAsync.maybeWhen(
          data: (machines) => _findMachineName(machines, machineId),
          orElse: () => null,
        ) ??
        'Exercise';

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text(title),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(machinesProvider.future),
            ref.refresh(setsForMachineProvider(machineId).future),
          ]),
          child: setsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Center(child: Text('Could not load history: $error')),
            data: (sets) =>
                _ExerciseDetailBody(machineId: machineId, sets: sets),
          ),
        ),
      ),
    );
  }
}

String? _findMachineName(List<Machine> machines, int machineId) {
  for (final machine in machines) {
    if (machine.id == machineId) return machine.name;
  }
  return null;
}

class _ExerciseDetailBody extends ConsumerWidget {
  const _ExerciseDetailBody({required this.machineId, required this.sets});

  final int machineId;
  final List<WorkoutSet> sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pr = computePersonalRecord(sets);
    final history = List<WorkoutSet>.of(sets)
      ..sort((a, b) => b.loggedAt.compareTo(a.loggedAt));

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Record',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (pr == null)
                const Text(
                  'No PR yet',
                  style: TextStyle(color: AppColors.textSecondary),
                )
              else
                Text(_formatPrLine(pr)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (history.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 32),
            child: Center(
              child: Text(
                'Not logged yet',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          )
        else
          for (final set in history)
            _HistoryRow(
              set: set,
              onTap: () => showEditWorkoutSetDialog(
                context,
                ref,
                set,
                onChanged: () =>
                    ref.invalidate(setsForMachineProvider(machineId)),
              ),
            ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.set, required this.onTap});

  final WorkoutSet set;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: SectionCard(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMM d, yyyy').format(set.loggedAt),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              Text(
                _formatSetLine(set),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatPrLine(WorkoutSet set) {
  return '${_formatSetLine(set)} — ${DateFormat('MMM d, yyyy').format(set.loggedAt)}';
}

/// Formats whichever measurement fields are non-null — strength
/// (weight/reps) or cardio (incline/speed/duration) — the same branch
/// convention the Log/History tabs use for this schema ambiguity (see
/// docs/WORKOUTS_PLAN.md).
String _formatSetLine(WorkoutSet set) {
  if (set.weight != null && set.reps != null) {
    return '${_formatNum(set.weight!)} ${set.unit} x ${set.reps}';
  }
  final parts = <String>[
    if (set.durationMinutes != null) '${_formatNum(set.durationMinutes!)} min',
    if (set.speed != null) '${_formatNum(set.speed!)} mph',
    if (set.incline != null) '${_formatNum(set.incline!)}% incline',
  ];
  return parts.isEmpty ? 'No data logged' : parts.join(' · ');
}

String _formatNum(double value) {
  return value % 1 == 0 ? value.toInt().toString() : value.toString();
}
