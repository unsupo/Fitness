import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/logged_quantity_converter.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The fuller Quick Add Modal replacing the simple 2-row FAB sheet.
class QuickAddModal extends ConsumerStatefulWidget {
  const QuickAddModal({super.key});

  @override
  ConsumerState<QuickAddModal> createState() => _QuickAddModalState();
}

class _QuickAddModalState extends ConsumerState<QuickAddModal> {
  final _searchController = TextEditingController();
  final Map<int, TextEditingController> _quantityControllers = {};
  final Map<int, String> _selectedUnits = {};
  MealType _selectedMeal = MealType.breakfast;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recentFoodsAsync = ref.watch(recentFoodsProvider);
    final searchResultsAsync = _query.isNotEmpty
        ? ref.watch(foodSearchProvider(_query))
        : const AsyncValue<List<FoodItem>>.data([]);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle/pill on top
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Search row
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search food or brand...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onChanged: (val) => setState(() => _query = val.trim()),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.accentOrange,
                  size: 28,
                ),
                onSelected: (value) {
                  Navigator.pop(context); // Close sheet
                  if (value == 'scan') {
                    context.push('/scanner');
                  } else if (value == 'photo') {
                    context.push('/food-recognition');
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'scan',
                    child: Row(
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: AppColors.accentOrange,
                        ),
                        SizedBox(width: 8),
                        Text('Scan Barcode'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'photo',
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, color: AppColors.accentOrange),
                        SizedBox(width: 8),
                        Text('Take Photo'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Meal selection dropdown
          DropdownButtonFormField<MealType>(
            initialValue: _selectedMeal,
            decoration: const InputDecoration(
              labelText: 'Target Meal Log',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: [
              for (final meal in MealType.values)
                DropdownMenuItem(
                  value: meal,
                  child: Text(
                    meal.name[0].toUpperCase() + meal.name.substring(1),
                  ),
                ),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _selectedMeal = val);
            },
          ),
          const SizedBox(height: 16),
          // Body content
          Expanded(
            child: _query.isEmpty
                ? recentFoodsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) =>
                        Center(child: Text('Error loading recent foods: $err')),
                    data: (foods) {
                      if (foods.isEmpty) {
                        return const Center(
                          child: Text(
                            'No recent foods found.\nSearch to log your first food!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return _FoodListSection(
                        title: 'Recent Foods',
                        foods: foods,
                        quantityControllers: _quantityControllers,
                        selectedUnits: _selectedUnits,
                        mealType: _selectedMeal,
                        onFoodLogged: () {
                          ref.invalidate(diaryEntriesProvider(DateTime.now()));
                        },
                      );
                    },
                  )
                : searchResultsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, _) =>
                        Center(child: Text('Search error: $err')),
                    data: (foods) {
                      if (foods.isEmpty) {
                        return const Center(
                          child: Text(
                            'No matches found.\nCheck the spelling or scan barcode.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        );
                      }
                      return _FoodListSection(
                        title: 'Search Results',
                        foods: foods,
                        quantityControllers: _quantityControllers,
                        selectedUnits: _selectedUnits,
                        mealType: _selectedMeal,
                        onFoodLogged: () {
                          ref.invalidate(diaryEntriesProvider(DateTime.now()));
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FoodListSection extends ConsumerStatefulWidget {
  const _FoodListSection({
    required this.title,
    required this.foods,
    required this.quantityControllers,
    required this.selectedUnits,
    required this.mealType,
    required this.onFoodLogged,
  });

  final String title;
  final List<FoodItem> foods;
  final Map<int, TextEditingController> quantityControllers;
  final Map<int, String> selectedUnits;
  final MealType mealType;
  final VoidCallback onFoodLogged;

  @override
  ConsumerState<_FoodListSection> createState() => _FoodListSectionState();
}

class _FoodListSectionState extends ConsumerState<_FoodListSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.separated(
            itemCount: widget.foods.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final food = widget.foods[index];
              final availableUnits = LoggedQuantityConverter.getAvailableUnits(
                servingSize: food.servingSize,
                servingUnit: food.servingUnit,
              );

              final qController = widget.quantityControllers[food.id] ??=
                  TextEditingController(text: '1');
              final selectedUnit = widget.selectedUnits[food.id] ??= 'serving';

              return Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () {
                    Navigator.pop(context); // Close sheet
                    context.push('/food-detail/${food.id}');
                  },
                  title: Text(
                    food.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${food.calories.round()} kcal | ${food.brand ?? 'Generic'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Quantity input
                      SizedBox(
                        width: 45,
                        child: TextField(
                          controller: qController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Unit selector dropdown
                      DropdownButton<String>(
                        value: selectedUnit,
                        underline: const SizedBox.shrink(),
                        isDense: true,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black,
                        ),
                        items: [
                          for (final unit in availableUnits)
                            DropdownMenuItem(value: unit, child: Text(unit)),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              widget.selectedUnits[food.id] = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      // Quick add + button
                      IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.accentOrange,
                          size: 28,
                        ),
                        onPressed: () async {
                          final double quantityValue =
                              double.tryParse(qController.text) ?? 1.0;
                          final servingMultiplier =
                              LoggedQuantityConverter.toServingMultiplier(
                                LoggedQuantity(
                                  amount: quantityValue,
                                  unit: selectedUnit,
                                ),
                                servingSize: food.servingSize,
                                servingUnit: food.servingUnit,
                              );

                          final calculatedCalories =
                              food.calories * servingMultiplier;
                          final calculatedProtein =
                              food.proteinG * servingMultiplier;
                          final calculatedCarbs =
                              food.carbsG * servingMultiplier;
                          final calculatedFat = food.fatG * servingMultiplier;

                          await ref
                              .read(diaryRepositoryProvider)
                              .logFood(
                                foodId: food.id,
                                quantity: LoggedQuantity(
                                  amount: quantityValue,
                                  unit: selectedUnit,
                                ),
                                mealType: widget.mealType,
                                loggedAt: DateTime.now(),
                                calories: calculatedCalories,
                                proteinG: calculatedProtein,
                                carbsG: calculatedCarbs,
                                fatG: calculatedFat,
                                servingSize: food.servingSize,
                                servingUnit: food.servingUnit,
                              );

                          widget.onFoodLogged();

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Logged ${quantityValue.toStringAsFixed(1)}x ${food.name} to ${widget.mealType.name}',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Helper function to display the Quick Add modal sheet.
void showQuickAddModal(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QuickAddModal(),
  );
}
