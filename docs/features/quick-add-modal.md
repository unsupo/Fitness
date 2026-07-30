# Feature request: Quick-add modal (replaces the current FAB sheet)

Status: **not yet scoped for implementation** — captured from user feedback,
2026-07-29. Read `docs/ARCHITECTURE.md` first when this gets built.

## Current behavior

`lib/core/router/app_shell.dart` — the center FAB's `_showQuickAddMenu`
opens a minimal `showModalBottomSheet` with exactly two rows: "Scan Barcode"
(`context.push('/scanner')`) and "Take Photo" (`context.push('/food-recognition')`).
There's no way to log a known food or a recent food from this menu — you can
only get to a food via barcode scan or the (stubbed) AI photo flow, or by
going to Home and tapping a meal section's own `+` (`meal_section.dart`),
which also just pushes `/scanner`.

## Requested behavior

Replace the two-row sheet with a fuller modal:

1. **Recent foods** — a list (or horizontally-scrolling row, see
   `home-layout-v2.md` for the pattern used elsewhere) of recently-logged
   `FoodItem`s, most recent first. Needs a new use case/query — nothing in
   `DiaryRepository` currently returns "recent distinct foods logged", only
   `getEntriesForDate`. Likely a new repository method, e.g.
   `Future<List<FoodItem>> getRecentFoods({int limit})`, backed by a
   `food_log` query deduped by `food_id`, ordered by `logged_at desc`.
2. **Search bar** — free-text search against the `foods` table (name/brand),
   returning matching `FoodItem`s. Needs a repository method like
   `Future<List<FoodItem>> searchFoods(String query)`.
3. **Camera icon** — keeps today's two existing entry points (barcode scan,
   AI photo) reachable from inside the same modal, not as the whole modal.
4. **Inline quick-add** — each result row (recent or searched) gets:
   - A quantity selector inline (reuse whatever stepper/field pattern
     `edit_daily_goals_dialog.dart` or the workouts Strong-redesign set rows
     use for a small inline numeric input).
   - A `+` button that logs it directly from the modal without leaving it
     (calls whatever `DiaryRepository.logFood`-equivalent method exists or
     needs to be added — check current logging path in
     `scanner/data/repositories/supabase_food_logging_repository.dart`,
     which is today's only "write a food_log row" implementation).
   - Tapping the row **itself** (not the `+`) instead navigates to the food's
     detail screen — see below.

## New: Food detail screen

Tapping a food (from the quick-add modal, or from an existing diary entry)
should go to a screen showing that `FoodItem`'s full macro breakdown, and:

- **A live preview of what adding it would do**: given the current day's
  totals (from `computeDailyTotals` + `dailyGoalsProvider`) and this food's
  macros × the selected quantity, show projected new totals against goals
  (e.g. "Calories: 1,450 → 1,650 / 2,000"). Recompute as the quantity
  changes.
- **An Add button** on this screen too, using the same quantity value shown
  in the preview — so adding from the detail screen and adding inline from
  the modal both go through the same underlying log call.
- Respects whatever quantity-unit picker comes out of
  `configurable-quantity-units.md` (grams vs. serving vs. other) — build
  that shared piece first if both land together, since this screen's
  quantity field and the modal's inline one should behave identically.

## Open questions to resolve before implementation

- Does "recent foods" mean distinct foods (deduped) or a raw recent-entries
  feed? (Recommend distinct — a feed duplicates what Home already shows.)
- Should the modal remember its last-used quantity per food, or always
  default to that food's `servingSize`?
