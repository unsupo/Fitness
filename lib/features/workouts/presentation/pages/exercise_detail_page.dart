import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/use_cases/compute_personal_record.dart';
import '../../domain/use_cases/calculate_one_rep_max.dart';
import '../controllers/exercises_providers.dart';
import '../controllers/workout_repository_provider.dart';
import '../widgets/edit_workout_set_dialog.dart';
import 'package:fl_chart/fl_chart.dart';

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
        _ProgressChartCard(sets: sets),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              if (set.notes != null && set.notes!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  set.notes!,
                  style: const TextStyle(
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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

class _ProgressChartCard extends StatelessWidget {
  const _ProgressChartCard({required this.sets});

  final List<WorkoutSet> sets;

  @override
  Widget build(BuildContext context) {
    final strengthSets = sets.where((s) => s.weight != null && s.reps != null).toList();
    if (sets.isEmpty || (sets.isNotEmpty && strengthSets.isEmpty)) {
      return const SizedBox.shrink();
    }

    final Map<String, ({DateTime date, double max1RM})> sessionData = {};
    for (final set in strengthSets) {
      final dateStr = DateFormat('yyyy-MM-dd').format(set.loggedAt);
      final oneRepMax = calculateOneRepMax(weight: set.weight!, reps: set.reps!);
      final existing = sessionData[dateStr];
      if (existing == null || oneRepMax > existing.max1RM) {
        sessionData[dateStr] = (date: set.loggedAt, max1RM: oneRepMax);
      }
    }

    final sortedPoints = sessionData.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    if (sortedPoints.length < 2) {
      return SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estimated 1RM Progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            const Text(
              'Log this exercise in at least 2 different workouts to see your progress chart.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final min1RM = sortedPoints.map((p) => p.max1RM).reduce((a, b) => a < b ? a : b);
    final max1RM = sortedPoints.map((p) => p.max1RM).reduce((a, b) => a > b ? a : b);

    final minY = (min1RM * 0.9).roundToDouble();
    final maxY = (max1RM * 1.1).roundToDouble();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated 1RM Progress',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: (val, meta) => Text(
                        val.round().toString(),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= sortedPoints.length) return const SizedBox.shrink();
                        if (idx == 0 || idx == sortedPoints.length - 1 || sortedPoints.length <= 4) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('M/d').format(sortedPoints[idx].date),
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0.0,
                maxX: (sortedPoints.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < sortedPoints.length; i++)
                        FlSpot(i.toDouble(), sortedPoints[i].max1RM),
                    ],
                    isCurved: true,
                    color: AppColors.brandGreen,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.brandGreen.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
