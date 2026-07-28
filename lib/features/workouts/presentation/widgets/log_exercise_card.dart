import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_set.dart';
import '../../domain/use_cases/previous_set_for.dart';

/// Values typed into one row's confirm action, resolved against the
/// previous set's values for whichever field was left blank. The card
/// doesn't know the persisted `WorkoutSet` shape — it just hands back what
/// the user (or the previous-value fallback) resolved to.
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

/// One exercise's card in the active-session list, Strong-style: every set
/// — logged or not-yet-confirmed — is its own row with inline editable
/// fields and a "Previous" hint (from [history], the machine's sets from
/// other sessions). A trailing blank row is always available; "Add Set"
/// appends another. Swiping a row away deletes it (if persisted) or just
/// drops the local draft (if not yet confirmed). See
/// docs/features/workouts-log-redesign.md.
class LogExerciseCard extends StatefulWidget {
  const LogExerciseCard({
    super.key,
    required this.machine,
    required this.sets,
    required this.history,
    required this.currentSessionId,
    required this.onConfirmSet,
    required this.onDeleteSet,
  });

  final Machine machine;

  /// This machine's already-persisted sets for the active session.
  final List<WorkoutSet> sets;

  /// This machine's sets from *other* sessions, used to compute each row's
  /// "Previous" hint via [previousSetFor].
  final List<WorkoutSet> history;

  final int currentSessionId;

  /// Called when a row is confirmed (new or edited), with its 1-based
  /// `setNumber` and the resolved input (typed value, or the previous
  /// value when a field was left blank).
  final void Function(int setNumber, LogSetInput input) onConfirmSet;

  /// Called when an already-persisted row is swiped away, with its real
  /// `workout_sets.id`.
  final void Function(int setId) onDeleteSet;

  @override
  State<LogExerciseCard> createState() => _LogExerciseCardState();
}

class _RowState {
  _RowState({this.persisted}) : localId = _nextLocalId++;

  static int _nextLocalId = 0;

  /// Stable identity independent of the row's position in [_rows] — used
  /// for the Dismissible key. Keying by list index would let a freshly
  /// added blank row inherit a just-dismissed row's key and inherit its
  /// (still-animating-away) Dismissible state instead of appearing fresh.
  final int localId;

  final WorkoutSet? persisted;
  final weightCtrl = TextEditingController();
  final repsCtrl = TextEditingController();
  final inclineCtrl = TextEditingController();
  final speedCtrl = TextEditingController();
  final durationCtrl = TextEditingController();

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
    inclineCtrl.dispose();
    speedCtrl.dispose();
    durationCtrl.dispose();
  }
}

class _LogExerciseCardState extends State<LogExerciseCard> {
  late List<_RowState> _rows;

  bool get _isCardio => widget.machine.muscleGroup == 'cardio';

  @override
  void initState() {
    super.initState();
    _rows = _buildRows(blankCount: 1);
  }

  @override
  void didUpdateWidget(covariant LogExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldIds = oldWidget.sets.map((s) => s.id).toList();
    final newIds = widget.sets.map((s) => s.id).toList();
    if (!listEquals(oldIds, newIds)) {
      final oldBlankCount = _rows.where((r) => r.persisted == null).length;
      for (final row in _rows) {
        row.dispose();
      }
      _rows = _buildRows(blankCount: oldBlankCount == 0 ? 1 : oldBlankCount);
    }
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  List<_RowState> _buildRows({required int blankCount}) {
    final sorted = List<WorkoutSet>.of(widget.sets)
      ..sort((a, b) => a.setNumber.compareTo(b.setNumber));
    return [
      for (final set in sorted)
        _RowState(persisted: set)
          ..weightCtrl.text = _fmt(set.weight)
          ..repsCtrl.text = set.reps?.toString() ?? ''
          ..inclineCtrl.text = _fmt(set.incline)
          ..speedCtrl.text = _fmt(set.speed)
          ..durationCtrl.text = _fmt(set.durationMinutes),
      for (var i = 0; i < blankCount; i++) _RowState(),
    ];
  }

  WorkoutSet? _previousFor(int setNumber) => previousSetFor(
    widget.history,
    setNumber,
    currentSessionId: widget.currentSessionId,
  );

  void _confirm(int index) {
    final row = _rows[index];
    final setNumber = index + 1;
    final prev = _previousFor(setNumber);

    final input = _isCardio
        ? LogSetInput(
            incline: double.tryParse(row.inclineCtrl.text) ?? prev?.incline,
            speed: double.tryParse(row.speedCtrl.text) ?? prev?.speed,
            durationMinutes:
                double.tryParse(row.durationCtrl.text) ?? prev?.durationMinutes,
          )
        : LogSetInput(
            weight: double.tryParse(row.weightCtrl.text) ?? prev?.weight,
            reps: int.tryParse(row.repsCtrl.text) ?? prev?.reps,
          );

    widget.onConfirmSet(setNumber, input);
  }

  void _removeRow(int index) {
    final row = _rows[index];
    if (row.persisted != null) {
      widget.onDeleteSet(row.persisted!.id);
    }
    setState(() {
      row.dispose();
      _rows.removeAt(index);
      if (_rows.every((r) => r.persisted != null)) {
        _rows.add(_RowState());
      }
    });
  }

  void _addBlankRow() => setState(() => _rows.add(_RowState()));

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
          const SizedBox(height: 8),
          for (var i = 0; i < _rows.length; i++)
            Dismissible(
              key: ValueKey(_rows[i].localId),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _removeRow(i),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 12),
                child: const Icon(Icons.delete_outline, color: Colors.red),
              ),
              child: _buildRow(machineId, i),
            ),
          const SizedBox(height: 4),
          TextButton.icon(
            key: const Key('add-set-row-button'),
            onPressed: _addBlankRow,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Set'),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(int machineId, int index) {
    final row = _rows[index];
    final setNumber = index + 1;
    final prev = _previousFor(setNumber);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 44, child: Text('Set $setNumber')),
          Expanded(
            child: Text(
              prev == null ? '—' : _previousLabel(prev),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (_isCardio) ...[
            SizedBox(
              width: 56,
              child: TextField(
                key: Key('incline-field-$machineId-$setNumber'),
                controller: row.inclineCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Incl',
                  hintText: _fmtOrNull(prev?.incline),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 56,
              child: TextField(
                key: Key('speed-field-$machineId-$setNumber'),
                controller: row.speedCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Spd',
                  hintText: _fmtOrNull(prev?.speed),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 56,
              child: TextField(
                key: Key('duration-field-$machineId-$setNumber'),
                controller: row.durationCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Min',
                  hintText: _fmtOrNull(prev?.durationMinutes),
                ),
              ),
            ),
          ] else ...[
            SizedBox(
              width: 64,
              child: TextField(
                key: Key('weight-field-$machineId-$setNumber'),
                controller: row.weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Wt',
                  hintText: _fmtOrNull(prev?.weight),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 56,
              child: TextField(
                key: Key('reps-field-$machineId-$setNumber'),
                controller: row.repsCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Reps',
                  hintText: prev?.reps?.toString(),
                ),
              ),
            ),
          ],
          IconButton(
            key: Key('confirm-set-button-$machineId-$setNumber'),
            icon: const Icon(Icons.check_circle_outline),
            color: AppColors.brandGreen,
            onPressed: () => _confirm(index),
          ),
        ],
      ),
    );
  }
}

String _previousLabel(WorkoutSet set) {
  if (set.weight != null && set.reps != null) {
    return '${_fmt(set.weight)} ${set.unit} x ${set.reps}';
  }
  final parts = <String>[
    if (set.durationMinutes != null) '${_fmt(set.durationMinutes)} min',
    if (set.speed != null) '${_fmt(set.speed)} mph',
    if (set.incline != null) '${_fmt(set.incline)}% incline',
  ];
  return parts.isEmpty ? '—' : parts.join(' · ');
}

String _fmt(double? value) {
  if (value == null) return '';
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}

String? _fmtOrNull(double? value) => value == null ? null : _fmt(value);
