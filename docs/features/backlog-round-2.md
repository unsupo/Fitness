# Feature request: round 2 follow-ups (post-implementation review)

Status: **not yet scoped for implementation** — captured from user feedback,
2026-07-29, after reviewing the round-1 implementation
(`quick-add-modal.md`, `home-and-trends-layout-v2.md`, `recipes-v2.md`,
`configurable-quantity-units.md`, `profile-goal-calculator.md`). These are
things the user tested live and found still missing/broken, plus one new
ask. Each item below is confirmed against the current code, not just
reported verbatim.

## 1. Recipe ingredients still aren't a collapsible, individually-editable list

Confirmed gap in `add_recipe_page.dart`: `_addIngredient()` exists and
`_IngredientRow` supports editing an existing row's food/quantity/unit, but
there is **no remove/delete button anywhere on `_IngredientRow`**, and the
list isn't collapsible — it's a flat `Column` of rows. The only collapsible
ingredient view that exists is in `log_recipe_dialog.dart`'s `ExpansionTile`,
which is **read-only** (shown when about to log a recipe to the diary, not
when managing the recipe itself). So collapsible and editable landed on two
different screens instead of being combined on the one that needs it — the
recipe's own edit view (`add_recipe_page.dart` in `recipeToEdit` mode).

Needs: a remove-ingredient affordance (icon button per row, or swipe like
the workouts Strong-redesign pattern) on `add_recipe_page.dart`, and
probably wrapping the ingredient section in a collapsed/expanded state
there too so a recipe with many ingredients doesn't dominate the edit page.

## 2. Tapping a recipe-based diary entry on Home does nothing

`meal_section.dart`:
```dart
onTap: entry.foodId == null
    ? null
    : () => context.push('/food-detail/${entry.foodId}'),
```
and the trailing chevron is also gated on `entry.foodId != null`. A
`DiaryEntry` logged from a recipe has `foodId == null` (`recipe_id` is set
instead — see the "references exactly one of food_id/recipe_id" comment in
`diary_entry_model.dart`), so **recipe-logged rows render with no chevron
and `onTap: null` — completely unclickable**, silently, with no visual
indication that anything is different about that row versus a food row.

Needs: a route/page for "what recipe was this, and what's in it" (the
`RecipesListPage`'s existing recipe detail via `AddRecipePage(recipeToEdit:
...)` could be reused in a read-only mode, or a dedicated recipe-detail
page) reachable via `entry.recipeId`. `DiaryEntry` needs a `recipeId` field
if it doesn't already carry one — check before assuming.

## 3. Weekly Calories chart: bars aren't tappable, no swipe between weeks

Confirmed via search — there is no `BarTouchData`/`touchCallback` anywhere
near `_CaloriesBarChart` in `trends_page.dart`. Tapping a bar does nothing;
there's no per-day calorie/macro breakdown popup. The only way to move
between weeks is the `_WeekHeader`'s prev/next chevron `IconButton`s
(±7 days at a time) — no horizontal swipe/scroll gesture on the chart
itself, unlike the weight history list and weight-goal projection chart
which both got fitInside/tooltip treatment in the earlier weight-chart bug
fixes.

Needs:
- `BarTouchData` with a `touchCallback` + tooltip (or a tap handler that
  opens a small sheet/dialog) showing that day's total calories and
  protein/carbs/fat — the per-day data (`DailyCalories.proteinG/carbsG/fatG`)
  already exists after the round-1 stacked-chart work, it just isn't
  surfaced on tap yet.
- Either a swipe gesture on the chart itself to move ±1 week (in addition
  to the existing chevrons), or explicitly confirm the chevrons are
  sufficient and this is just a discoverability issue — don't assume which
  without checking with the user if ambiguous when this is picked up.

## 4. Daily Goals weekly-rate calculator: reported still missing (needs live re-verification)

This is confirmed **wired in code** —
`profile_page.dart`'s `_DailyGoalsSection` calls
`showEditDailyGoalsDialog(context, ref, goals)`, and that dialog (as of
round 1) has the full bidirectional slider built in. So either:
- it's gated behind `canCalculate` (`profile.isCompleteForTdee &&
  weightHistory.isNotEmpty`) and the user's profile/weight data doesn't
  satisfy that yet, in which case they'd only see the amber "Add sex, age,
  height, and activity level..." / "Log your weight..." prompt instead of
  the slider — which reads as "the feature isn't there" rather than "the
  feature needs setup first", or
- there's a real bug that wasn't caught by the existing widget test.

**Needs live re-verification on-device with a complete profile + logged
weight** before assuming which. If it turns out to be the gating/messaging
issue, consider making the amber prompt more obviously "this unlocks a
calculator" rather than reading as a dead end.

## 5. New ask: Home macro rings should show percent AND grams

`lib/core/widgets/macro_ring.dart`'s `MacroRing` currently renders only
`'${(clamped * 100).round()}%'` inside the ring — no gram value anywhere
(not on the ring, not as a caption). Requested: show both, e.g. percent
inside the ring as today plus a grams line (`"64g / 120g"` style) beneath
the existing label caption. This is a shared widget (used by "every feature
that needs a macro ring" per its own doc comment — diary and analytics both
use it), so check both call sites
(`diary/presentation/pages/diary_page.dart` and wherever analytics'
`_MacroBreakdownSection` uses it) to make sure both have the actual/target
gram values on hand to pass in — `MacroRing` itself has no goal-gram
parameter today, only `progress` (0.0-1.0), so this needs a new parameter
(e.g. `actualGrams`/`targetGrams` or a pre-formatted caption string) rather
than being computable inside the widget.
