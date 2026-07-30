import 'package:arndt_fitness/core/network/external_link_launcher.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/logged_quantity_converter.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:arndt_fitness/features/recipes/domain/use_cases/compute_recipe_totals.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Trims a whole-number double to "2" instead of "2.0"; keeps decimals as-is.
String _formatNumber(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// One in-progress ingredient row on [AddRecipePage] — not yet a saved
/// [RecipeIngredient]. Holds its own text controllers and the [FoodItem]
/// selected (if any) from the search suggestions.
class _IngredientDraft {
  _IngredientDraft() : id = _nextId++;

  /// Pre-fills a draft from an already-saved [RecipeIngredient] (edit mode).
  /// [RecipeIngredient] only stores totals (`quantity * food.macro`), so the
  /// per-unit [FoodItem] is recovered by dividing back out.
  factory _IngredientDraft.fromIngredient(RecipeIngredient ingredient) {
    final draft = _IngredientDraft();
    final quantity = LoggedQuantityConverter.toServingMultiplier(
      ingredient.quantity,
      servingSize: ingredient.servingSize,
      servingUnit: ingredient.servingUnit,
    );
    final divisor = quantity == 0.0 ? 1.0 : quantity;
    draft.foodQueryController.text = ingredient.foodName;
    draft.quantityController.text = _formatNumber(ingredient.quantity.amount);
    draft.selectedUnit = ingredient.quantity.unit;
    draft.selectedFood = FoodItem(
      id: ingredient.foodId,
      name: ingredient.foodName,
      calories: ingredient.calories / divisor,
      proteinG: ingredient.proteinG / divisor,
      carbsG: ingredient.carbsG / divisor,
      fatG: ingredient.fatG / divisor,
      servingSize: ingredient.servingSize,
      servingUnit: ingredient.servingUnit,
    );
    return draft;
  }

  static int _nextId = 0;

  final int id;
  final TextEditingController foodQueryController = TextEditingController();
  final TextEditingController quantityController = TextEditingController(
    text: '1',
  );
  FoodItem? selectedFood;
  String selectedUnit = 'serving';

  void dispose() {
    foodQueryController.dispose();
    quantityController.dispose();
  }
}

/// Create a new recipe from existing foods, or edit an existing one when
/// [recipeToEdit] is passed (via `context.push('/recipes/add', extra: recipe)`):
/// name, servings, a growing list of ingredient rows (food picker + quantity),
/// a live macro preview, and a Save button that calls `createRecipe`/
/// `updateRecipe` then pops back to `/recipes`.
class AddRecipePage extends ConsumerStatefulWidget {
  const AddRecipePage({super.key, this.recipeToEdit});

  final Recipe? recipeToEdit;

  @override
  ConsumerState<AddRecipePage> createState() => _AddRecipePageState();
}

class _AddRecipePageState extends ConsumerState<AddRecipePage> {
  late final _nameController = TextEditingController(
    text: widget.recipeToEdit?.name ?? '',
  );
  late final _servingsController = TextEditingController(
    text: widget.recipeToEdit != null
        ? _formatNumber(widget.recipeToEdit!.servings)
        : '1',
  );
  late final List<_IngredientDraft> _ingredients =
      widget.recipeToEdit != null && widget.recipeToEdit!.ingredients.isNotEmpty
      ? [
          for (final ing in widget.recipeToEdit!.ingredients)
            _IngredientDraft.fromIngredient(ing),
        ]
      : [_IngredientDraft()];
  String? _error;
  bool _ingredientsExpanded = true;

  bool get _isEditing => widget.recipeToEdit != null;

  @override
  void dispose() {
    _nameController.dispose();
    _servingsController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  /// Builds an unsaved [Recipe] from current form state, for computing the
  /// live macro preview via the domain use cases — never sent to the
  /// repository as-is.
  Recipe get _draftRecipe {
    final servings = double.tryParse(_servingsController.text) ?? 1;
    final ingredients = <RecipeIngredient>[];

    for (final draft in _ingredients) {
      final food = draft.selectedFood;
      if (food == null) continue;
      final amount = double.tryParse(draft.quantityController.text) ?? 0;
      final loggedQty = LoggedQuantity(amount: amount, unit: draft.selectedUnit);
      final quantity = LoggedQuantityConverter.toServingMultiplier(
        loggedQty,
        servingSize: food.servingSize,
        servingUnit: food.servingUnit,
      );
      ingredients.add(
        RecipeIngredient(
          foodId: food.id,
          foodName: food.name,
          quantity: loggedQty,
          calories: quantity * food.calories,
          proteinG: quantity * food.proteinG,
          carbsG: quantity * food.carbsG,
          fatG: quantity * food.fatG,
          servingSize: food.servingSize,
          servingUnit: food.servingUnit,
        ),
      );
    }

    return Recipe(
      id: 0,
      name: _nameController.text,
      servings: servings,
      ingredients: ingredients,
    );
  }

  void _addIngredient() {
    setState(() => _ingredients.add(_IngredientDraft()));
  }

  void _removeIngredient(int index) {
    setState(() {
      _ingredients[index].dispose();
      _ingredients.removeAt(index);
    });
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final servings = double.tryParse(_servingsController.text);
    final selected = _ingredients
        .where((draft) => draft.selectedFood != null)
        .toList();

    if (name.isEmpty || servings == null || servings <= 0 || selected.isEmpty) {
      setState(
        () => _error =
            'Enter a name, servings greater than 0, and at least one ingredient.',
      );
      return;
    }

    final ingredientsArg = [
      for (final draft in selected)
        (
          foodId: draft.selectedFood!.id,
          quantity: LoggedQuantityConverter.toServingMultiplier(
            LoggedQuantity(
              amount: double.tryParse(draft.quantityController.text) ?? 0,
              unit: draft.selectedUnit,
            ),
            servingSize: draft.selectedFood!.servingSize,
            servingUnit: draft.selectedFood!.servingUnit,
          ),
          quantityUnit: draft.selectedUnit,
        ),
    ];

    final repo = ref.read(recipeRepositoryProvider);
    if (_isEditing) {
      await repo.updateRecipe(
        recipeId: widget.recipeToEdit!.id,
        name: name,
        servings: servings,
        ingredients: ingredientsArg,
      );
    } else {
      await repo.createRecipe(
        name: name,
        servings: servings,
        ingredients: ingredientsArg,
      );
    }

    ref.invalidate(recipesListProvider);
    // A recipe's name is joined live into diary entries logged from it (see
    // RecipesListPage), so an edit here can change what the diary displays.
    ref.invalidate(diaryEntriesProvider);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _delete() async {
    final recipe = widget.recipeToEdit;
    if (recipe == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete recipe?'),
        content: Text(
          'This removes "${recipe.name}" permanently. Diary entries already '
          'logged from it keep their calories but will no longer show its name.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(recipeRepositoryProvider).deleteRecipe(recipe.id);
    ref.invalidate(recipesListProvider);
    ref.invalidate(diaryEntriesProvider);

    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _draftRecipe;
    final totals = recipeTotals(recipe);
    final perServing = recipePerServing(recipe);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          },
        ),
        title: Text(_isEditing ? 'Edit Recipe' : 'Add Recipe'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete recipe',
              onPressed: _delete,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              key: const Key('name-field'),
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Recipe name'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('servings-field'),
              controller: _servingsController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(labelText: 'Servings'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            InkWell(
              onTap: () =>
                  setState(() => _ingredientsExpanded = !_ingredientsExpanded),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ingredients (${_ingredients.length})',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Icon(
                    _ingredientsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (_ingredientsExpanded) ...[
              for (var i = 0; i < _ingredients.length; i++)
                _IngredientRow(
                  key: ValueKey(_ingredients[i].id),
                  index: i,
                  draft: _ingredients[i],
                  onChanged: () => setState(() {}),
                  onRemove: _ingredients.length > 1 ? () => _removeIngredient(i) : null,
                ),
              TextButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add),
                label: const Text('Add ingredient'),
              ),
            ],
            const SizedBox(height: 12),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${totals.calories.round()} cal total',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${perServing.calories.round()} cal / serving',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends ConsumerWidget {
  const _IngredientRow({
    super.key,
    required this.index,
    required this.draft,
    required this.onChanged,
    this.onRemove,
  });

  final int index;
  final _IngredientDraft draft;
  final VoidCallback onChanged;
  final VoidCallback? onRemove;

  void _selectFood(FoodItem food) {
    draft.selectedFood = food;
    draft.foodQueryController.text = food.name;
    draft.selectedUnit = food.servingUnit ?? 'serving';
    onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = draft.foodQueryController.text;
    final showRecent = draft.selectedFood == null && query.isEmpty;
    final showSearch = draft.selectedFood == null && query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  key: Key('food-field-$index'),
                  controller: draft.foodQueryController,
                  decoration: const InputDecoration(labelText: 'Food'),
                  onChanged: (_) {
                    draft.selectedFood = null;
                    onChanged();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextField(
                  key: Key('quantity-field-$index'),
                  controller: draft.quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Qty'),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 90,
                child: StatefulBuilder(
                  builder: (context, setState) {
                    final availableUnits = LoggedQuantityConverter.getAvailableUnits(
                      servingSize: draft.selectedFood?.servingSize,
                      servingUnit: draft.selectedFood?.servingUnit,
                    );
                    if (!availableUnits.contains(draft.selectedUnit)) {
                      draft.selectedUnit = 'serving';
                    }
                    return DropdownButtonFormField<String>(
                      key: Key('unit-field-$index'),
                      initialValue: draft.selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      ),
                      isExpanded: true,
                      items: [
                        for (final unit in availableUnits)
                          DropdownMenuItem(value: unit, child: Text(unit, style: const TextStyle(fontSize: 12))),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => draft.selectedUnit = value);
                          onChanged();
                        }
                      },
                    );
                  },
                ),
              ),
              if (onRemove != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  key: Key('remove-ingredient-$index'),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Remove ingredient',
                  onPressed: onRemove,
                ),
              ],
            ],
          ),
          if (showRecent)
            Consumer(
              builder: (context, ref, _) {
                final recentAsync = ref.watch(recentFoodsProvider);
                return recentAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (foods) {
                    if (foods.isEmpty) return const SizedBox.shrink();
                    return _FoodResultSection(
                      label: 'Recent',
                      children: [
                        for (final food in foods)
                          _FoodResultTile(
                            name: food.name,
                            imageUrl: food.imageUrl,
                            sourceUrl: food.sourceUrl,
                            onTap: () => _selectFood(food),
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          if (showSearch) ...[
            Consumer(
              builder: (context, ref, _) {
                final suggestionsAsync = ref.watch(foodSearchProvider(query));
                return suggestionsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (foods) => Column(
                    children: [
                      for (final food in foods)
                        _FoodResultTile(
                          name: food.name,
                          imageUrl: food.imageUrl,
                          sourceUrl: food.sourceUrl,
                          onTap: () => _selectFood(food),
                        ),
                    ],
                  ),
                );
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final onlineAsync = ref.watch(onlineFoodSearchProvider(query));
                return onlineAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (error, stackTrace) => const SizedBox.shrink(),
                  data: (candidates) {
                    if (candidates.isEmpty) return const SizedBox.shrink();
                    return _FoodResultSection(
                      label: 'From OpenFoodFacts',
                      children: [
                        for (final candidate in candidates)
                          _FoodResultTile(
                            name: candidate.name,
                            imageUrl: candidate.imageUrl,
                            sourceUrl: candidate.sourceUrl,
                            onTap: () {
                              ref
                                  .read(diaryRepositoryProvider)
                                  .importOnlineFood(candidate)
                                  .then(_selectFood);
                            },
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// A labeled group of food-search result tiles ("Recent", "From
/// OpenFoodFacts").
class _FoodResultSection extends StatelessWidget {
  const _FoodResultSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

/// One selectable food result — a thumbnail, name, and (when a real source
/// link is known) a small external-link icon to view it online without
/// selecting it.
class _FoodResultTile extends StatelessWidget {
  const _FoodResultTile({
    required this.name,
    required this.onTap,
    this.imageUrl,
    this.sourceUrl,
  });

  final String name;
  final String? imageUrl;
  final String? sourceUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = sourceUrl;
    return ListTile(
      dense: true,
      leading: FoodThumbnail(imageUrl: imageUrl),
      title: Text(name),
      trailing: url == null
          ? null
          : IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              tooltip: 'View source',
              onPressed: () => openExternalUrl(url),
            ),
      onTap: onTap,
    );
  }
}
