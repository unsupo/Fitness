import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/core/widgets/app_drawer.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/use_cases/compute_recipe_totals.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
import 'package:arndt_fitness/features/recipes/presentation/widgets/log_recipe_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Saved recipes: view them and log one to today's diary. The Recipes bottom
/// nav tab — see `docs/ARCHITECTURE.md`. "Add recipe" is an AppBar action
/// (not a page-level FAB) since the shell already owns a global quick-add
/// FAB visible on every tab; two FABs on one screen would be its own
/// redundant-affordance problem.
class RecipesListPage extends ConsumerWidget {
  const RecipesListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipesAsync = ref.watch(recipesListProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add recipe',
            onPressed: () => context.push('/recipes/add'),
          ),
        ],
      ),
      body: SafeArea(
        child: recipesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Could not load recipes: $error')),
          data: (recipes) => _RecipesListBody(recipes: recipes),
        ),
      ),
    );
  }
}

class _RecipesListBody extends ConsumerStatefulWidget {
  const _RecipesListBody({required this.recipes});

  final List<Recipe> recipes;

  @override
  ConsumerState<_RecipesListBody> createState() => _RecipesListBodyState();
}

class _RecipesListBodyState extends ConsumerState<_RecipesListBody> {
  /// Recipes swiped away locally, hidden immediately while the delete
  /// request is in flight — `recipes` comes from a Riverpod provider one
  /// level up, so without this a `Dismissible` would still be in the tree
  /// on the next build (before the provider refetches), which Flutter
  /// treats as an error ("a dismissed Dismissible widget is still part of
  /// the tree").
  final Set<int> _locallyDeletedRecipeIds = {};

  Future<void> _refresh() => ref.refresh(recipesListProvider.future);

  void _deleteRecipe(int id) {
    setState(() => _locallyDeletedRecipeIds.add(id));
    ref.read(recipeRepositoryProvider).deleteRecipe(id);
    ref.invalidate(recipesListProvider);
  }

  @override
  Widget build(BuildContext context) {
    final recipes = widget.recipes
        .where((r) => !_locallyDeletedRecipeIds.contains(r.id))
        .toList();

    if (recipes.isEmpty) {
      // A plain (non-scrollable) empty state wouldn't support the pull
      // gesture at all — RefreshIndicator needs a scrollable descendant, so
      // this is a single-item ListView rather than a bare Padding/Column,
      // same as every other empty-state-but-still-refreshable page.
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SectionCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.menu_book_outlined,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No recipes yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Create a custom recipe to easily log your favorite meals and ingredients.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => context.push('/recipes/add'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add recipe'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: recipes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          final perServing = recipePerServing(recipe);

          return Dismissible(
            key: ValueKey('recipe-dismissible-${recipe.id}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 12),
              child: const Icon(Icons.delete_outline, color: Colors.red),
            ),
            onDismissed: (_) => _deleteRecipe(recipe.id),
            child: SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => context.push('/recipes/add', extra: recipe),
                    child: Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${perServing.calories.round()} cal / serving',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => showLogRecipeDialog(context, recipe),
                      child: const Text('Log to diary'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
