import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/use_cases/weight_unit.dart';
import '../controllers/analytics_providers.dart';

/// A single numeric weight text field (in the user's preferred unit system —
/// see [userProfileProvider].unitSystem) plus a goal-type dropdown.
///
/// With [entryToEdit] omitted: creates a new entry via
/// [AnalyticsRepository.logWeight] and invalidates [weightHistoryProvider].
/// With [entryToEdit] set: pre-fills the form from that entry, adds a
/// Delete button, and Save calls [AnalyticsRepository.updateWeightEntry]
/// instead.
Future<void> showLogWeightDialog(
  BuildContext context,
  WidgetRef ref, {
  WeightEntry? entryToEdit,
}) {
  final unitSystem = ref.read(userProfileProvider).value?.unitSystem ?? 'metric';
  final unit = weightUnitFor(unitSystem);
  final weightController = TextEditingController(
    text: entryToEdit == null
        ? ''
        : formatNumberForDisplay(displayWeight(entryToEdit.weightKg, unit: unit)),
  );
  var goalType = entryToEdit?.goalType ?? 'maintain';

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(entryToEdit == null ? 'Log weight' : 'Edit weigh-in'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: weightController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(labelText: 'Weight ($unit)'),
                ),
                const SizedBox(height: 16),
                DropdownButton<String>(
                  value: goalType,
                  items: const [
                    DropdownMenuItem(value: 'maintain', child: Text('Maintain')),
                    DropdownMenuItem(value: 'lose', child: Text('Lose')),
                    DropdownMenuItem(value: 'gain', child: Text('Gain')),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => goalType = value);
                  },
                ),
              ],
            ),
            actions: [
              if (entryToEdit != null)
                TextButton(
                  onPressed: () async {
                    await ref
                        .read(analyticsRepositoryProvider)
                        .deleteWeightEntry(entryToEdit.id);
                    ref.invalidate(weightHistoryProvider);
                    if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete'),
                ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final entered = double.tryParse(weightController.text);
                  if (entered == null) return;
                  final weightKg = parseDisplayWeight(entered, unit: unit);

                  if (entryToEdit == null) {
                    await ref
                        .read(analyticsRepositoryProvider)
                        .logWeight(weightKg, goalType);
                  } else {
                    await ref.read(analyticsRepositoryProvider).updateWeightEntry(
                      WeightEntry(
                        id: entryToEdit.id,
                        loggedAt: entryToEdit.loggedAt,
                        weightKg: weightKg,
                        goalType: goalType,
                      ),
                    );
                  }
                  ref.invalidate(weightHistoryProvider);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.brandGreen),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
