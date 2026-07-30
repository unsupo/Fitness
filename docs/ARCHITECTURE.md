# Nourish — Architecture & Build Contract

Food tracking app ("Nourish") built with Feature-First Clean Architecture.
This doc is the shared contract all feature agents must follow. Feature-specific
specs live in `docs/features/*.md`.

## Layers (per feature)

```
features/<name>/
  domain/
    entities/       pure Dart classes, no Flutter/Supabase imports
    repositories/    abstract interfaces (the "adapter" seam)
    use_cases/       pure functions / classes operating on entities
  data/
    models/          fromJson/toJson mapping to Supabase rows
    data_sources/    wraps SupabaseClient, one method per query
    repositories/    Supabase<X>Repository implements domain interface
  presentation/
    controllers/     Riverpod providers/notifiers
    pages/           full-screen widgets (routed)
    widgets/         feature-local reusable widgets
```

Dependency rule: `presentation -> domain <- data`. Presentation never imports
`data/` directly — it goes through the abstract repository interface via a
Riverpod provider. This is what makes Supabase swappable later (the "adapter
backend" pattern) without touching UI or domain code.

**Composition root — where the concrete backend gets chosen.** A feature's
own `presentation/controllers/*_providers.dart` must depend only on
`ref.watch(backendProvider).createXRepository()` (from
`lib/core/di/backend.dart`) — never construct a `SupabaseXRepository` or
import `package:supabase_flutter` directly. The abstract `Backend` factory
(`lib/core/di/backend.dart`) and its default implementation
(`lib/core/di/supabase_backend.dart`) are the **only** place in the app that
imports `supabase_flutter` outside of `data/` layer files and `main.dart`.
Swapping backends means writing a new `Backend` implementation and changing
the one override in `main.dart` (`NourishApp(backend: ...)`) — zero feature
code changes. (This was retrofitted in round 3 after every feature's own
provider file was found hardcoding `SupabaseXRepository(Supabase.instance.client)`
— correct per-feature isolation, but not actually backend-agnostic until the
adapter selection moved to one composition root.)

## Tech stack (already added to pubspec.yaml — do not edit pubspec.yaml)

- `flutter_riverpod` — state management, plain providers (no codegen/build_runner)
- `go_router` — routing (wired centrally, see below)
- `fl_chart` — charts (analytics feature)
- `mobile_scanner` — barcode scanning (scanner feature)
- `camera` — photo capture for AI food recognition (scanner feature)
- `dio` — HTTP client (OpenFoodFacts calls)
- `supabase_flutter` — already initialized in `lib/main.dart` (do not touch)
- `intl` — date formatting

## Shared foundation (already built — reuse, do not duplicate)

- `lib/core/theme/app_theme.dart` — `AppTheme.light()`, `AppColors`, `SectionCard` widget
- `lib/core/widgets/macro_ring.dart` — `MacroRing` widget (circular % indicator)
- `lib/core/network/supabase_tables.dart` — `SupabaseTables` table-name constants, `MealType` enum
- `Supabase.instance.client` — already initialized at app startup, available globally

## Supabase schema (already migrated — real project, already has live data)

```
foods(id, name, brand, serving_size, serving_unit, calories, protein_g, carbs_g,
      fat_g, fiber_g, sugar_g, sodium_mg, micros jsonb, source, is_estimate,
      created_at, image_url, source_url)

food_log(id, logged_at, food_id -> foods.id, quantity, quantity_unit, calories,
         protein_g, carbs_g, fat_g, notes, recipe_id -> recipes.id, sodium_mg,
         micros jsonb, meal_type text check in ('breakfast','lunch','dinner','snack'))

recipes(id, name, servings, is_estimate, source, created_at)
recipe_ingredients(id, recipe_id -> recipes.id, food_id -> foods.id, quantity,
                    quantity_unit)

daily_goals(id, calorie_goal, protein_goal_g, carbs_goal_g, fat_goal_g, updated_at)
  -- single row, single-user app for now

weight_log(id, logged_at, weight_kg, goal_type text check in ('maintain','lose','gain'))
```

RLS is enabled on all tables with permissive `anon`-role policies (single-user
app, no auth yet). Numeric (Postgres `numeric` type) columns do **not**
consistently arrive as `String` from PostgREST/supabase_flutter — the same
column can come back as a JSON string or a native `num` depending on the
value. Caught live on an emulator run (`type 'double' is not a subtype of
type 'String'`) after every feature agent assumed String-only, per the
(wrong) original version of this doc. Always parse numeric fields with
`lib/core/network/supabase_json.dart`'s `parseSupabaseNum(json['x'])`, never
`double.parse(json['x'] as String)`.

## Route contract (do not create your own router — I wire this centrally)

| Path | Page class | File |
|---|---|---|
| `/` (Home tab) | `DiaryPage` | `lib/features/diary/presentation/pages/diary_page.dart` |
| `/recipes` (Recipes tab) | `RecipesListPage` | `lib/features/recipes/presentation/pages/recipes_list_page.dart` |
| `/trends` (Extras tab) | `TrendsPage` | `lib/features/analytics/presentation/pages/trends_page.dart` |
| `/profile` (Profile tab) | `ProfilePage` | `lib/features/profile/presentation/pages/profile_page.dart` |
| `/scanner` (pushed from FAB) | `BarcodeScannerPage` | `lib/features/scanner/presentation/pages/barcode_scanner_page.dart` |
| `/food-recognition` (pushed from FAB) | `FoodRecognitionPage` | `lib/features/scanner/presentation/pages/food_recognition_page.dart` |
| `/recipes/add` (pushed from Recipes tab's AppBar action) | `AddRecipePage` | `lib/features/recipes/presentation/pages/add_recipe_page.dart` |

Each page must have a plain, no-required-external-context constructor (only
optional named params as noted) so it can be instantiated directly by
`GoRoute(builder: (context, state) => const XPage())`. Use `context.pop()` to
go back and `context.push('/scanner')` etc. to navigate — `go_router` is
already a dependency, just `import 'package:go_router/go_router.dart';`.

## TDD workflow — red/green, required for every unit of logic

For every use case / pure function / mapper AND every page:

1. Write the test first (`test/features/<name>/...`), against the interface
   you're about to build (a class/function that doesn't exist yet, or exists
   with different behavior).
2. Run `flutter test <that file>` and confirm it **fails** (red) — if it
   passes immediately, the test isn't testing anything real; fix the test.
3. Implement the minimum code to make it pass.
4. Run the test again and confirm it **passes** (green).
5. Move to the next slice.

For widget/page tests: build a `Fake<X>Repository implements <X>Repository`
in the test file (or a `test/features/<name>/fakes/` helper) returning canned
domain entities, override the Riverpod provider with
`ProviderScope(overrides: [xRepositoryProvider.overrideWithValue(fake)], child: ...)`,
pump the page, assert on rendered text/widgets. No real network/Supabase calls
in tests.

## Hard constraints for every feature agent

- Only create/edit files under your own `lib/features/<name>/` and
  `test/features/<name>/` directories.
- Do **not** edit `pubspec.yaml`, `lib/main.dart`, `lib/core/router/*`, or any
  other feature's folder.
- Do **not** run `flutter run`, boot an emulator, or attempt device
  screenshots — that verification happens centrally after all features land.
- Do run `flutter analyze` (whole-project, read-only check) and
  `flutter test test/features/<name>` before reporting done. Report the exact
  output of both.
- Match the visual style using `AppColors` / `SectionCard` / `MacroRing` from
  core — don't invent a different palette.
- When done, report: files created, test results (red→green transcript
  summary), and any deviation from this spec with reasoning.

## Backlog

See `docs/FUTURE_IMPROVEMENTS.md` for what's intentionally deferred.
