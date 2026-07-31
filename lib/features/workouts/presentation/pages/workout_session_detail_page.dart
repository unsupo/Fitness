import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/use_cases/group_sets_by_machine.dart';
import '../controllers/history_providers.dart';
import '../widgets/edit_workout_set_dialog.dart';

/// Full detail for one past workout session — every set, grouped by
/// machine. View-only in this pass (no editing/deleting); see
/// docs/features/workouts-history.md.
///
/// Routed centrally by the orchestrator at `/workouts/session/:id` — this
/// page takes a plain required `sessionId`, it does not read route state
/// itself.
class WorkoutSessionDetailPage extends ConsumerWidget {
  const WorkoutSessionDetailPage({super.key, required this.sessionId});

  final int sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionHistoryProvider);
    final setsAsync = ref.watch(setsForSessionProvider(sessionId));

    final title = sessionsAsync.maybeWhen(
      data: (sessions) {
        final matches = sessions.where((s) => s.id == sessionId);
        if (matches.isEmpty) return 'Workout';
        return DateFormat('MMM d, yyyy').format(matches.first.sessionDate);
      },
      orElse: () => 'Workout',
    );

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(title),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            ref.refresh(setsForSessionProvider(sessionId).future),
          ]),
          child: setsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Center(child: Text('Could not load session: $error')),
            data: (sets) => _SessionBody(sessionId: sessionId, sets: sets),
          ),
        ),
      ),
    );
  }
}

class _SessionBody extends ConsumerWidget {
  const _SessionBody({required this.sessionId, required this.sets});

  final int sessionId;
  final List<WorkoutSet> sets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = groupSetsByMachine(sets);

    if (groups.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.only(top: 64),
            child: Center(
              child: Text(
                'No sets logged for this session.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = groups[index];

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.machineName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              for (final set in group.sets)
                InkWell(
                  onTap: () => showEditWorkoutSetDialog(
                    context,
                    ref,
                    set,
                    onChanged: () =>
                        ref.invalidate(setsForSessionProvider(sessionId)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_formatSet(set)),
                            const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        ),
                        if (set.notes != null && set.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              set.notes!,
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// "Set 1: 135 lb x 8" for strength sets (weight/reps both present),
  /// "12 min @ 5.5 mph" style for cardio sets — branches on which fields
  /// are non-null, per docs/features/workouts-history.md.
  String _formatSet(WorkoutSet set) {
    if (set.weight != null && set.reps != null) {
      return 'Set ${set.setNumber}: ${_trimNum(set.weight!)} ${set.unit} x ${set.reps}';
    }

    final parts = <String>[];
    if (set.durationMinutes != null) {
      parts.add('${_trimNum(set.durationMinutes!)} min');
    }
    if (set.speed != null) {
      parts.add('@ ${_trimNum(set.speed!)} mph');
    }
    if (set.incline != null) {
      parts.add('(${_trimNum(set.incline!)}% incline)');
    }
    return parts.isEmpty ? 'Set ${set.setNumber}' : parts.join(' ');
  }

  String _trimNum(double value) {
    return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
  }
}
