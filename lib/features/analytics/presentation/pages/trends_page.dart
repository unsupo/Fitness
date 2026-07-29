import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../domain/entities/daily_calories.dart';
import '../../domain/entities/macro_breakdown.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/use_cases/weight_unit.dart';
import '../controllers/analytics_providers.dart';
import '../widgets/fullscreen_chart_page.dart';
import '../widgets/import_weight_csv.dart';
import '../widgets/log_weight_dialog.dart';
import '../widgets/weight_goal_section.dart';

/// A small rotating palette used for the weekly-calories bars — the mockup
/// gives each bar visual variety, not per-day semantic meaning.
const _barPalette = [
  AppColors.proteinRing,
  AppColors.carbsRing,
  AppColors.fatRing,
  AppColors.brandGreen,
];

class TrendsPage extends ConsumerWidget {
  const TrendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final selectedTab = ref.watch(selectedTrendsTabProvider);
    final showCalories = selectedTab == 0 || selectedTab == 2;
    final showProgress = selectedTab == 1 || selectedTab == 2;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Nourish'),
        actions: [
          if (Navigator.of(context).canPop())
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () {
            final macroParams = (
              start: weekStart,
              end: weekStart.add(const Duration(days: 7)),
            );
            return Future.wait([
              ref.refresh(weeklyCaloriesProvider(weekStart).future),
              ref.refresh(macroBreakdownProvider(macroParams).future),
              ref.refresh(weightHistoryProvider.future),
              ref.refresh(calorieGoalProvider.future),
              ref.refresh(userProfileProvider.future),
            ]);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _WeekHeader(weekStart: weekStart),
              const SizedBox(height: 16),
              if (showCalories) ...[
                const _WeeklyCaloriesSection(),
                const SizedBox(height: 16),
              ],
              if (showProgress) ...[
                const _MacroBreakdownSection(),
                const SizedBox(height: 16),
                const _WeightSection(),
                const SizedBox(height: 16),
                const WeightGoalSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekHeader extends ConsumerWidget {
  const _WeekHeader({required this.weekStart});

  final DateTime weekStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final rangeLabel = weekStart.month == weekEnd.month
        ? '${DateFormat('MMM d').format(weekStart)}-${DateFormat('d').format(weekEnd)}'
        : '${DateFormat('MMM d').format(weekStart)} - ${DateFormat('MMM d').format(weekEnd)}';

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () =>
                  ref.read(selectedWeekStartProvider.notifier).state = weekStart
                      .subtract(const Duration(days: 7)),
            ),
            Text(
              rangeLabel,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () =>
                  ref.read(selectedWeekStartProvider.notifier).state = weekStart
                      .add(const Duration(days: 7)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const _SegmentedTabs(),
      ],
    );
  }
}

/// Segmented control matching the mockup's three labels. Selecting a tab
/// changes which sections `TrendsPage` shows below (see
/// `selectedTrendsTabProvider`).
class _SegmentedTabs extends ConsumerWidget {
  const _SegmentedTabs();

  static const _labels = ['Weekly', 'Progress', 'Trends'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedTrendsTabProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.ringTrack,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: List.generate(_labels.length, (i) {
          final isSelected = i == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(selectedTrendsTabProvider.notifier).state = i,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.brandGreen
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WeeklyCaloriesSection extends ConsumerWidget {
  const _WeeklyCaloriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final caloriesAsync = ref.watch(weeklyCaloriesProvider(weekStart));
    final goalAsync = ref.watch(calorieGoalProvider);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Calories',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: caloriesAsync.when(
              data: (days) => goalAsync.when(
                data: (goal) => _CaloriesBarChart(days: days, goal: goal),
                loading: () => _CaloriesBarChart(days: days, goal: null),
                error: (_, _) => _CaloriesBarChart(days: days, goal: null),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CaloriesBarChart extends StatelessWidget {
  const _CaloriesBarChart({required this.days, required this.goal});

  final List<DailyCalories> days;
  final double? goal;

  @override
  Widget build(BuildContext context) {
    final maxCalories = days.isEmpty
        ? 100.0
        : days.map((d) => d.totalCalories).reduce((a, b) => a > b ? a : b);
    final maxY = [maxCalories, goal ?? 0].reduce((a, b) => a > b ? a : b) * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY == 0 ? 100 : maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${days[i].date.day}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < days.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: days[i].totalCalories,
                  color: _barPalette[i % _barPalette.length],
                  width: 18,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
        ],
        extraLinesData: goal == null
            ? const ExtraLinesData()
            : ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: goal!,
                    color: AppColors.accentOrange,
                    strokeWidth: 2,
                    dashArray: const [8, 4],
                  ),
                ],
              ),
      ),
    );
  }
}

class _MacroBreakdownSection extends ConsumerWidget {
  const _MacroBreakdownSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);
    final params = (
      start: weekStart,
      end: weekStart.add(const Duration(days: 7)),
    );
    final macroAsync = ref.watch(macroBreakdownProvider(params));

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro Breakdown',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: macroAsync.when(
              data: (macro) => _MacroDonut(macro: macro),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(child: Text('Error: $error')),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroDonut extends StatelessWidget {
  const _MacroDonut({required this.macro});

  final MacroBreakdown macro;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              sections: [
                PieChartSectionData(
                  value: macro.proteinG,
                  color: AppColors.proteinRing,
                  showTitle: false,
                  radius: 40,
                ),
                PieChartSectionData(
                  value: macro.carbsG,
                  color: AppColors.carbsRing,
                  showTitle: false,
                  radius: 40,
                ),
                PieChartSectionData(
                  value: macro.fatG,
                  color: AppColors.fatRing,
                  showTitle: false,
                  radius: 40,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendRow(
                color: AppColors.proteinRing,
                label: 'Protein',
                percent: macro.proteinPercent,
              ),
              const SizedBox(height: 8),
              _LegendRow(
                color: AppColors.carbsRing,
                label: 'Carbs',
                percent: macro.carbsPercent,
              ),
              const SizedBox(height: 8),
              _LegendRow(
                color: AppColors.fatRing,
                label: 'Fat',
                percent: macro.fatPercent,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.percent,
  });

  final Color color;
  final String label;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label ${(percent * 100).round()}%',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _WeightSection extends ConsumerStatefulWidget {
  const _WeightSection();

  @override
  ConsumerState<_WeightSection> createState() => _WeightSectionState();
}

class _WeightSectionState extends ConsumerState<_WeightSection> {
  // Lets a tap anywhere in this section (e.g. this "Weight" heading, not
  // just the chart itself) dismiss a touched point's tooltip.
  final _chartKey = GlobalKey<_WeightHistoryChartState>();

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(weightHistoryProvider);

    return SectionCard(
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => _chartKey.currentState?.clear(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weight',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.upload_file_outlined, size: 20),
                  tooltip: 'Import weigh-ins from CSV',
                  onPressed: () => importWeightCsv(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 12),
            historyAsync.when(
              data: (history) =>
                  _WeightBody(history: history, chartKey: _chartKey),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(child: Text('Error: $error')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeightBody extends ConsumerStatefulWidget {
  const _WeightBody({required this.history, required this.chartKey});

  final List<WeightEntry> history;

  /// Owned by the ancestor `_WeightSectionState` so a tap anywhere in that
  /// wider section (not just this chart's own bounds) can dismiss a
  /// touched point's tooltip.
  final GlobalKey<_WeightHistoryChartState> chartKey;

  @override
  ConsumerState<_WeightBody> createState() => _WeightBodyState();
}

class _WeightBodyState extends ConsumerState<_WeightBody> {
  // Editing every weigh-in is still one tap away, but a growing CSV-imported
  // history shouldn't force a long scroll just to see the chart — only the
  // most recent few show by default.
  static const _collapsedCount = 5;
  bool _showAll = false;

  List<WeightEntry> _visibleEntries(List<WeightEntry> history) {
    final newestFirst = history.reversed.toList();
    return _showAll ? newestFirst : newestFirst.take(_collapsedCount).toList();
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    if (history.isEmpty) {
      return Column(
        children: [
          const SizedBox(height: 16),
          const Text(
            'No weigh-ins yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => showLogWeightDialog(context, ref),
            child: const Text('Log weight'),
          ),
        ],
      );
    }

    final latest = history.last;
    final goalLabel = latest.goalType.isEmpty
        ? ''
        : latest.goalType[0].toUpperCase() + latest.goalType.substring(1);
    final unitSystem =
        ref.watch(userProfileProvider).value?.unitSystem ?? 'metric';
    final unit = weightUnitFor(unitSystem);
    final displayLatest = displayWeight(latest.weightKg, unit: unit);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Current Weight: ${displayLatest.toStringAsFixed(1)} $unit',
                style: const TextStyle(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text('Goal: $goalLabel'),
          ],
        ),
        const SizedBox(height: 12),
        for (final entry in _visibleEntries(history))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${DateFormat('MMM d, yyyy').format(entry.loggedAt)} · '
                    '${displayWeight(entry.weightKg, unit: unit).toStringAsFixed(1)} $unit',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit weigh-in',
                  onPressed: () =>
                      showLogWeightDialog(context, ref, entryToEdit: entry),
                ),
              ],
            ),
          ),
        if (history.length > _collapsedCount)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                _showAll ? 'Show less' : 'Show all (${history.length})',
              ),
            ),
          ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            key: const Key('weight-history-fullscreen-button'),
            icon: const Icon(Icons.fullscreen, size: 20),
            tooltip: 'View fullscreen',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FullScreenChartPage(
                  title: 'Weight',
                  chart: _WeightHistoryChart(history: history, unit: unit),
                ),
              ),
            ),
          ),
        ),
        _WeightHistoryChart(
          key: widget.chartKey,
          history: history,
          unit: unit,
          height: 160,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showLogWeightDialog(context, ref),
            child: const Text('Log weight'),
          ),
        ),
      ],
    );
  }
}

/// The weigh-in history chart, reused both inline (small) and in the
/// fullscreen landscape view. Stateful so a touched point's tooltip
/// persists until the user taps elsewhere, rather than only while actively
/// touching (fl_chart's built-in behavior, which reads as "nothing
/// happened" on a real device — a tap is a quick down-then-up).
class _WeightHistoryChart extends StatefulWidget {
  const _WeightHistoryChart({
    super.key,
    required this.history,
    required this.unit,
    this.height,
  });

  final List<WeightEntry> history;
  final String unit;

  /// A fixed chart height for the small inline card view; `null` (the
  /// fullscreen view) fills whatever bounded space its ancestor gives it.
  final double? height;

  @override
  State<_WeightHistoryChart> createState() => _WeightHistoryChartState();
}

class _WeightHistoryChartState extends State<_WeightHistoryChart> {
  List<LineBarSpot> _touchedSpots = [];

  /// Called by an ancestor (e.g. `_WeightSectionState`, when its wider
  /// "tap elsewhere" area is tapped) to dismiss a shown tooltip.
  void clear() {
    if (_touchedSpots.isNotEmpty) setState(() => _touchedSpots = []);
  }

  @override
  Widget build(BuildContext context) {
    final history = widget.history;
    final unit = widget.unit;

    final chart = LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          // We manage the tooltip's visibility ourselves (via
          // showingTooltipIndicators below) so it persists after the
          // finger lifts, instead of fl_chart's default of hiding it the
          // moment the touch ends.
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response?.lineBarSpots != null) {
              setState(() => _touchedSpots = response!.lineBarSpots!);
            }
          },
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) => [
              for (final spot in touchedSpots)
                LineTooltipItem(
                  '${DateFormat('MMM d, yyyy').format(history[spot.x.toInt()].loggedAt)}\n'
                  '${spot.y.toStringAsFixed(1)} $unit',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        showingTooltipIndicators: _touchedSpots.isEmpty
            ? []
            : [ShowingTooltipIndicators(_touchedSpots)],
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              // Every point's own date, not just the month — several
              // readings within the same month previously all showed the
              // identical "Jul" label with nothing distinguishing them.
              // Thin out labels for longer histories so they don't overlap.
              interval: (history.length / 5).ceil().clamp(1, 999).toDouble(),
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= history.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    DateFormat('M/d').format(history[i].loggedAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < history.length; i++)
                FlSpot(i.toDouble(), displayWeight(history[i].weightKg, unit: unit)),
            ],
            isCurved: true,
            color: AppColors.brandGreen,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(() => _touchedSpots = []),
      child: widget.height != null
          ? SizedBox(height: widget.height, child: chart)
          : chart,
    );
  }
}
