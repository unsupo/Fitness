import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_drawer.dart';
import '../../../diary/domain/entities/daily_goals.dart';
import '../../../diary/presentation/controllers/diary_providers.dart';
import '../../domain/entities/daily_calories.dart';
import '../../domain/entities/macro_breakdown.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/use_cases/compute_weekly_average_trend.dart';
import '../../domain/use_cases/format_week_range.dart';
import '../../domain/use_cases/weight_unit.dart';
import '../controllers/analytics_providers.dart';
import '../widgets/fullscreen_chart_page.dart';
import '../widgets/import_weight_csv.dart';
import '../widgets/log_weight_dialog.dart';
import '../widgets/weight_goal_section.dart';



class TrendsPage extends ConsumerWidget {
  const TrendsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekStart = ref.watch(selectedWeekStartProvider);

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
              const _WeeklyCaloriesSection(),
              const SizedBox(height: 16),
              const _MacroBreakdownSection(),
              const SizedBox(height: 16),
              const _WeightSection(),
              const SizedBox(height: 16),
              const WeightGoalSection(),
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
    final rangeLabel = formatWeekRange(weekStart);

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
      ],
    );
  }
}

class _WeeklyCaloriesSection extends ConsumerStatefulWidget {
  const _WeeklyCaloriesSection();

  @override
  ConsumerState<_WeeklyCaloriesSection> createState() =>
      _WeeklyCaloriesSectionState();
}

class _WeeklyCaloriesSectionState
    extends ConsumerState<_WeeklyCaloriesSection> {
  /// A real horizontal scroll (not a fling-velocity gesture) needs a wide
  /// enough virtual page range to feel infinite in both directions —
  /// ~1900 years each way is more than enough headroom.
  static const _centerPage = 100000;

  late final PageController _pageController;

  /// The week shown at [_centerPage] — re-anchored (and the controller
  /// re-centered) every time the page settles, so the range never runs out.
  late DateTime _anchorWeekStart;

  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _anchorWeekStart = ref.read(selectedWeekStartProvider);
    _pageController = PageController(initialPage: _centerPage);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime _weekStartForPage(int page) =>
      _anchorWeekStart.add(Duration(days: 7 * (page - _centerPage)));

  void _onPageChanged(int page) {
    final newWeekStart = _weekStartForPage(page);
    ref.read(selectedWeekStartProvider.notifier).state = newWeekStart;
    setState(() {
      _anchorWeekStart = newWeekStart;
      _selectedIndex = null;
    });
    // Recenter without animating — the page at _centerPage now shows the
    // same week the user just scrolled to, so this causes no visible jump,
    // it just resets how much headroom is left on either side.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_pageController.hasClients) {
        _pageController.jumpToPage(_centerPage);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the chevron buttons (a sibling widget, `_WeekHeader`) in sync:
    // if they change selectedWeekStartProvider directly, re-anchor and
    // recenter the PageView to match, same as settling a drag would.
    ref.listen(selectedWeekStartProvider, (previous, next) {
      if (next != _anchorWeekStart) {
        setState(() => _anchorWeekStart = next);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(_centerPage);
          }
        });
      }
    });

    final anchorCaloriesAsync = ref.watch(
      weeklyCaloriesProvider(_anchorWeekStart),
    );

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
          const SizedBox(height: 8),
          const Row(
            children: [
              _LegendItem(color: AppColors.proteinRing, label: 'Protein'),
              SizedBox(width: 12),
              _LegendItem(color: AppColors.carbsRing, label: 'Carbs'),
              SizedBox(width: 12),
              _LegendItem(color: AppColors.fatRing, label: 'Fat'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, page) {
                final pageWeekStart = _weekStartForPage(page);
                final caloriesAsync = ref.watch(
                  weeklyCaloriesProvider(pageWeekStart),
                );
                final goalAsync = ref.watch(calorieGoalProvider);

                return caloriesAsync.when(
                  data: (days) => goalAsync.when(
                    data: (goal) => _CaloriesBarChart(
                      days: days,
                      goal: goal,
                      selectedIndex: page == _centerPage ? _selectedIndex : null,
                      onDaySelected: (i) => setState(() => _selectedIndex = i),
                    ),
                    loading: () => _CaloriesBarChart(
                      days: days,
                      goal: null,
                      selectedIndex: page == _centerPage ? _selectedIndex : null,
                      onDaySelected: (i) => setState(() => _selectedIndex = i),
                    ),
                    error: (_, _) => _CaloriesBarChart(
                      days: days,
                      goal: null,
                      selectedIndex: page == _centerPage ? _selectedIndex : null,
                      onDaySelected: (i) => setState(() => _selectedIndex = i),
                    ),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                );
              },
            ),
          ),
          if (_selectedIndex != null)
            anchorCaloriesAsync.maybeWhen(
              data: (days) => _selectedIndex! < days.length
                  ? _DayBreakdown(day: days[_selectedIndex!])
                  : const SizedBox.shrink(),
              orElse: () => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// The calorie/macro breakdown for a single tapped day — shown below the
/// chart instead of a floating tooltip, since `BarChartData` (unlike
/// `LineChartData`) has no persistent `showingTooltipIndicators` mechanism.
class _DayBreakdown extends StatelessWidget {
  const _DayBreakdown({required this.day});

  final DailyCalories day;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('EEEE, MMM d').format(day.date),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('${day.totalCalories.round()} kcal'),
            Text(
              'Protein ${day.proteinG.round()}g · '
              'Carbs ${day.carbsG.round()}g · '
              'Fat ${day.fatG.round()}g',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _CaloriesBarChart extends StatelessWidget {
  const _CaloriesBarChart({
    required this.days,
    required this.goal,
    required this.selectedIndex,
    required this.onDaySelected,
  });

  final List<DailyCalories> days;
  final double? goal;
  final int? selectedIndex;
  final ValueChanged<int?> onDaySelected;

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
        barTouchData: BarTouchData(
          handleBuiltInTouches: false,
          touchCallback: (event, response) {
            if (event is! FlTapUpEvent) return;
            onDaySelected(response?.spot?.touchedBarGroupIndex);
          },
        ),
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
                () {
                  final day = days[i];
                  final pCal = day.proteinG * 4;
                  final cCal = day.carbsG * 4;
                  final fCal = day.fatG * 9;
                  final totalMacroCal = pCal + cCal + fCal;
                  final double targetTotal = day.totalCalories;

                  double finalP = pCal;
                  double finalC = cCal;
                  double finalF = fCal;

                  if (totalMacroCal > 0 && targetTotal > 0) {
                    finalP = (pCal / totalMacroCal) * targetTotal;
                    finalC = (cCal / totalMacroCal) * targetTotal;
                    finalF = (fCal / totalMacroCal) * targetTotal;
                  } else if (targetTotal > 0) {
                    finalC = targetTotal;
                  }

                  return BarChartRodData(
                    toY: targetTotal,
                    color: Colors.transparent,
                    width: 18,
                    borderRadius: BorderRadius.circular(4),
                    rodStackItems: targetTotal > 0
                        ? [
                            BarChartRodStackItem(0, finalP, AppColors.proteinRing),
                            BarChartRodStackItem(finalP, finalP + finalC, AppColors.carbsRing),
                            BarChartRodStackItem(finalP + finalC, finalP + finalC + finalF, AppColors.fatRing),
                          ]
                        : [],
                  );
                }(),
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
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Macro Breakdown (${formatWeekRange(weekStart)})',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: macroAsync.when(
              data: (macro) =>
                  _MacroDonut(macro: macro, goals: goalsAsync.asData?.value),
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
  const _MacroDonut({required this.macro, this.goals});

  final MacroBreakdown macro;

  /// The daily goals set in Profile, when loaded — multiplied by 7 for a
  /// weekly comparison against [macro], which sums a whole week of
  /// logging. Null (goal text simply omitted) while still loading.
  final DailyGoals? goals;

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
                grams: macro.proteinG,
                percent: macro.proteinPercent,
                goalG: goals == null ? null : goals!.proteinGoalG * 7,
              ),
              const SizedBox(height: 8),
              _LegendRow(
                color: AppColors.carbsRing,
                label: 'Carbs',
                grams: macro.carbsG,
                percent: macro.carbsPercent,
                goalG: goals == null ? null : goals!.carbsGoalG * 7,
              ),
              const SizedBox(height: 8),
              _LegendRow(
                color: AppColors.fatRing,
                label: 'Fat',
                grams: macro.fatG,
                percent: macro.fatPercent,
                goalG: goals == null ? null : goals!.fatGoalG * 7,
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
    required this.grams,
    required this.percent,
    this.goalG,
  });

  final Color color;
  final String label;
  final double grams;
  final double percent;

  /// This macro's weekly goal (daily goal from Profile x7), when known —
  /// shown alongside the logged grams so actual vs. target is visible at a
  /// glance, not just the relative percent split.
  final double? goalG;

  @override
  Widget build(BuildContext context) {
    final goal = goalG;
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
            '$label ${grams.round()}g (${(percent * 100).round()}%)'
            '${goal == null ? '' : ' · Goal ${goal.round()}g'}',
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
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final entry in _visibleEntries(history)) ...[
                Card(
                  elevation: 0,
                  color: AppColors.background,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('MMM d, yyyy').format(entry.loggedAt),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${displayWeight(entry.weightKg, unit: unit).toStringAsFixed(1)} $unit',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandGreen,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit weigh-in',
                          onPressed: () =>
                              showLogWeightDialog(context, ref, entryToEdit: entry),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        if (history.length > _collapsedCount) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => setState(() => _showAll = !_showAll),
              child: Text(
                _showAll ? 'Show less' : 'Show all (${history.length})',
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            key: const Key('weight-history-fullscreen-button'),
            icon: const Icon(Icons.fullscreen, size: 20),
            tooltip: 'View fullscreen',
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
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
            // Without these, a point near an edge draws its tooltip
            // centered on that point and lets it overflow past the
            // chart's bounds instead of shifting to stay fully visible.
            fitInsideHorizontally: true,
            fitInsideVertically: true,
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
          // Weekly-average trend, smoothing out day-to-day noise (water
          // weight, etc.) in the raw readings above.
          LineChartBarData(
            spots: [
              for (final point in computeWeeklyAverageTrend(history))
                FlSpot(point.x, displayWeight(point.avgWeightKg, unit: unit)),
            ],
            isCurved: true,
            color: AppColors.accentOrange,
            barWidth: 2,
            dotData: const FlDotData(show: false),
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
