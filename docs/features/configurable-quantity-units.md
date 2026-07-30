# Feature request: Configurable quantity units for food logging + recipe ingredients

Status: **not yet scoped for implementation** — captured from user feedback,
2026-07-29. This is a shared cross-cutting piece referenced by
`quick-add-modal.md` and `recipes-v2.md` — build it once, use it in both.

## Current state

- `DiaryEntry.quantity` (`lib/features/diary/domain/entities/diary_entry.dart`)
  is a bare `double` — a multiplier against the food's stored macros, with
  no unit attached.
- `RecipeIngredient.quantity` (`recipes/domain/entities/recipe_ingredient.dart`)
  is the same — a bare `double`.
- `FoodItem.servingSize` / `FoodItem.servingUnit` exist (e.g. `1` /
  `"cup"`), but are informational display fields, not something the user
  picks from when logging — logging just multiplies by a plain number.

## Requested behavior

When logging a food (quick-add modal, food detail screen, or a recipe
ingredient row), the user should be able to pick the unit the quantity is
in — at minimum: the food's own serving unit (from `servingSize`/
`servingUnit`), grams, and possibly other common units (oz, ml, etc.,
scope TBD) — not just a fixed multiplier of "servings".

## Implementation shape (sketch, not final)

This needs a per-food notion of "how much is 1 gram / 1 serving / 1 oz in
terms of the stored macros", which isn't fully present today:
`FoodItem.servingSize` + `servingUnit` gives *one* known conversion (e.g.
"this food's stored macros are per 1 cup"), but converting to grams
requires either:
- A `gramsPerServing` field on `FoodItem` (needs a schema addition — check
  whether OpenFoodFacts data already provides this and it's just not being
  captured yet, before assuming a manual-entry-only field), or
- Restricting the picker to whatever units are actually derivable per food
  (i.e. don't offer "grams" for a food where the gram equivalent isn't
  known).

Likely a small value object, e.g.:
```dart
class LoggedQuantity {
  final double amount;
  final String unit; // 'serving' | 'g' | ...
}
```
replacing the bare `double quantity` on both `DiaryEntry` and
`RecipeIngredient`, with a use case that converts a `LoggedQuantity` + a
`FoodItem` into the actual macro multiplier used for storage/display.

## Open question

Do we store the *unit the user picked* (so editing later shows "2 scoops"
rather than a silently-converted gram amount), or normalize to grams at
write time and only keep the unit as a UI convenience? Recommend storing
the picked unit + amount verbatim — normalizing at write time loses
information and makes edits confusing (a user who entered "1 cup" seeing
"236g" on edit is surprising).
