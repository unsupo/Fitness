# Future Improvements (backlog)

Deliberately deferred from the first build pass. Not urgent, but worth
tracking so decisions aren't lost.

## Round 11 — adjustable macro pie chart, workout notes, weekly-rate precision, CI fix
- **Profile's macro targets are now a draggable pie chart, not text fields.**
  `edit_daily_goals_dialog.dart` replaced the plain protein/carbs/fat number
  fields with `AdjustableMacroPieChart` — a `CustomPainter` donut whose slice
  angles are each macro's calorie share (protein/carbs at 4 kcal/g, fat at 9,
  via new `lib/features/diary/domain/use_cases/macro_calorie_split.dart`), so
  the ring always totals the calorie goal. Dragging a boundary transfers kcal
  between just the two neighboring macros (`adjustMacroSliceBoundary`,
  clamped at literal zero — no minimum floor, since diets can legitimately
  want 0% of a macro, e.g. keto's 0 carbs). See `docs/GOTCHAS.md` for why a
  percentage floor was tried and reverted in favor of always-visible handle
  markers at each boundary.
- **Fixed a real goal/pie mismatch found via live device testing.** The
  stored macro grams didn't always sum to the stored calorie goal (pre-dated
  this feature — e.g. real DB data had macros summing to 2105 kcal against a
  2000 kcal goal). The dialog now rescales macros onto the calorie goal once
  on open (`rescaleMacrosToCalories`), so the pie's center number can never
  visibly disagree with the Calories field.
- **Added a "recommended split" (30% protein / 40% carbs / 30% fat) with a
  one-tap apply button** (`recommendedMacroSplit` in
  `macro_calorie_split.dart`) — a fitness-oriented default, not personalized
  to body weight/training focus.
- **Weekly-rate slider precision + a label/field consistency bug.** The
  slider snapped its displayed "Lose/Gain X lb/week" label to the nearest
  0.25 grid independently of the exact calorie figure shown right above it —
  see `docs/GOTCHAS.md`'s "rounded display value" entry for the full
  mechanism. Fixed by only rounding what the slider itself produces on drag,
  never the label derived from an already-exact calorie value. Also
  tightened the US-unit step from 0.25 lb to 0.05 lb/week (`sliderDivisions`
  120 over the -3..3 span).
- **TDEE line clarified.** "Estimated TDEE: N kcal" now says "(Maintain)"
  next to it and has an info button explaining what TDEE means and how the
  Weekly Rate slider relates to it — it previously showed a bare number with
  no context.
- **Trends' Macro Breakdown now shows the Profile goal alongside actual
  intake.** `_LegendRow` in `trends_page.dart` gained a "· Goal Xg" suffix
  (the `dailyGoalsProvider` daily goal ×7, since the breakdown itself sums a
  whole week) next to each macro's logged grams/percent — previously the
  legend showed percent only, with no way to see actual-vs-target at a
  glance.
- **Surfaced workout set notes that existed in the DB with zero UI anywhere.**
  `workout_sets.notes` was being saved and correctly round-tripped through
  the model, but no widget ever read `set.notes` — confirmed real notes
  existed via direct SQL before fixing. Now shown under each set on the
  exercise detail and session detail pages, and `edit_workout_set_dialog.dart`
  gained a notes field (previously missing from that dialog entirely).
- **Recipes list: tap-to-edit instead of a pencil icon, swipe-to-delete,
  pull-to-refresh** matching the Home/Trends `RefreshIndicator` pattern —
  see `docs/GOTCHAS.md` for the `RefreshIndicator`-needs-a-real-`ListView`
  and `Dismissible`-locally-removed-ids gotchas this surfaced.
- **Fixed a CI-only failure and a CI job that had been red for two pushes.**
  `quick_add_modal.dart` had a `ListTile` with `onTap` nested in a colored
  `Container` with no `Material` ancestor — passed locally on Flutter 3.41.6,
  failed in CI's unpinned `stable` (3.44.8). Separately, the Android
  integration test job (`integration_test/app_test.dart`) had been failing
  for two prior pushes on a stale `find.text('Macro Breakdown')` assertion
  that never got updated when that heading gained a week-range suffix
  earlier in development — not noticed because CI output wasn't checked
  immediately after those pushes. Both are now fixed; see `docs/GOTCHAS.md`.

## Round 10 — Exercise progress, overload recommendations, and brand deployment
- **Epley One-Rep Max (1RM) Progress Chart.** Plots historical peak 1RM per workout day on a curved `LineChart` using `fl_chart`. Added an interactive placeholder card instead of hiding the section when data is insufficient (less than 2 days logged) to provide better user guidance.
- **Progressive Overload Recommendations.** Built a rules usecase that increments reps/weights based on the user's focus (Hypertrophy targets 8-12 reps; Strength targets 3-6 reps) and injected it as target visual indicators and input field fallbacks on active set logging.
- **Branding Assets Overwrite.** Replaced standard Flutter launcher icons and white launch screens on iOS and Android with customized Nourish logo branding and a warm-cream native splash screen matching the background color scheme.
- **Gotcha: Lazy Riverpod Notifier Build in tests.** When testing a Riverpod `Notifier` that loads data asynchronously in its `build` method (like reading from `shared_preferences`), creating the `ProviderContainer` does not automatically trigger the build. You must call `container.read()` or listen to the provider *before* introducing async test delays, otherwise the async load is never kicked off.
- **Gotcha: Unique icon finders in widget tests.** Re-using common icons (like `Icons.delete_outline` for both recipe deletion and ingredient row removals) can break existing widget tests searching by a generic icon finder. Proactively assign specific tooltips or keys to AppBar actions (e.g., `tooltip: 'Delete recipe'`) and locate them using `find.byTooltip()` to avoid ambiguous matches.

## Round 9 — CSV weight import + weekly-average goal graph + an ordering bug
- **CSV weigh-in import.** New upload icon in `_WeightSection`'s header
  (`trends_page.dart`) opens the native file picker (`file_picker: ^8.1.0`,
  new dependency) for a smart-scale export CSV
  (`Time,Weight,...`, `M/d/yyyy h:mm a` / `<n>lb` format). Parsed by
  `parse_weight_export_csv.dart` (header-driven column lookup, skips
  unparseable rows rather than aborting), confirmed via a dialog showing
  reading count + date range, then bulk-inserted through
  `AnalyticsRepository.importWeightEntries`.
- **Idempotent by construction.** Smart-scale exports are cumulative (each
  new export re-includes every prior reading), and `weight_log` has no
  unique constraint beyond its primary key — a plain re-import would have
  silently duplicated rows. Added `dedupeNewWeightEntries` (matches by exact
  `logged_at` instant, ignoring weight) so re-importing the same or an
  overlapping later export is a safe no-op ("All readings in that file are
  already imported."), or imports only the genuinely-new rows and says so
  ("Found N new readings... (M already imported, skipped)"). Verified live:
  importing the user's real export twice in a row only inserted 8 rows
  once; the second attempt correctly no-op'd.
- **Weight Goal projection graph now plots real weekly-average points.**
  `computeWeeklyAverages.dart` buckets `weight_log` history into 7-day
  windows from the earliest entry and averages each week. `WeightGoalSection`
  draws these as a solid orange "Actual (weekly avg)" series alongside the
  existing dashed green "Projected" series, sharing one continuous
  date-based x-axis (previously the projection line used an index-based
  axis with no way to place real historical points on it at all). The
  projection's "current weight" input is now the latest weekly average
  (smoothed) instead of the single last raw entry, so the projected target
  date recalculates naturally as new weigh-ins land.
- **Found and fixed a real ordering bug via live verification.**
  `AnalyticsRemoteDataSource.fetchAllWeightLogRows`'s
  `.order('logged_at')` had no explicit `ascending` — postgrest-dart
  defaults that to **descending**, not ascending. Every caller assumed
  ascending (oldest-first): `_WeightBody`'s "Current Weight" (`history.last`)
  was showing the *oldest* reading instead of the latest, the per-entry list
  was showing oldest-first, and the raw chart's index-based x-axis was
  plotting in reverse. Caught only by actually running the import on-device
  and eyeballing "Current Weight: 248.2 lb" looking wrong (250.9 lb was the
  known latest CSV reading) — none of the 151 unit/widget tests caught it,
  since they all go through `FakeAnalyticsRepository` and never touch the
  real Postgrest query builder's default. Fixed by passing
  `ascending: true` explicitly. While auditing for the same mistake
  elsewhere, found and fixed an identical latent bug in
  `DiaryRemoteDataSource.getEntriesForDate`'s `.order('logged_at')` (diary
  entries within a day were also silently newest-first instead of
  chronological).
- **Weigh-in list no longer grows unbounded.** Once the CSV import could add
  8+ readings at once, `_WeightBody`'s per-entry editable list
  (`trends_page.dart`) got clunky — a long scroll of rows before reaching the
  chart. Converted `_WeightBody` to a `ConsumerStatefulWidget` that shows only
  the 5 most recent entries by default, with a "Show all (N)" / "Show less"
  toggle. Editing is still one tap away for every entry, just collapsed by
  default. Verified live on-device with all 9 real readings.

## Round 8 — food-detail hero banner + empty-diary-day state
- **`FoodDetailPage` image treatment redesigned.** When a food has a photo,
  it now renders as a full-width, 220-tall, rounded (24px), shadowed banner
  (`_FoodHero` in `food_detail_page.dart`) instead of a small 128px square —
  a proper showcase image, matching how modern food apps present a product
  photo. Falls back to the existing compact `FoodThumbnail` placeholder when
  there's no photo at all (deliberately NOT a giant empty banner for the
  common no-image case). A photo that's set but fails to load (dead link,
  hotlink block) still renders the banner *shape* with a large centered
  placeholder icon inside it, rather than collapsing back to the small
  layout — the URL is real, it's just not loading right now. Verified live
  with BBQ Pringles' real product photo.
- ~~**Diary empty-state gap.**~~ Resolved: a day with zero logged entries
  previously rendered nothing at all between the date selector and the
  Daily Calories card — just blank space, no explanation. Added
  `_EmptyDiaryDay` (`diary_page.dart`) — an icon + "No meals logged yet" +
  a prompt to use the FAB, in the same `SectionCard` style as everything
  else on the page. Verified live by paging back to a day with no entries.

**Other "prettify" candidates identified but not yet done** (flagging per
user request to "look for gaps," not implementing unprompted):
- `RecipesListPage`'s empty state ("No recipes yet") is still plain
  centered gray text — could get the same icon+heading+subtext treatment
  as the new `_EmptyDiaryDay`.
- `ScannedProductSheet` (barcode-scan result) still uses the small 48px
  thumbnail next to the product name — could get the same full-width hero
  banner treatment as `FoodDetailPage` for visual consistency across every
  screen that shows a real product photo.
- Recipes have no image concept at all (`Recipe` entity/`recipes` table has
  no `image_url`) — `RecipesListPage` cards are text-only. Would need a new
  column + UI, bigger scope than the food-level image work already done.
- The Weekly Calories bar chart's meaningless rotating color palette (see
  the "Needs a closer look" section below) is itself a "prettify" gap, just
  already tracked separately since it's more a correctness-of-meaning issue
  than a pure visual one.

## Round 7 — real food photos on the Home diary list
- ~~**Diary-entry-row thumbnails in `MealSection`.**~~ Resolved: the user
  added real product images/links to several foods via the round-6 edit
  dialog, then noticed the Home list still showed the generic gray
  fork/knife icon for them. Root cause: `DiaryRemoteDataSource.getEntriesForDate`'s
  join only selected `foods(name, serving_size, serving_unit)`, never
  `image_url` — widened to include it, threaded through as a new
  `DiaryEntry.imageUrl` field, and `MealSection` now renders
  `FoodThumbnail(imageUrl: entry.imageUrl, size: 48)` instead of the
  hardcoded icon. Verified live — Pringles/Crystal Light photos now render
  correctly; the Protein Shake image (hosted on the brand's own imgix CDN)
  403s on hotlink and correctly falls back to the placeholder, confirming
  `FoodThumbnail`'s `errorBuilder` handles real-world CDN hotlink protection
  gracefully rather than breaking.
- **`FoodThumbnail` visual polish** (`lib/core/widgets/food_thumbnail.dart`):
  added a subtle 1px `ringTrack` border for definition against white
  `SectionCard` backgrounds, a `loadingBuilder` so a slow image shows the
  placeholder instead of a blank flash while it loads, and the placeholder
  icon now scales with `size` instead of a fixed 18px. `FoodDetailPage`'s
  thumbnail bumped from a small 64px corner image to a centered 128px hero,
  since that page is the one place a food's photo should feel like a
  showcase rather than a list-row icon.

## Round 6 — full food editing (name/macros/image/link) + a data-quality finding
- **`DiaryRepository` gained `updateFood(FoodItem)`.** `FoodDetailPage` now
  has an edit icon (AppBar) opening `showEditFoodDialog`
  (`lib/features/diary/presentation/widgets/edit_food_dialog.dart`) — edits
  the underlying `foods` row directly: name, brand, serving size/unit,
  calories, protein/carbs/fat, image URL, and source link. Distinct from
  `showEditDiaryEntryDialog` (still quantity/mealType/loggedAt only, on the
  `food_log` row). Editing a food's name/image/link here changes what
  already-logged diary entries show too, since those are joined live from
  `foods`, not frozen at log time — verified live (edited "BBQ Pringles",
  confirmed the Supabase row updated, confirmed a bad/guessed image URL
  correctly falls back to `FoodThumbnail`'s placeholder icon via its
  `errorBuilder` rather than breaking anything).
- **Not a code bug — a data-quality finding:** the user reported "everything
  is classified as Snacks" and "can't seem to crud the home items." Live
  testing showed diary-entry CRUD (`showEditDiaryEntryDialog` — quantity,
  meal type, delete) already worked correctly end-to-end (verified: changed
  a real entry's meal type, confirmed the Supabase row updated, then
  reverted the test change). The "all Snacks" symptom is `DiaryEntryModel`
  correctly defaulting a `null` `meal_type` to `MealType.snack` — and a
  number of real `food_log` rows (ids 20, 21, 23-35 at the time of writing)
  really do have `meal_type IS NULL` in the database. These weren't
  inserted through any app code path (`logScannedProduct`/`logRecipeToDiary`
  both always set an explicit `meal_type` string) — they look like direct
  SQL inserts (matching `foods` rows 10-15's narrative `source` field style)
  that simply omitted the column. The dropdown in the edit dialog already
  lets you fix each one; nothing to backfill via code. A one-time SQL
  backfill (guessing meal type from local hour, like the original round-3
  backfill) is possible on request but wasn't done unprompted since it'd be
  guessing at real personal data.

## Needs a closer look — Weekly Calories bar chart colors are meaningless
`_CaloriesBarChart` in `trends_page.dart` colors each day's bar by cycling
through `_barPalette` (`proteinRing` green, `carbsRing` teal, `fatRing` red,
`brandGreen`) indexed by day-of-week position — purely decorative, not tied
to that day's actual macro split. Since those exact colors mean
protein/carbs/fat everywhere else in the app (macro rings, the Progress
tab's macro chart), a rotating palette on a plain calories-per-day chart
reads as if it should mean something and doesn't. User-flagged; the fix
they want is to make each day's bar an actual **stacked bar** (protein/carbs/
fat segments sized to that day's real macro totals, in their real colors)
rather than a single flat-colored bar — turns a decorative bug into a
genuinely useful per-day macro view. Not yet implemented.

## Round 5 — food images/links/recent list + "remaining after adding" caution
- **`foods` gained `image_url`/`source_url` (nullable, additive migration).**
  Populated for barcode-scanned foods (from OpenFoodFacts) and for foods
  imported from a live OpenFoodFacts name search (see below); still null for
  hand-typed/AI-estimated foods with no real external source.
- **`DiaryRepository` gained `getRecentFoods`, `searchOnlineFoods`,
  `importOnlineFood`.** The recipe ingredient picker (`AddRecipePage`) now
  shows a "Recent" section (from `food_log` history) when the food field is
  empty, and — when searching — both local `foods` table matches and a
  "From OpenFoodFacts" section of live text-search results with real images;
  picking an OpenFoodFacts result inserts it into `foods` first (mirroring
  `logScannedProduct`'s insert-then-reference pattern) so it gets a real id
  usable as a `recipe_ingredients.food_id`. Deliberately built at the
  repository level (not hardcoded into one page) so the "Manual food entry"
  item below can reuse the same search/recent affordance for free.
- **"Remaining after adding" caution.** Both existing confirm-before-log
  screens (`ScannedProductSheet` for barcode scans, `RecognizedMealResult`
  for the AI photo flow) now show "`{X}` kcal left today after adding this",
  plus a red caution line when it would exceed today's calorie goal —
  computed from `computeRemainingAfterAdding` (new, in the diary domain).
  `RecognizedMealResult` recomputes this live as the servings stepper
  changes (it owns that state); both fetches are best-effort — a failed
  goals/entries lookup just means no caution shows, it never blocks logging.
- **Bug caught via live testing, fixed this round:** both `ScannedProductModel`
  and `OnlineFoodCandidateModel` were scaling per-100g nutriments using
  OpenFoodFacts's `product_quantity` field — which is the whole package
  weight (e.g. a 630g Nutella jar), not a serving. A live search for
  "Nutella" produced ~3400 kcal for one "serving" before the fix. Now prefers
  `serving_quantity` (the true per-serving weight) and only falls back to
  `product_quantity` when no serving size is given at all.
- **OpenFoodFacts's `cgi/search.pl` endpoint is intermittently flaky** —
  caught live: a real search occasionally returns HTTP 503 (with a valid
  JSON body underneath, which Dio's default status validation still treats
  as an error) before recovering to 200 moments later on an identical
  request. `searchOnlineFoods` already fails soft (empty list, no crash,
  local results still show), so this doesn't break anything today — but a
  retry-with-backoff would make the "From OpenFoodFacts" section more
  reliably populated.
- **Deferred out of this round:** no "remaining after adding" caution on
  `RecipesListPage`'s "Log to diary" button — that flow has no confirmation
  step at all today (one tap logs immediately), unlike the two screens
  above. Adding one would mean building a new confirmation UI from scratch;
  worth doing if recipe-logging mistakes become a real complaint, but out of
  scope for this pass. Also deferred: diary-entry-row thumbnails in
  `MealSection` (the Home screen's already-logged entries still show a
  generic icon, not the real food photo) — `getEntriesForDate`'s
  `foods(name, serving_size, serving_unit)` join would need widening to
  include `image_url` to support this.

## Round 4 — Weight Goal projection
- **TDEE is an estimate (Mifflin-St Jeor), not measured.** The projection
  graph (`WeightGoalSection`, `estimateTdee`, `projectWeightTrajectory`)
  assumes eating exactly at `calorie_goal` every day converts to weight
  change at 7700 kcal/kg — real TDEE varies by individual and changes as
  weight changes (the projection doesn't re-estimate TDEE at each week's
  projected weight, it holds the day-1 estimate constant throughout).
  Treat the date/target as directional, not a guarantee — the dialog says
  as much, but worth remembering when extending this.
- **`unit_system` ('metric'/'us') lives on the single `daily_goals` row**,
  same as the rest of the profile — fine for one user, would need to move
  to a per-user row (see the RLS/auth item above) for multi-user.
- **No re-projection trigger.** The projection recomputes on every build
  from the latest weight + current profile/goal, so it's always fresh —
  but there's no explicit "recalculate" affordance; if that ever feels
  wrong to a user, it's because the inputs (weight, calorie goal, or
  profile) changed, not a caching bug.

## Backend / data
- **Real AI vision provider for food recognition.** Currently stubbed
  (`StubFoodRecognitionRepository`). Swap in a real multimodal call (Claude
  vision or similar) behind the existing `FoodRecognitionRepository`
  interface — no UI changes needed. Requires an API key decision + secret
  storage (not hardcoded in the repo).
- **Offline-first local cache (Isar or Drift).** Spec called for
  fetch-from-API → cache locally → stream local DB to UI so the app works
  without connectivity. Skipped for the first pass to keep scope sane —
  Supabase is the only source of truth right now. Worth adding once the
  online-only version is validated.
- **Auth + per-user RLS.** All tables currently use permissive `anon`-role
  RLS policies (single-user app, no login). When multi-user support is
  needed: add Supabase Auth, add a `user_id` column to `food_log`,
  `weight_log`, and `daily_goals`, and replace the `anon full access`
  policies with `auth.uid() = user_id` policies.
- **Retrofit-style typed API codegen.** Spec mentioned Dio + Retrofit;
  we used plain `Dio` calls without the `retrofit_generator`/`build_runner`
  codegen step to keep iteration fast. Fine at this scale; revisit if the
  number of endpoints grows.
- **Barcode dedup.** `logScannedProduct` currently inserts a new `foods` row
  per scan rather than checking for an existing product with the same
  barcode/source. Add a `foods.barcode` column + upsert-by-barcode once
  duplicate food entries become a real problem.

## Product
- **Meal-type picker on barcode scan and recipe logging.** Both default to
  `snack`; Image 2's flow doesn't show a picker, but real usage will want one.
- **No recipe-detail page.** Recipe-based diary entries render (with the
  correct name, via the `recipes(name)` join added in round 2) but aren't
  tappable — there's no destination to navigate to yet, unlike food-based
  entries which open `FoodDetailPage`. Add a `RecipeDetailPage` showing full
  ingredient breakdown when there's a real need to drill in from the diary.
- ~~**No recipe editing/deleting.**~~ Resolved: `RecipeRepository` gained
  `updateRecipe`/`deleteRecipe`; `AddRecipePage` now doubles as an edit page
  via an optional `recipeToEdit` param (pre-fills name/servings/ingredients,
  adds a Delete button with a confirmation dialog), and each card in
  `RecipesListPage` has an edit icon that pushes `/recipes/add` with the
  recipe via `state.extra`. `food_log.recipe_id`'s FK was migrated from
  `NO ACTION` to `ON DELETE SET NULL` so deleting a recipe that's already
  been logged doesn't fail — the diary entry keeps its frozen calories/macros
  but loses the name link (falls back the same way "Unknown food" already
  did before the `recipes(name)` join existed).
- **Quick-add FAB menu.** FAB currently routes straight to the barcode
  scanner; a proper "Scan Barcode / Take Photo / Manual Entry" bottom sheet
  is a nicer entry point once manual entry exists.
- **Manual food entry.** No screen for typing in a food/quantity by hand yet
  — currently the only ways to log are barcode scan and AI photo.
- ~~**Profile tab.**~~ Resolved: real `lib/features/profile/` page — a
  "Daily Goals" section (calorie/protein/carbs/fat targets, editable for the
  first time via `DiaryRepository.updateDailyGoals`, previously had zero UI
  anywhere) and a "Profile" section reusing the existing biometric/weight-goal
  editing (`showEditWeightGoalDialog`, still also reachable from its original
  gear icon on the Trends page). No account/settings model exists yet — this
  is still single-user, no-login — the tab now just has real content instead
  of being a stub.
- ~~**"Breakfast" nav tab semantics.**~~ Resolved: replaced with a Recipes
  tab (was redundant with Home, which already shows every meal category).

## Needs a closer look
- **"Log weight" empty-state button on the Trends screen** — code is wired
  correctly (`TextButton(onPressed: () => showLogWeightDialog(context, ref))`
  in `trends_page.dart`, and the widget test for the empty state passes), but
  several `adb`-driven taps on a live emulator did not visibly open the
  dialog. Not reproduced via `flutter test`. Worth a real manual tap on a
  device before trusting this control. (Round 2: several other `adb`
  coordinate misses this session turned out to just be bad pixel-math on my
  part, not real bugs — cropping the screenshot with `sips` before computing
  tap coordinates fixed those. This one may be the same; wasn't re-tried with
  that technique.)

## Round 3 fixes — the timezone bug was systemic, not isolated
Round 2's `utc_day_range` fix only covered the diary's query boundary. A full
codebase audit (`grep` for `toIso8601String()`/`DateFormat` with no matching
`toLocal()`/`toUtc()`) found the same missing-conversion mistake repeated in
three more places, all fixed the same way — convert once at the boundary
(`.toLocal()` when reading a Supabase timestamp into a model, `.toUtc()`
before writing one into a query or insert) rather than scattering
conversions at display time:
- `DiaryEntryModel`/`WeightEntryModel`: `loggedAt` wasn't localized after
  parsing, so every displayed time-of-day was off by the local UTC offset
  (e.g. a 8:36am entry showed as "2:36 PM"). User-reported.
- `AnalyticsRemoteDataSource.fetchFoodLogEntries`: same missing `.toUtc()`
  as the original diary bug, in the Weekly Calories / Macro Breakdown range
  query — caused the Weekly Calories chart to show a bar for a day that
  hadn't happened yet ("entries for tomorrow"), because `groupCaloriesByDay`
  extracts `.day`/`.month`/`.year` directly from `loggedAt`, and those
  getters return UTC components on a UTC-flagged `DateTime`.
- `WeightEntryModel.toInsertJson`: new weight-log inserts stored a naive
  local timestamp with no UTC conversion — latent, since no real weigh-ins
  existed yet, but would have caused the same class of bug going forward.

Also re-ran the `meal_type` backfill (originally categorized by *UTC* hour,
not local hour — e.g. a 6pm-MDT dinner is 00:xx UTC, hour 0, so the original
backfill mislabeled it "breakfast"). Recomputed using
`AT TIME ZONE 'America/Denver'`. **This hardcodes the timezone** — fine for
a single-user app run from one place, but wrong the moment the user travels
or DST changes the offset; the sturdier fix is a user-editable meal-type
(see "no entry editing" below) rather than a derived value at all.

**No editing or deleting entries yet.** The user asked directly: "I should
be able to edit this stuff." Currently the diary is view/log-only — no way
to fix a wrong meal type, quantity, or time, or delete a mistaken entry, short
of `execute_sql` by hand. This is the most-requested missing piece; next
build round should add edit + delete to `FoodDetailPage` and
`DiaryRepository`.

## Round 2 fixes (bugs found via closed-loop device testing, not just tests)
Real product bugs, each caught by actually running the app on a device and
checking behavior against what the user expected — not by `flutter
analyze`/`flutter test` alone, which all passed throughout:
- Timezone day-boundary bug in `DiaryRemoteDataSource.getEntriesForDate`
  (naive local `DateTime` sent to a `timestamptz` column without `.toUtc()`
  first) — misattributed evening-logged food to the wrong calendar day.
- Two missing Riverpod provider invalidations after cross-screen writes:
  creating a recipe didn't refresh the recipes list, and logging a recipe to
  the diary didn't refresh the diary. Same root cause both times — a
  `FutureProvider`'s cached value doesn't know external state changed unless
  something calls `ref.invalidate(...)`.
- Recipe-logged diary entries showed "Unknown food" — the query only joined
  `foods(name)`, never `recipes(name)`, so `food_id IS NULL` rows (recipe
  entries) had nothing to display. Fixed by joining both and preferring
  whichever is non-null.
- A floating-point display bug in quantity formatting
  (`1.804511278954886x`) introduced by me earlier the same session, caught
  immediately by the next closed-loop pass.

## Engineering
- **CI coverage for the new features.** `.github/workflows/ci.yml` runs
  `flutter analyze`/`flutter test`/an Android emulator integration test/an
  iOS build sanity check for the original rep-counter scaffold. Extend the
  Android integration test to cover a Diary → Scanner → back-to-Diary flow
  once the app is stable.
- **google_fonts / custom typography.** The mockup's "Nourish" wordmark uses
  a distinct rounded/serif font; the current theme uses the system font
  styled bold + green. Add `google_fonts` if exact typography match matters.
