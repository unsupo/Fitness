import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_tables.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/diary_entry.dart';
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
    text: _trimTrailingZeros(entry.quantity),
  );
  var mealType = entry.mealType;
  var loggedAt = entry.loggedAt;

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: Text(entry.foodName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const Key('edit-quantity-field'),
                  controller: quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Quantity'),
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
                  final newQuantity = double.tryParse(quantityController.text);
                  if (newQuantity == null || newQuantity <= 0) return;

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
