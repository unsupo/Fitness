import 'package:arndt_fitness/core/network/external_link_launcher.dart';
import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/compute_daily_totals.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/logged_quantity_converter.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/edit_food_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full nutrition detail for a single food, reached by tapping a diary entry.
class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({super.key, required this.foodId});

  final int foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodAsync = ref.watch(foodDetailsProvider(foodId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nourish'),
        actions: [
          foodAsync.maybeWhen(
            data: (food) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit food',
              onPressed: () => showEditFoodDialog(context, ref, food),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: foodAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Could not load food: $error')),
          data: (food) => _FoodDetailBody(food: food),
        ),
      ),
    );
  }
}

class _FoodDetailBody extends ConsumerStatefulWidget {
  const _FoodDetailBody({required this.food});

  final FoodItem food;

  @override
  ConsumerState<_FoodDetailBody> createState() => _FoodDetailBodyState();
}

class _FoodDetailBodyState extends ConsumerState<_FoodDetailBody> {
  final _quantityController = TextEditingController(text: '1');
  late String _selectedUnit;
  MealType _selectedMeal = MealType.breakfast;

  @override
  void initState() {
    super.initState();
    _selectedUnit = 'serving';
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableUnits = LoggedQuantityConverter.getAvailableUnits(
      servingSize: widget.food.servingSize,
      servingUnit: widget.food.servingUnit,
    );
    if (!availableUnits.contains(_selectedUnit)) {
      _selectedUnit = availableUnits.first;
    }

    final double quantity = double.tryParse(_quantityController.text) ?? 1.0;
    final servingMultiplier = LoggedQuantityConverter.toServingMultiplier(
      LoggedQuantity(amount: quantity, unit: _selectedUnit),
      servingSize: widget.food.servingSize,
      servingUnit: widget.food.servingUnit,
    );

    final selectedDate = ref.watch(selectedDateProvider);
    final entriesAsync = ref.watch(diaryEntriesProvider(selectedDate));
    final goalsAsync = ref.watch(dailyGoalsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FoodHero(imageUrl: widget.food.imageUrl),
        const SizedBox(height: 16),
        Text(
          widget.food.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (widget.food.sourceUrl != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openExternalUrl(widget.food.sourceUrl!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View source'),
            ),
          ),
        ],
        if (widget.food.brand != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.food.brand!,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
        if (widget.food.servingSize != null) ...[
          const SizedBox(height: 4),
          Text('Serving: ${widget.food.servingSize} ${widget.food.servingUnit ?? ''}'),
        ],
        const SizedBox(height: 16),

        // Logging form card
        Card(
          elevation: 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Log Food',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          for (final unit in availableUnits)
                            DropdownMenuItem(value: unit, child: Text(unit)),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedUnit = val);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MealType>(
                  initialValue: _selectedMeal,
                  decoration: const InputDecoration(
                    labelText: 'Meal',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    for (final meal in MealType.values)
                      DropdownMenuItem(
                        value: meal,
                        child: Text(meal.name[0].toUpperCase() + meal.name.substring(1)),
                      ),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedMeal = val);
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () async {
                    final calculatedCalories = widget.food.calories * servingMultiplier;
                    final calculatedProtein = widget.food.proteinG * servingMultiplier;
                    final calculatedCarbs = widget.food.carbsG * servingMultiplier;
                    final calculatedFat = widget.food.fatG * servingMultiplier;

                    await ref.read(diaryRepositoryProvider).logFood(
                          foodId: widget.food.id,
                          quantity: LoggedQuantity(amount: quantity, unit: _selectedUnit),
                          mealType: _selectedMeal,
                          loggedAt: DateTime.now(),
                          calories: calculatedCalories,
                          proteinG: calculatedProtein,
                          carbsG: calculatedCarbs,
                          fatG: calculatedFat,
                          servingSize: widget.food.servingSize,
                          servingUnit: widget.food.servingUnit,
                        );

                    ref.invalidate(diaryEntriesProvider(selectedDate));
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Log'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Live preview of macro targets
        goalsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (err, st) => const SizedBox.shrink(),
          data: (goals) => entriesAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (err, st) => const SizedBox.shrink(),
            data: (entries) {
              final currentTotals = computeDailyTotals(entries);
              final itemCalories = widget.food.calories * servingMultiplier;
              final itemProtein = widget.food.proteinG * servingMultiplier;
              final itemCarbs = widget.food.carbsG * servingMultiplier;
              final itemFat = widget.food.fatG * servingMultiplier;

              final projectedCalories = currentTotals.calories + itemCalories;
              final projectedProtein = currentTotals.proteinG + itemProtein;
              final projectedCarbs = currentTotals.carbsG + itemCarbs;
              final projectedFat = currentTotals.fatG + itemFat;

              return Card(
                elevation: 2,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Projected Daily Totals',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _ProjectedRow(
                        label: 'Calories',
                        current: currentTotals.calories,
                        projected: projectedCalories,
                        target: goals.calorieGoal.toDouble(),
                        unit: ' kcal',
                      ),
                      const SizedBox(height: 8),
                      _ProjectedRow(
                        label: 'Protein',
                        current: currentTotals.proteinG,
                        projected: projectedProtein,
                        target: goals.proteinGoalG.toDouble(),
                        unit: 'g',
                      ),
                      const SizedBox(height: 8),
                      _ProjectedRow(
                        label: 'Carbs',
                        current: currentTotals.carbsG,
                        projected: projectedCarbs,
                        target: goals.carbsGoalG.toDouble(),
                        unit: 'g',
                      ),
                      const SizedBox(height: 8),
                      _ProjectedRow(
                        label: 'Fat',
                        current: currentTotals.fatG,
                        projected: projectedFat,
                        target: goals.fatGoalG.toDouble(),
                        unit: 'g',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrition Facts (per serving)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.food.calories.round()} calories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _MacroRow(label: 'Protein', grams: widget.food.proteinG),
              _MacroRow(label: 'Carbs', grams: widget.food.carbsG),
              _MacroRow(label: 'Fat', grams: widget.food.fatG),
              if (widget.food.fiberG != null)
                _MacroRow(label: 'Fiber', grams: widget.food.fiberG!),
              if (widget.food.sugarG != null)
                _MacroRow(label: 'Sugar', grams: widget.food.sugarG!),
              if (widget.food.sodiumMg != null)
                _MacroRow(label: 'Sodium', grams: widget.food.sodiumMg!, unit: 'mg'),
            ],
          ),
        ),
        if (widget.food.isEstimate == true) ...[
          const SizedBox(height: 12),
          const Text(
            'Estimated values',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProjectedRow extends StatelessWidget {
  const _ProjectedRow({
    required this.label,
    required this.current,
    required this.projected,
    required this.target,
    required this.unit,
  });

  final String label;
  final double current;
  final double projected;
  final double target;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              '${current.round()} → ${projected.round()} / ${target.round()}$unit',
              style: TextStyle(
                color: projected > target ? Colors.red : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: target > 0 ? (projected / target).clamp(0.0, 1.0) : 0.0,
            backgroundColor: AppColors.background,
            color: projected > target ? Colors.red : AppColors.accentOrange,
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

/// A full-width, rounded, shadowed banner when the food has a real photo —
/// a showcase, not just a list-row icon. Falls back to the compact
/// [FoodThumbnail] placeholder treatment (matching every other place a food
/// image can appear) when there's no photo at all. A photo that's set but
/// fails to load (dead link, hotlink-blocked CDN, etc.) still renders the
/// banner shape with a large centered placeholder icon inside it, rather
/// than silently shrinking back down — the URL is real, it just isn't
/// loading right now.
class _FoodHero extends StatelessWidget {
  const _FoodHero({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null) {
      return Center(child: FoodThumbnail(imageUrl: url, size: 128));
    }

    return Container(
      key: const Key('food-hero-banner'),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _bannerPlaceholder(),
        errorBuilder: (context, error, stackTrace) => _bannerPlaceholder(),
      ),
    );
  }

  Widget _bannerPlaceholder() => Container(
    color: AppColors.background,
    alignment: Alignment.center,
    child: const Icon(
      Icons.restaurant,
      size: 56,
      color: AppColors.textSecondary,
    ),
  );
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.label, required this.grams, this.unit = 'g'});

  final String label;
  final double grams;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text('${grams.round()}$unit')],
      ),
    );
  }
}
