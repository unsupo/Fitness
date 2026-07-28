import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/widgets/macro_ring.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/compute_daily_totals.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/daily_calorie_card.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/meal_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// The Home dashboard: date selector, meal sections grouped by category,
/// daily calorie progress bar, and three macro rings.
class DiaryPage extends ConsumerWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = ref.watch(selectedDateProvider);

    final entriesAsync = ref.watch(diaryEntriesProvider(date));
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Nourish'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: entriesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Could not load diary: $error')),
          data: (entries) => goalsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) =>
                Center(child: Text('Could not load goals: $error')),
            data: (goals) => _DiaryContent(date: date, entries: entries, goals: goals),
          ),
        ),
      ),
    );
  }
}

class _DiaryContent extends ConsumerWidget {
  const _DiaryContent({
    required this.date,
    required this.entries,
    required this.goals,
  });

  final DateTime date;
  final List<DiaryEntry> entries;
  final DailyGoals goals;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = computeDailyTotals(entries);

    return RefreshIndicator(
      onRefresh: () => Future.wait([
        ref.refresh(diaryEntriesProvider(date).future),
        ref.refresh(dailyGoalsProvider.future),
      ]),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _DateSelectorRow(date: date, ref: ref),
          const SizedBox(height: 16),
          if (entries.isEmpty) const _EmptyDiaryDay() else ..._buildMealSections(),
          const SizedBox(height: 16),
          DailyCalorieCard(totals: totals, goals: goals),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MacroRing(
                label: 'Protein',
                progress: goals.proteinGoalG == 0
                    ? 0
                    : totals.proteinG / goals.proteinGoalG,
                color: AppColors.proteinRing,
              ),
              MacroRing(
                label: 'Carbs',
                progress: goals.carbsGoalG == 0
                    ? 0
                    : totals.carbsG / goals.carbsGoalG,
                color: AppColors.carbsRing,
              ),
              MacroRing(
                label: 'Fat',
                progress: goals.fatGoalG == 0
                    ? 0
                    : totals.fatG / goals.fatGoalG,
                color: AppColors.fatRing,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMealSections() {
    final widgets = <Widget>[];
    for (final mealType in MealType.values) {
      final matching = entries.where((e) => e.mealType == mealType).toList();
      if (matching.isEmpty) continue;
      widgets.add(MealSection(mealType: mealType, entries: matching));
      widgets.add(const SizedBox(height: 16));
    }
    return widgets;
  }
}

/// Shown instead of the meal sections when a day has nothing logged at all
/// — previously this left a blank gap between the date selector and the
/// Daily Calories card, with no indication of why or what to do next.
class _EmptyDiaryDay extends StatelessWidget {
  const _EmptyDiaryDay();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        children: [
          const Icon(
            Icons.restaurant_outlined,
            size: 40,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 12),
          Text(
            'No meals logged yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap the + button below to scan a barcode or snap a photo of '
            'your first meal today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DateSelectorRow extends StatelessWidget {
  const _DateSelectorRow({required this.date, required this.ref});

  final DateTime date;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('MMM d, yyyy').format(date);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () {
            ref.read(selectedDateProvider.notifier).state = date.subtract(
              const Duration(days: 1),
            );
          },
        ),
        Text('Date: $formatted', style: Theme.of(context).textTheme.bodyLarge),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () {
            ref.read(selectedDateProvider.notifier).state = date.add(
              const Duration(days: 1),
            );
          },
        ),
      ],
    );
  }
}
