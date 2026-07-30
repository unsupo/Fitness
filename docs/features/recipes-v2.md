# Feature request: Recipes v2 (photos, editable ingredients, add-preview)

Status: **not yet scoped for implementation** — captured from user feedback,
2026-07-29. Companion/follow-up to `docs/features/recipes.md` (the original
spec) — read that first for the existing `Recipe`/`RecipeIngredient` shape
and current screens before starting.

Current entities (`lib/features/recipes/domain/entities/`):
```dart
class Recipe {
  final int id;
  final String name;
  final double servings;
  final List<RecipeIngredient> ingredients;
}

class RecipeIngredient {
  final int foodId;
  final String foodName;
  final double quantity; // no unit field today
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
}
```

## Requested changes

1. **Photo support** — ability to attach a picture to a recipe, and
   separately to a food item (`FoodItem` already has `imageUrl` for remote
   product photos from OpenFoodFacts; this is about **user-uploaded** photos
   for recipes/foods that don't have one). Needs: Supabase Storage bucket
   (check whether one already exists for anything image-related — none
   found as of this writing), an upload use case using the `camera` package
   already in the stack, and a new nullable column (e.g. `recipes.photo_url`,
   `foods.user_photo_url` — don't overload `foods.image_url` which is
   OpenFoodFacts-sourced) plus the corresponding entity/model field.

2. **Editable ingredient list, collapsible, even after saving** — today's
   recipe creation flow (check `recipes.md` / the actual creation page) may
   only support building the ingredient list at creation time. Requested:
   after a recipe is saved, its detail/edit screen should show ingredients
   as a **collapsible list** (collapsed = just recipe totals + servings;
   expanded = each `RecipeIngredient` row), and allow **add / remove /
   update quantity** on existing ingredients post-save — not just at
   creation. This means `RecipeRepository` needs update/delete-ingredient
   methods if it doesn't have them already (check
   `lib/features/recipes/domain/repositories/recipe_repository.dart` before
   assuming what's missing).

3. **Add-to-log preview** — same idea as the food detail screen's preview in
   `quick-add-modal.md`: before confirming "add this recipe to today's log",
   show what the day's calorie/macro totals would become (current totals +
   recipe's per-serving-or-whole macros × chosen quantity). Reuses whatever
   preview computation gets built for the food detail screen — don't
   duplicate the math, extract a shared use case if both land
   (`compute_projected_totals(current, addition) -> DailyTotals` or similar).

4. **Configurable quantity/unit** — see `configurable-quantity-units.md`;
   applies to `RecipeIngredient.quantity` the same way it applies to
   `DiaryEntry.quantity`. Build the shared unit-picker piece once, use it in
   both places.

## Sequencing note

#2 (editable-after-save) is probably the biggest structural change —
depends on what `RecipeRepository` currently supports. Check that first;
if it's read/create-only, this is not a small UI tweak.
