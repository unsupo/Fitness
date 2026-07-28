import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/use_cases/summarize_session.dart';
import '../controllers/log_providers.dart';

/// Idle-state summary card: the most recent session's date plus a
/// comma-joined list of its distinct exercises (e.g. "Bench Press, Squat"),
/// from [summarizeSession], or "No workouts yet" if there's no history at
/// all.
class LogLastWorkoutCard extends ConsumerWidget {
  const LogLastWorkoutCard({super.key});

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
          return _LastSessionSummary(sessionId: session.id, date: session.sessionDate);
        },
      ),
    );
  }
}

class _LastSessionSummary extends ConsumerWidget {
  const _LastSessionSummary({required this.sessionId, required this.date});

  final int sessionId;
  final DateTime date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(sessionSetsProvider(sessionId));
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
            return Text(
              summary.isEmpty ? 'No exercises logged' : summary,
              style: const TextStyle(color: AppColors.textSecondary),
            );
          },
        ),
      ],
    );
  }
}
