import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_set.dart';

/// Raw input collected from [LogExerciseCard]'s inline add-set form. The
/// card doesn't know the active session or the next `setNumber` — it just
/// hands back what the user typed and lets the caller (`LogActiveView`)
/// build the real [WorkoutSet] to log.
class LogSetInput {
  const LogSetInput({
    this.weight,
    this.reps,
    this.incline,
    this.speed,
    this.durationMinutes,
  });

  final double? weight;
  final int? reps;
  final double? incline;
  final double? speed;
  final double? durationMinutes;
}

/// One exercise's card in the active-session list: the machine name as a
/// heading, its already-logged sets as rows, and an inline form to log
/// another set. Branches its fields on `machine.muscleGroup == 'cardio'`
/// (the schema has no separate strength/cardio flag beyond that free-text
/// field) — weight/reps for strength machines, incline/speed/duration for
/// cardio machines.
class LogExerciseCard extends StatefulWidget {
  const LogExerciseCard({
    super.key,
    required this.machine,
    required this.sets,
    required this.onAddSet,
    required this.onEditSet,
  });

  final Machine machine;

  /// This machine's sets so far, already sorted by `setNumber`.
  final List<WorkoutSet> sets;

  final void Function(LogSetInput input) onAddSet;

  /// Tapping an already-logged set row opens the shared edit/delete dialog.
  final void Function(WorkoutSet set) onEditSet;

  @override
  State<LogExerciseCard> createState() => _LogExerciseCardState();
}

class _LogExerciseCardState extends State<LogExerciseCard> {
  final _weightController = TextEditingController();
  final _repsController = TextEditingController();
  final _inclineController = TextEditingController();
  final _speedController = TextEditingController();
  final _durationController = TextEditingController();

  bool get _isCardio => widget.machine.muscleGroup == 'cardio';

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    _inclineController.dispose();
    _speedController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _isCardio
        ? LogSetInput(
            incline: double.tryParse(_inclineController.text),
            speed: double.tryParse(_speedController.text),
            durationMinutes: double.tryParse(_durationController.text),
          )
        : LogSetInput(
            weight: double.tryParse(_weightController.text),
            reps: int.tryParse(_repsController.text),
          );
    widget.onAddSet(input);
    _weightController.clear();
    _repsController.clear();
    _inclineController.clear();
    _speedController.clear();
    _durationController.clear();
  }

  String _setLabel(WorkoutSet set) {
    if (_isCardio) {
      final duration = set.durationMinutes == null
          ? '?'
          : set.durationMinutes!.toStringAsFixed(0);
      final speed = set.speed == null ? '?' : set.speed!.toStringAsFixed(1);
      final incline = set.incline == null
          ? '?'
          : set.incline!.toStringAsFixed(0);
      return '$duration min @ $speed mph, incline $incline';
    }
    final weight = set.weight == null ? '?' : set.weight!.toStringAsFixed(0);
    return 'Set ${set.setNumber}: $weight ${set.unit} x ${set.reps ?? '?'}';
  }

  @override
  Widget build(BuildContext context) {
    final machineId = widget.machine.id;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.machine.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          if (widget.sets.isNotEmpty) ...[
            const SizedBox(height: 8),
            for (final set in widget.sets)
              InkWell(
                onTap: () => widget.onEditSet(set),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_setLabel(set)),
                      const Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: 12),
          if (_isCardio)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('incline-field-$machineId'),
                    controller: _inclineController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Incline'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('speed-field-$machineId'),
                    controller: _speedController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Speed'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('duration-field-$machineId'),
                    controller: _durationController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Minutes'),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('weight-field-$machineId'),
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Weight'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    key: Key('reps-field-$machineId'),
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: Key('add-set-button-$machineId'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
              ),
              onPressed: _submit,
              child: const Text('Add Set'),
            ),
          ),
        ],
      ),
    );
  }
}
