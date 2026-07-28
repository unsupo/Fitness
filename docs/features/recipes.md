# Feature: Recipes (new, round 2)

Read `docs/ARCHITECTURE.md` first for the layer contract, tech stack, schema,
and the mandatory TDD workflow. This is a **new** feature slice added after
the initial Nourish build — the user asked for "a recipe and ability to add
[one]" while using the app. `recipes` and `recipe_ingredients` tables already
exist in the schema (unused until now) and `food_log.recipe_id` already has a
foreign key to `recipes.id` — you're filling in a gap, not adding schema.

## Schema you're working with (already exists, do not migrate)

```
recipes(id, name, servings, is_estimate, source, created_at)
recipe_ingredients(id, recipe_id -> recipes.id, food_id -> foods.id, quantity)
foods(id, name, brand, calories, protein_g, carbs_g, fat_g, ...)  -- read-only source of ingredients
food_log(..., recipe_id -> recipes.id, ...)  -- logging a recipe sets recipe_id, leaves food_id null
```

A recipe's total macros are the sum of `ingredient.quantity * food.macro` across
its `recipe_ingredients`, joined to `foods`. Per-serving macros divide that
total by `recipes.servings`.

## Domain (`lib/features/recipes/domain/`)

`entities/recipe_ingredient.dart`:
```dart
class RecipeIngredient {
  final int foodId;
  final String foodName;
  final double quantity;
  final double calories;   // this ingredient's contribution: quantity * food.calories
  final double proteinG;
  final double carbsG;
  final double fatG;
}
```

`entities/recipe.dart`:
```dart
class Recipe {
  final int id;
  final String name;
  final double servings;
  final List<RecipeIngredient> ingredients;
}
```

`use_cases/compute_recipe_totals.dart` — pure functions:
```dart
({double calories, double proteinG, double carbsG, double fatG}) recipeTotals(Recipe recipe);
({double calories, double proteinG, double carbsG, double fatG}) recipePerServing(Recipe recipe);
```
`recipePerServing` divides `recipeTotals` by `recipe.servings` (guard against
`servings == 0`, treat as 1 to avoid division by zero). **Write the tests for
both first** (`test/features/recipes/domain/compute_recipe_totals_test.dart`):
build a `Recipe` with 2-3 fixed `RecipeIngredient`s, assert totals sum
correctly and per-serving divides correctly. Confirm red before implementing.

`repositories/recipe_repository.dart`:
```dart
abstract class RecipeRepository {
  Future<List<Recipe>> getRecipes();
  Future<List<FoodItem>> searchFoods(String query); // for the ingredient picker; empty query = list all (there are only ~7 foods right now)
  Future<void> createRecipe({
    required String name,
    required double servings,
    required List<({int foodId, double quantity})> ingredients,
  });
  Future<void> logRecipeToDiary(int recipeId, MealType mealType);
}
```
`FoodItem` is `lib/features/diary/domain/entities/food_item.dart` — reuse it,
don't redefine it. `MealType` is `lib/core/network/supabase_tables.dart`.

## Data (`lib/features/recipes/data/`)

- `models/recipe_model.dart` — maps a `recipes` row joined with
  `recipe_ingredients(quantity, foods(id, name, calories, protein_g, carbs_g, fat_g))`
  to a `Recipe` (Supabase embedded-resource select:
  `.select('*, recipe_ingredients(quantity, foods(id, name, calories, protein_g, carbs_g, fat_g))')`).
  Numeric columns don't consistently arrive as `String` — use
  `parseSupabaseNum` from `lib/core/network/supabase_json.dart`, never
  `double.parse(... as String)` (this bit every feature in round 1; don't
  repeat it).
- `data_sources/recipes_remote_data_source.dart` — wraps `SupabaseClient`:
  fetch all recipes (with the join above), fetch/search `foods` (simple
  `.ilike('name', '%$query%')` when query is non-empty, else `.select()` all),
  insert a `recipes` row then bulk-insert `recipe_ingredients` rows for it
  (two-step: insert recipe, read back its generated `id`, insert ingredients
  referencing that id — don't hardcode a generated id per
  `docs/ARCHITECTURE.md`'s data-migration guidance, this applies to app-code
  inserts too), and insert a `food_log` row with `recipe_id` set,
  `food_id: null`, `quantity: 1`, `logged_at: DateTime.now().toUtc().toIso8601String()`,
  and calories/protein_g/carbs_g/fat_g set to the recipe's **per-serving**
  totals (computed via `recipePerServing` from the domain use case).
- `repositories/supabase_recipe_repository.dart` —
  `SupabaseRecipeRepository implements RecipeRepository`. This is the
  **adapter** — delegates raw fetches/writes to the data source, maps
  rows to domain entities via the model.

## Presentation (`lib/features/recipes/presentation/`)

`controllers/recipes_providers.dart` — `recipeRepositoryProvider`,
`recipesListProvider` (`FutureProvider<List<Recipe>>`), a
`foodSearchProvider` (`FutureProvider.family<List<FoodItem>, String>` for the
ingredient picker).

`pages/recipes_list_page.dart` — **`class RecipesListPage extends ConsumerWidget`**,
const no-arg constructor. AppBar (leading back/close via
`Navigator.of(context).pop()` if `canPop`, title "Recipes"). Body: list of
`SectionCard`s, one per `Recipe`, each showing the name, computed per-serving
calories (`"${recipePerServing(recipe).calories.round()} cal / serving"`), and
a "Log to diary" button that calls `logRecipeToDiary(recipe.id,
MealType.snack)` (simplest default meal type — a picker is a nice-to-have,
not required) then pops back. Empty state ("No recipes yet") if the list is
empty. A `FloatingActionButton` (or a prominent button in the body — your
call) that pushes `/recipes/add`.

`pages/add_recipe_page.dart` — **`class AddRecipePage extends ConsumerStatefulWidget`**,
const no-arg constructor. AppBar with a close button. Body: a `TextField` for
recipe name, a `TextField` for servings (numeric), a growing list of
ingredient rows (each: a way to pick a food — a simple `Autocomplete` or a
`TextField` + filtered list below it using `foodSearchProvider`, is enough,
don't build a full search UI — plus a quantity `TextField`), an "Add
ingredient" button appending a blank row, a live-updating preview of total /
per-serving macros as ingredients are filled in (using the domain use cases
on the in-progress local state, not a saved `Recipe` yet), and a "Save"
button that validates (name non-empty, servings > 0, at least one ingredient
with a food selected) and calls `createRecipe(...)`, then pops back to
`/recipes`.

## Tests to write (red, then green)

- `test/features/recipes/domain/compute_recipe_totals_test.dart` (see above).
- `test/features/recipes/presentation/recipes_list_page_test.dart`: a
  `FakeRecipeRepository implements RecipeRepository` returning 1-2 fixed
  `Recipe`s (with ingredients). Pump
  `ProviderScope(overrides: [recipeRepositoryProvider.overrideWithValue(fake)], child: MaterialApp(home: RecipesListPage()))`.
  Assert: recipe name renders, computed per-serving calorie text renders, and
  a case with an empty list shows the empty state.
- `test/features/recipes/presentation/add_recipe_page_test.dart`: pump
  `AddRecipePage` with a fake repository (also implement `searchFoods` in the
  fake, returning 2-3 fixed `FoodItem`s), fill in name + servings, add an
  ingredient, assert the live macro preview updates, tap Save, assert
  `createRecipe` was called on the fake with the expected arguments (record
  the call on the fake, e.g. a nullable `lastCreateRecipeCall` field you can
  assert on afterward — this is the same "assert the adapter was called
  correctly" pattern used elsewhere, not a new pattern).

## Hard constraints (same as round 1)

- Only create/edit files under `lib/features/recipes/` and
  `test/features/recipes/`. Do not edit `pubspec.yaml`, `lib/main.dart`,
  `lib/core/router/*`, or any other feature's folder — the FAB menu and
  routes (`/recipes`, `/recipes/add`) are wired centrally after you're done,
  not by you.
- Do not run `flutter run` or touch an emulator/device.
- Run `flutter analyze` (whole project) and `flutter test test/features/recipes`
  before reporting done; report exact output plus files created plus any
  deviations with reasoning. Keep the report under 400 words.
