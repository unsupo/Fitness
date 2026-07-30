import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_tables.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/diary_entry.dart';
import '../../../../core/entities/logged_quantity.dart';
import '../../domain/use_cases/logged_quantity_converter.dart';
import '../../domain/use_cases/rescale_diary_entry.dart';
import '../controllers/diary_providers.dart';

/// Edit quantity/meal type/time for [entry], or delete it outright.
/// Submits via [DiaryRepository.updateEntry]/`deleteEntry` and invalidates
/// [diaryEntriesProvider] (the whole family — the entry's date doesn't need
/// to be known here) so the diary reflects the change immediately.
Future<void> showEditDiaryEntryDialog(
  BuildContext context,
  WidgetRef ref,
  DiaryEntry entry,
) {
  final quantityController = TextEditingController(
    text: _trimTrailingZeros(entry.quantity.amount),
  );
  var mealType = entry.mealType;
  var loggedAt = entry.loggedAt;
  var selectedUnit = entry.quantity.unit;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          final availableUnits = LoggedQuantityConverter.getAvailableUnits(
            servingSize: entry.servingSize,
            servingUnit: entry.servingUnit,
          );

          return AlertDialog(
            title: Text(entry.foodName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        key: const Key('edit-quantity-field'),
                        controller: quantityController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Quantity'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        key: const Key('edit-quantity-unit-dropdown'),
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit'),
                        items: [
                          for (final unit in availableUnits)
                            DropdownMenuItem(value: unit, child: Text(unit)),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => selectedUnit = value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<MealType>(
                  key: const Key('edit-meal-type-dropdown'),
                  initialValue: mealType,
                  decoration: const InputDecoration(labelText: 'Meal'),
                  items: [
                    for (final type in MealType.values)
                      DropdownMenuItem(value: type, child: Text(type.label)),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => mealType = value);
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Time'),
                    TextButton(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: dialogContext,
                          initialTime: TimeOfDay.fromDateTime(loggedAt),
                        );
                        if (picked != null) {
                          setState(() {
                            loggedAt = DateTime(
                              loggedAt.year,
                              loggedAt.month,
                              loggedAt.day,
                              picked.hour,
                              picked.minute,
                            );
                          });
                        }
                      },
                      child: Text(TimeOfDay.fromDateTime(loggedAt).format(dialogContext)),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await ref.read(diaryRepositoryProvider).deleteEntry(entry.id);
                  ref.invalidate(diaryEntriesProvider);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete entry'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final newAmount = double.tryParse(quantityController.text);
                  if (newAmount == null || newAmount <= 0) return;

                  final newQuantity = LoggedQuantity(amount: newAmount, unit: selectedUnit);

                  var updated = entry;
                  if (newQuantity != entry.quantity) {
                    updated = rescaleDiaryEntry(updated, newQuantity: newQuantity);
                  }
                  updated = DiaryEntry(
                    id: updated.id,
                    loggedAt: loggedAt,
                    mealType: mealType,
                    foodName: updated.foodName,
                    foodId: updated.foodId,
                    quantity: updated.quantity,
                    calories: updated.calories,
                    proteinG: updated.proteinG,
                    carbsG: updated.carbsG,
                    fatG: updated.fatG,
                    servingSize: entry.servingSize,
                    servingUnit: entry.servingUnit,
                    imageUrl: entry.imageUrl,
                  );

                  await ref.read(diaryRepositoryProvider).updateEntry(updated);
                  ref.invalidate(diaryEntriesProvider);
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

/// "1" instead of "1.0", "0.5" as-is — a friendlier starting value in the
/// quantity field than Dart's default `double.toString()`.
String _trimTrailingZeros(double value) {
  final isWhole = value == value.roundToDouble();
  return isWhole ? value.round().toString() : value.toString();
}
