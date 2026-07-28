import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/food_item.dart';
import '../controllers/diary_providers.dart';

/// Edits a food's own record — name, brand, serving, macros, image, and
/// source link — as opposed to `showEditDiaryEntryDialog`'s quantity/
/// mealType/loggedAt, which only touch the `food_log` row. Reached from
/// `FoodDetailPage`. Since a food's name/image/link are joined live into
/// diary entries (not frozen at log time), editing here changes how
/// already-logged entries display too.
Future<void> showEditFoodDialog(
  BuildContext context,
  WidgetRef ref,
  FoodItem current,
) {
  String display(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : value.toString();

  final nameController = TextEditingController(text: current.name);
  final brandController = TextEditingController(text: current.brand ?? '');
  final servingSizeController = TextEditingController(
    text: current.servingSize == null ? '' : display(current.servingSize!),
  );
  final servingUnitController = TextEditingController(
    text: current.servingUnit ?? '',
  );
  final caloriesController = TextEditingController(text: display(current.calories));
  final proteinController = TextEditingController(text: display(current.proteinG));
  final carbsController = TextEditingController(text: display(current.carbsG));
  final fatController = TextEditingController(text: display(current.fatG));
  final imageUrlController = TextEditingController(text: current.imageUrl ?? '');
  final sourceUrlController = TextEditingController(text: current.sourceUrl ?? '');
  var error = '';

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Edit food'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('food-name-field'),
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('food-brand-field'),
                    controller: brandController,
                    decoration: const InputDecoration(labelText: 'Brand'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('food-serving-size-field'),
                          controller: servingSizeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Serving size'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          key: const Key('food-serving-unit-field'),
                          controller: servingUnitController,
                          decoration: const InputDecoration(labelText: 'Unit'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('food-calories-field'),
                    controller: caloriesController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Calories'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('food-protein-field'),
                          controller: proteinController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Protein (g)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          key: const Key('food-carbs-field'),
                          controller: carbsController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Carbs (g)'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          key: const Key('food-fat-field'),
                          controller: fatController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(labelText: 'Fat (g)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('food-image-url-field'),
                    controller: imageUrlController,
                    decoration: const InputDecoration(labelText: 'Image URL'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('food-source-url-field'),
                    controller: sourceUrlController,
                    decoration: const InputDecoration(labelText: 'Source link'),
                  ),
                  if (error.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(error, style: const TextStyle(color: Colors.red)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final calories = double.tryParse(caloriesController.text);
                  final protein = double.tryParse(proteinController.text);
                  final carbs = double.tryParse(carbsController.text);
                  final fat = double.tryParse(fatController.text);

                  if (name.isEmpty ||
                      calories == null ||
                      protein == null ||
                      carbs == null ||
                      fat == null) {
                    setState(
                      () => error = 'Enter a name and valid numbers for calories/macros.',
                    );
                    return;
                  }

                  final brand = brandController.text.trim();
                  final servingSize = double.tryParse(servingSizeController.text);
                  final servingUnit = servingUnitController.text.trim();
                  final imageUrl = imageUrlController.text.trim();
                  final sourceUrl = sourceUrlController.text.trim();

                  final updated = FoodItem(
                    id: current.id,
                    name: name,
                    brand: brand.isEmpty ? null : brand,
                    calories: calories,
                    proteinG: protein,
                    carbsG: carbs,
                    fatG: fat,
                    servingSize: servingSize,
                    servingUnit: servingUnit.isEmpty ? null : servingUnit,
                    fiberG: current.fiberG,
                    sugarG: current.sugarG,
                    sodiumMg: current.sodiumMg,
                    isEstimate: current.isEstimate,
                    imageUrl: imageUrl.isEmpty ? null : imageUrl,
                    sourceUrl: sourceUrl.isEmpty ? null : sourceUrl,
                  );

                  await ref.read(diaryRepositoryProvider).updateFood(updated);
                  ref.invalidate(foodDetailsProvider(current.id));
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
