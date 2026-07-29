import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/use_cases/compute_weekly_averages.dart';
import '../../domain/use_cases/estimate_tdee.dart';
import '../../domain/use_cases/project_weight_trajectory.dart';
import '../../domain/use_cases/weight_unit.dart';
import '../controllers/analytics_providers.dart';
import 'edit_weight_goal_dialog.dart';
import 'fullscreen_chart_page.dart';

/// "If I keep eating at my calorie goal, when do I hit my target weight?" —
/// a projected trajectory from the latest logged weight to
/// [UserProfile.targetWeightKg], with weekly dates on the x-axis. Needs a
/// weigh-in (from the Weight section above) and a complete profile (age,
/// sex, height, activity level, target weight) to compute; prompts for
/// whichever is missing.
class WeightGoalSection extends ConsumerWidget {
  const WeightGoalSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(weightHistoryProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final calorieGoalAsync = ref.watch(calorieGoalProvider);

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weight Goal',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              profileAsync.maybeWhen(
                data: (profile) => IconButton(
                  icon: const Icon(Icons.settings_outlined, size: 20),
                  tooltip: 'Edit weight goal',
                  onPressed: () =>
                      showEditWeightGoalDialog(context, ref, profile),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          historyAsync.when(
            loading: () => const _CenteredSpinner(),
            error: (error, _) => Text('Error: $error'),
            data: (history) {
              if (history.isEmpty) {
                return const Text(
                  'Log your weight above to see a projection.',
                  style: TextStyle(color: AppColors.textSecondary),
                );
              }
              return profileAsync.when(
                loading: () => const _CenteredSpinner(),
                error: (error, _) => Text('Error: $error'),
                data: (profile) {
                  if (!profile.isCompleteForProjection) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Set a target weight and a few profile details to '
                          'see when you\'ll reach it.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () =>
                              showEditWeightGoalDialog(context, ref, profile),
                          child: const Text('Set up weight goal'),
                        ),
                      ],
                    );
                  }
                  return calorieGoalAsync.when(
                    loading: () => const _CenteredSpinner(),
                    error: (error, _) => Text('Error: $error'),
                    data: (calorieGoal) => _ProjectionBody(
                      history: history,
                      profile: profile,
                      calorieGoal: calorieGoal,
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CenteredSpinner extends StatelessWidget {
  const _CenteredSpinner();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 24),
    child: Center(child: CircularProgressIndicator()),
  );
}

class _ProjectionBody extends StatelessWidget {
  const _ProjectionBody({
    required this.history,
    required this.profile,
    required this.calorieGoal,
  });

  final List<WeightEntry> history;
  final UserProfile profile;
  final double calorieGoal;

  @override
  Widget build(BuildContext context) {
    final weeklyAverages = computeWeeklyAverages(history);
    // The projection's "current weight" is the latest weekly average, not
    // just the single most recent raw entry — smooths day-to-day
    // water-weight noise and is what actually recalculates the projection
    // whenever new weigh-ins (including a bulk CSV import) come in.
    final currentWeightKg = weeklyAverages.last.avgWeightKg;
    final tdee = estimateTdee(profile: profile, weightKg: currentWeightKg);
    final trajectory = projectWeightTrajectory(
      currentWeightKg: currentWeightKg,
      targetWeightKg: profile.targetWeightKg!,
      tdee: tdee,
      calorieGoal: calorieGoal,
      // Anchor the projection at the same point the actual series ends
      // (the latest weekly average's weekStart), not "now" — weekStart is
      // often several days before today, so using DateTime.now() here left
      // a visible gap between the last real point and the first projected
      // one even though they're the same weight value.
      startDate: weeklyAverages.last.weekStart,
    );

    if (trajectory.length == 1) {
      return const Text(
        'At your current calorie goal, you\'re not projected to move '
        'toward your target weight. Adjust your calorie goal or target '
        'to see a projection.',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    final target = trajectory.last;
    final unit = weightUnitFor(profile.unitSystem);
    final displayTarget = displayWeight(profile.targetWeightKg!, unit: unit);

    // A single shared x-axis (days since the earliest weekly average, the
    // "starting point" of the tracked journey) so real past weeks and the
    // projected future share one continuous timeline instead of two
    // disconnected scales.
    final origin = weeklyAverages.first.weekStart;
    double xFor(DateTime date) => date.difference(origin).inDays.toDouble();

    final actualSpots = [
      for (final week in weeklyAverages)
        FlSpot(xFor(week.weekStart), displayWeight(week.avgWeightKg, unit: unit)),
    ];
    final projectedSpots = [
      for (final point in trajectory)
        FlSpot(xFor(point.date), displayWeight(point.weightKg, unit: unit)),
    ];

    final maxX = xFor(target.date);
    final labelInterval = (maxX / 6).clamp(1, 999).roundToDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Projected to reach ${displayTarget.round()} $unit by '
                '${DateFormat('MMM d, yyyy').format(target.date)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              key: const Key('weight-goal-fullscreen-button'),
              icon: const Icon(Icons.fullscreen, size: 20),
              tooltip: 'View fullscreen',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FullScreenChartPage(
                    title: 'Weight Goal',
                    chart: _ProjectionChart(
                      actualSpots: actualSpots,
                      projectedSpots: projectedSpots,
                      origin: origin,
                      maxX: maxX,
                      labelInterval: labelInterval,
                      displayTarget: displayTarget,
                      unit: unit,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _ProjectionChart(
          height: 160,
          actualSpots: actualSpots,
          projectedSpots: projectedSpots,
          origin: origin,
          maxX: maxX,
          labelInterval: labelInterval,
          displayTarget: displayTarget,
          unit: unit,
        ),
      ],
    );
  }
}

/// The Weight Goal chart itself, reused both inline (small) and in the
/// fullscreen landscape view. Stateful so a touched point's tooltip
/// persists until the user taps elsewhere, rather than only while actively
/// touching (fl_chart's built-in behavior, which reads as "nothing
/// happened" on a real device — a tap is a quick down-then-up).
class _ProjectionChart extends StatefulWidget {
  const _ProjectionChart({
    required this.actualSpots,
    required this.projectedSpots,
    required this.origin,
    required this.maxX,
    required this.labelInterval,
    required this.displayTarget,
    required this.unit,
    this.height,
  });

  final List<FlSpot> actualSpots;
  final List<FlSpot> projectedSpots;
  final DateTime origin;
  final double maxX;
  final double labelInterval;
  final double displayTarget;
  final String unit;

  /// A fixed chart height for the small inline card view; `null` (the
  /// fullscreen view) fills whatever bounded space its ancestor gives it.
  final double? height;

  @override
  State<_ProjectionChart> createState() => _ProjectionChartState();
}

class _ProjectionChartState extends State<_ProjectionChart> {
  List<LineBarSpot> _touchedSpots = [];

  @override
  Widget build(BuildContext context) {
    final chart = LineChart(
        LineChartData(
          minX: 0,
          maxX: widget.maxX,
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
                    '${spot.barIndex == 0 ? 'Actual' : 'Projected'}\n'
                    '${DateFormat('MMM d, yyyy').format(widget.origin.add(Duration(days: spot.x.round())))}\n'
                    '${spot.y.toStringAsFixed(1)} ${widget.unit}',
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
                interval: widget.labelInterval,
                getTitlesWidget: (value, meta) {
                  final date = widget.origin.add(Duration(days: value.round()));
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('MMM d').format(date),
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(
                y: widget.displayTarget,
                color: AppColors.accentOrange,
                strokeWidth: 1.5,
                dashArray: [6, 4],
              ),
            ],
          ),
          lineBarsData: [
            // Projected (green) first, Actual (orange) last — fl_chart
            // paints later entries on top, and the two series share their
            // boundary point exactly (by design, see the projection's
            // startDate above), so Actual must be on top there or its dot
            // is invisible, hidden under Projected's.
            LineChartBarData(
              spots: widget.projectedSpots,
              isCurved: false,
              dashArray: [6, 4],
              color: AppColors.brandGreen,
              barWidth: 2.5,
              dotData: const FlDotData(show: true),
            ),
            LineChartBarData(
              spots: widget.actualSpots,
              isCurved: false,
              color: AppColors.accentOrange,
              barWidth: 2.5,
              // Slightly larger than the projected series' default dot so
              // it's visibly distinct even at their shared boundary point.
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                      radius: 5,
                      color: AppColors.accentOrange,
                      strokeWidth: 0,
                    ),
              ),
            ),
          ],
        ),
      );

    const legend = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _LegendDot(color: AppColors.accentOrange, label: 'Actual (weekly avg)'),
        SizedBox(width: 16),
        _LegendDot(color: AppColors.brandGreen, label: 'Projected'),
      ],
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(() => _touchedSpots = []),
      child: widget.height != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: widget.height, child: chart),
                const SizedBox(height: 8),
                legend,
              ],
            )
          : Column(
              children: [
                Expanded(child: chart),
                const SizedBox(height: 8),
                legend,
              ],
            ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

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
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
