import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/use_cases/summarize_session.dart';
import '../controllers/history_providers.dart';

/// Strong app's "History" tab — past workout sessions newest first, each row
/// a date + short exercise summary, tapping opens the full session detail.
/// See docs/features/workouts-history.md. Hosted as one of the internal tabs
/// of `/workouts` (docs/WORKOUTS_PLAN.md) — deliberately has no AppBar of
/// its own, the hosting shell owns that; it does own a bare `Scaffold` so it
/// renders correctly (Material ancestor for `InkWell`) regardless of host.
class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionHistoryProvider);

    return Scaffold(
      body: SafeArea(
        child: sessionsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Could not load workout history: $error')),
          data: (sessions) => sessions.isEmpty
              ? const _EmptyHistory()
              : _HistoryList(sessions: sessions),
        ),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.sessions});

  final List<WorkoutSession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final session = sessions[index];
        final setsAsync = ref.watch(setsForSessionProvider(session.id));
        final formattedDate = DateFormat(
          'MMM d, yyyy',
        ).format(session.sessionDate);

        return _SessionRow(
          formattedDate: formattedDate,
          summary: setsAsync.when(
            data: summarizeSession,
            loading: () => '',
            error: (error, stackTrace) => '',
          ),
          onTap: () => context.push('/workouts/session/${session.id}'),
        );
      },
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.formattedDate,
    required this.summary,
    required this.onTap,
  });

  final String formattedDate;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(summary, style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Matches `_EmptyDiaryDay` in `diary_page.dart`'s style: icon + heading +
/// subtext in a `SectionCard`, per docs/features/workouts-history.md.
class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        child: Column(
          children: [
            const Icon(
              Icons.history,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No workouts logged yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Finish a workout on the Log tab and it will show up here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
