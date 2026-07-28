import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/workout_set.dart';
import '../controllers/workout_repository_provider.dart';

/// Edit weight/reps (or incline/speed/duration for a cardio set), or delete
/// [set] outright. Shared by the Log tab's active-session exercise cards
/// and the History session detail page — the only two places a
/// `workout_sets` row is user-editable. Calls [onChanged] after a
/// successful save/delete so the caller can invalidate whichever provider
/// is currently showing this set.
Future<void> showEditWorkoutSetDialog(
  BuildContext context,
  WidgetRef ref,
  WorkoutSet set, {
  required VoidCallback onChanged,
}) {
  final isCardio =
      set.weight == null &&
      set.reps == null &&
      (set.incline != null ||
          set.speed != null ||
          set.durationMinutes != null);

  final weightController = TextEditingController(text: _fmt(set.weight));
  final repsController = TextEditingController(
    text: set.reps?.toString() ?? '',
  );
  final inclineController = TextEditingController(text: _fmt(set.incline));
  final speedController = TextEditingController(text: _fmt(set.speed));
  final durationController = TextEditingController(
    text: _fmt(set.durationMinutes),
  );

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(set.machineName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: isCardio
              ? [
                  TextField(
                    key: const Key('edit-set-incline-field'),
                    controller: inclineController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Incline'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('edit-set-speed-field'),
                    controller: speedController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Speed'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('edit-set-duration-field'),
                    controller: durationController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Minutes'),
                  ),
                ]
              : [
                  TextField(
                    key: const Key('edit-set-weight-field'),
                    controller: weightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Weight'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('edit-set-reps-field'),
                    controller: repsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Reps'),
                  ),
                ],
        ),
        actions: [
          TextButton(
            key: const Key('delete-set-button'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () async {
              await ref.read(workoutRepositoryProvider).deleteSet(set.id);
              onChanged();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete set'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            key: const Key('save-set-button'),
            style: TextButton.styleFrom(foregroundColor: AppColors.brandGreen),
            onPressed: () async {
              final updated = WorkoutSet(
                id: set.id,
                loggedAt: set.loggedAt,
                machineId: set.machineId,
                machineName: set.machineName,
                sessionId: set.sessionId,
                setNumber: set.setNumber,
                machineOrder: set.machineOrder,
                weight: isCardio ? null : double.tryParse(weightController.text),
                reps: isCardio ? null : int.tryParse(repsController.text),
                unit: set.unit,
                incline: isCardio ? double.tryParse(inclineController.text) : null,
                speed: isCardio ? double.tryParse(speedController.text) : null,
                durationMinutes: isCardio
                    ? double.tryParse(durationController.text)
                    : null,
                seatPosition: set.seatPosition,
                restSeconds: set.restSeconds,
                notes: set.notes,
              );
              await ref.read(workoutRepositoryProvider).updateSet(updated);
              onChanged();
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}

/// "65" instead of "65.0" as a starting field value.
String _fmt(double? value) {
  if (value == null) return '';
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}
