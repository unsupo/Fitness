import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/core/widgets/app_drawer.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/recipes/domain/entities/recipe.dart';
import 'package:arndt_fitness/features/recipes/domain/use_cases/compute_recipe_totals.dart';
import 'package:arndt_fitness/features/recipes/presentation/controllers/recipes_providers.dart';
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

class _RecipesListBody extends ConsumerWidget {
  const _RecipesListBody({required this.recipes});

  final List<Recipe> recipes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recipes.isEmpty) {
      return const Center(
        child: Text(
          'No recipes yet',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final perServing = recipePerServing(recipe);

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      recipe.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    tooltip: 'Edit recipe',
                    onPressed: () =>
                        context.push('/recipes/add', extra: recipe),
                  ),
                ],
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
                  onPressed: () async {
                    await ref
                        .read(recipeRepositoryProvider)
                        .logRecipeToDiary(recipe.id, MealType.snack);
                    ref.invalidate(recipesListProvider);
                    // Crosses into the diary feature deliberately: logging a
                    // recipe changes what the diary shows, so its cached
                    // entries (for every date) must be invalidated too.
                    ref.invalidate(diaryEntriesProvider);
                    if (context.mounted && Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Log to diary'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
