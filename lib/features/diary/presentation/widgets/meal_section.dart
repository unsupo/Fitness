import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/core/entities/logged_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/format_quantity.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/logged_quantity_converter.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/rescale_diary_entry.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:arndt_fitness/features/recipes/domain/use_cases/rescale_recipe_ingredient.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'edit_diary_entry_dialog.dart';

/// A `SectionCard` for one meal type: heading + one row per entry, plus a
/// small orange "+" button that pushes the scanner.
///
/// Plain food entries are a single swipeable/inline-editable row. Entries
/// logged from a recipe render as a collapsible header (name/quantity/
/// calories) that expands to show the recipe's own ingredients as indented
/// sub-rows — each independently swipeable and inline-editable, mirroring
/// the Workouts feature's set-row pattern (`LogExerciseCard`): a `Dismissible`
/// with a trailing delete-icon background, and a small numeric field +
/// checkmark button to confirm an edited quantity, rather than a modal.
class MealSection extends ConsumerStatefulWidget {
  const MealSection({super.key, required this.mealType, required this.entries});

  final MealType mealType;
  final List<DiaryEntry> entries;

  @override
  ConsumerState<MealSection> createState() => _MealSectionState();
}

class _MealSectionState extends ConsumerState<MealSection> {
  /// Entries swiped away locally, hidden immediately while the delete
  /// request is in flight — `entries` comes from a Riverpod provider one
  /// level up, so without this a `Dismissible` would still be in the tree
  /// on the next build (before the provider refetches), which Flutter
  /// treats as an error ("a dismissed Dismissible widget is still part of
  /// the tree").
  final Set<int> _locallyDeletedEntryIds = {};

  void _deleteEntry(int id) {
    setState(() => _locallyDeletedEntryIds.add(id));
    ref.read(diaryRepositoryProvider).deleteEntry(id);
    ref.invalidate(diaryEntriesProvider);
  }

  void _saveEntryQuantity(DiaryEntry entry, LoggedQuantity newQuantity) {
    final rescaled = rescaleDiaryEntry(entry, newQuantity: newQuantity);
    ref.read(diaryRepositoryProvider).updateEntry(rescaled);
    ref.invalidate(diaryEntriesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final visibleEntries = widget.entries
        .where((e) => !_locallyDeletedEntryIds.contains(e.id))
        .toList();

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.mealType.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          for (final entry in visibleEntries)
            entry.recipeId != null
                ? _RecipeEntryTile(
                    key: ValueKey('recipe-entry-${entry.id}'),
                    entry: entry,
                    onDelete: () => _deleteEntry(entry.id),
                    onSaveQuantity: (q) => _saveEntryQuantity(entry, q),
                  )
                : _FoodEntryTile(
                    key: ValueKey('food-entry-${entry.id}'),
                    entry: entry,
                    onDelete: () => _deleteEntry(entry.id),
                    onSaveQuantity: (q) => _saveEntryQuantity(entry, q),
                  ),
          const SizedBox(height: 4),
          Center(
            child: IconButton(
              onPressed: () => context.push('/scanner'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _deleteBackground() => Container(
  alignment: Alignment.centerRight,
  padding: const EdgeInsets.only(right: 12),
  child: const Icon(Icons.delete_outline, color: Colors.red),
);

class _FoodEntryTile extends ConsumerStatefulWidget {
  const _FoodEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onSaveQuantity,
  });

  final DiaryEntry entry;
  final VoidCallback onDelete;
  final void Function(LoggedQuantity) onSaveQuantity;

  @override
  ConsumerState<_FoodEntryTile> createState() => _FoodEntryTileState();
}

class _FoodEntryTileState extends ConsumerState<_FoodEntryTile> {
  late final _qtyCtrl = TextEditingController(
    text: formatAmount(widget.entry.quantity.amount),
  );

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _confirmQuantity() {
    final amount = double.tryParse(_qtyCtrl.text);
    if (amount == null || amount <= 0) return;
    widget.onSaveQuantity(
      LoggedQuantity(amount: amount, unit: widget.entry.quantity.unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Dismissible(
      key: ValueKey('food-entry-dismissible-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(),
      onDismissed: (_) => widget.onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: entry.foodId == null
                  ? null
                  : () => context.push('/food-detail/${entry.foodId}'),
              child: Row(
                children: [
                  FoodThumbnail(imageUrl: entry.imageUrl, size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.foodName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${entry.calories.round()} calories · '
                          '${DateFormat('h:mm a').format(entry.loggedAt)}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (entry.foodId != null)
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 48,
                  child: TextField(
                    key: Key('entry-quantity-field-${entry.id}'),
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(entry.quantity.unit, style: const TextStyle(color: AppColors.textSecondary)),
                IconButton(
                  key: Key('entry-quantity-confirm-${entry.id}'),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  color: AppColors.brandGreen,
                  onPressed: _confirmQuantity,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit entry',
                  onPressed: () => showEditDiaryEntryDialog(context, ref, entry),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecipeEntryTile extends ConsumerStatefulWidget {
  const _RecipeEntryTile({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onSaveQuantity,
  });

  final DiaryEntry entry;
  final VoidCallback onDelete;
  final void Function(LoggedQuantity) onSaveQuantity;

  @override
  ConsumerState<_RecipeEntryTile> createState() => _RecipeEntryTileState();
}

class _RecipeEntryTileState extends ConsumerState<_RecipeEntryTile> {
  bool _expanded = false;
  late final _qtyCtrl = TextEditingController(
    text: formatAmount(widget.entry.quantity.amount),
  );

  /// Ingredients (by `foodId`) swiped away locally — same reasoning as
  /// `_MealSectionState._locallyDeletedEntryIds`, scoped to this recipe.
  final Set<int> _locallyRemovedIngredientFoodIds = {};

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _confirmQuantity() {
    final amount = double.tryParse(_qtyCtrl.text);
    if (amount == null || amount <= 0) return;
    widget.onSaveQuantity(
      LoggedQuantity(amount: amount, unit: widget.entry.quantity.unit),
    );
  }

  List<({int foodId, double quantity, String quantityUnit})> _toIngredientArgs(
    List<RecipeIngredient> ingredients,
  ) => [
    for (final ing in ingredients)
      (
        foodId: ing.foodId,
        quantity: LoggedQuantityConverter.toServingMultiplier(
          ing.quantity,
          servingSize: ing.servingSize,
          servingUnit: ing.servingUnit,
        ),
        quantityUnit: ing.quantity.unit,
      ),
  ];

  void _removeIngredient(Recipe recipe, RecipeIngredient toRemove) {
    setState(() => _locallyRemovedIngredientFoodIds.add(toRemove.foodId));
    final remaining = recipe.ingredients
        .where((i) => i.foodId != toRemove.foodId)
        .toList();
    ref.read(recipeRepositoryProvider).updateRecipe(
      recipeId: recipe.id,
      name: recipe.name,
      servings: recipe.servings,
      ingredients: _toIngredientArgs(remaining),
    );
    ref.invalidate(recipesListProvider);
  }

  void _saveIngredientQuantity(
    Recipe recipe,
    RecipeIngredient ingredient,
    LoggedQuantity newQuantity,
  ) {
    final updated = [
      for (final ing in recipe.ingredients)
        ing.foodId == ingredient.foodId
            ? rescaleRecipeIngredient(ing, newQuantity: newQuantity)
            : ing,
    ];
    ref.read(recipeRepositoryProvider).updateRecipe(
      recipeId: recipe.id,
      name: recipe.name,
      servings: recipe.servings,
      ingredients: _toIngredientArgs(updated),
    );
    ref.invalidate(recipesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Dismissible(
      key: ValueKey('recipe-entry-dismissible-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(),
      onDismissed: (_) => widget.onDelete(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              key: Key('recipe-entry-header-${entry.id}'),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.foodName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${entry.calories.round()} calories · '
                          '${DateFormat('h:mm a').format(entry.loggedAt)}',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  width: 48,
                  child: TextField(
                    key: Key('entry-quantity-field-${entry.id}'),
                    controller: _qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(entry.quantity.unit, style: const TextStyle(color: AppColors.textSecondary)),
                IconButton(
                  key: Key('entry-quantity-confirm-${entry.id}'),
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  color: AppColors.brandGreen,
                  onPressed: _confirmQuantity,
                ),
              ],
            ),
            if (_expanded)
              Consumer(
                builder: (context, ref, _) {
                  final recipesAsync = ref.watch(recipesListProvider);
                  return recipesAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(left: 24, top: 8),
                      child: LinearProgressIndicator(),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.only(left: 24, top: 8),
                      child: Text('Could not load ingredients: $error'),
                    ),
                    data: (recipes) {
                      Recipe? recipe;
                      for (final candidate in recipes) {
                        if (candidate.id == entry.recipeId) {
                          recipe = candidate;
                          break;
                        }
                      }
                      if (recipe == null) return const SizedBox.shrink();

                      final visibleIngredients = recipe.ingredients
                          .where(
                            (i) => !_locallyRemovedIngredientFoodIds.contains(i.foodId),
                          )
                          .toList();

                      return Padding(
                        padding: const EdgeInsets.only(left: 24, top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final ingredient in visibleIngredients)
                              _IngredientRow(
                                key: ValueKey(
                                  'ingredient-row-${entry.recipeId}-${ingredient.foodId}',
                                ),
                                ingredient: ingredient,
                                onRemove: () => _removeIngredient(recipe!, ingredient),
                                onSaveQuantity: (q) =>
                                    _saveIngredientQuantity(recipe!, ingredient, q),
                              ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatefulWidget {
  const _IngredientRow({
    super.key,
    required this.ingredient,
    required this.onRemove,
    required this.onSaveQuantity,
  });

  final RecipeIngredient ingredient;
  final VoidCallback onRemove;
  final void Function(LoggedQuantity) onSaveQuantity;

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  late final _qtyCtrl = TextEditingController(
    text: formatAmount(widget.ingredient.quantity.amount),
  );

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  void _confirmQuantity() {
    final amount = double.tryParse(_qtyCtrl.text);
    if (amount == null || amount <= 0) return;
    widget.onSaveQuantity(
      LoggedQuantity(amount: amount, unit: widget.ingredient.quantity.unit),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ingredient = widget.ingredient;

    return Dismissible(
      key: ValueKey('ingredient-dismissible-${ingredient.foodId}'),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(),
      onDismissed: (_) => widget.onRemove(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                ingredient.foodName,
                style: const TextStyle(fontSize: 13),
              ),
            ),
            SizedBox(
              width: 44,
              child: TextField(
                key: Key('ingredient-quantity-field-${ingredient.foodId}'),
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              ingredient.quantity.unit,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            IconButton(
              key: Key('ingredient-quantity-confirm-${ingredient.foodId}'),
              icon: const Icon(Icons.check_circle_outline, size: 18),
              color: AppColors.brandGreen,
              onPressed: _confirmQuantity,
            ),
          ],
        ),
      ),
    );
  }
}
