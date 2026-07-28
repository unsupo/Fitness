# Arndt Fitness / Nourish

Flutter mobile app. Two things live in this repo right now:

1. **Rep Counter** (`lib/rep_counter.dart`, `lib/main.dart`'s original scaffold)
   — a small proof-of-closed-loop demo app, not the real product.
2. **Nourish** — the actual food-tracking app being built out under
   `lib/features/*`. This is the active work.

## Why Flutter

Chosen over React Native / Kotlin Multiplatform specifically for closed-loop,
agent-driven development: single Dart codebase, fully CLI-scriptable
(`flutter analyze` / `flutter test` / `flutter test integration_test` /
`flutter build`), no GUI-only steps required for the inner loop, strong
Google investment (not at risk of abandonment as of mid-2026).

## Tech stack

- **State management:** `flutter_riverpod` — plain providers, no codegen/build_runner.
- **Routing:** `go_router`.
- **Backend:** Supabase (`supabase_flutter`), **default and only backend
  adapter for now** — repositories are defined as abstract interfaces per
  feature specifically so Supabase can be swapped later without touching UI.
- **Charts:** `fl_chart`.
- **Barcode scanning:** `mobile_scanner`.
- **Camera (food photos):** `camera`.
- **HTTP:** `dio` (plain calls, no Retrofit codegen — see
  `docs/FUTURE_IMPROVEMENTS.md`).
- **Local DB:** none yet. Spec called for Isar/offline-first; deferred, see
  `docs/FUTURE_IMPROVEMENTS.md`.

## Architecture

Feature-First Clean Architecture. Full contract, folder layout, and the
mandatory TDD (red/green) workflow are documented in `docs/ARCHITECTURE.md`.
Per-feature specs: `docs/features/diary.md`, `docs/features/scanner.md`,
`docs/features/analytics.md`. Deferred items: `docs/FUTURE_IMPROVEMENTS.md`.

Each feature is isolated (`domain/`, `data/`, `data/repositories/` implement
`domain/repositories/` interfaces). Presentation never talks to Supabase
directly — always through a repository interface + Riverpod provider. This is
the "adapter" seam the user asked for: Supabase is the default implementation,
not a hardwired dependency.

**Built via parallel subagents**, one per feature (diary / scanner /
analytics), each handed only its own `docs/features/<name>.md` spec plus the
shared `docs/ARCHITECTURE.md` contract, working only within its own
`lib/features/<name>/` and `test/features/<name>/` directories. Central
integration (router wiring, `main.dart`, cross-feature verification) is done
by the orchestrating session afterward, not by the feature agents.

## Supabase project

- Project: **"unsupo's Project"**, ref `mgdwhtldwqpudgohalwb`, org
  `jetjzldkjwodrygujrdr`, region `ca-central-1`. This is the user's real,
  already-in-use Supabase project (had live nutrition data before this app
  existed) — not a throwaway/demo project. Treat schema changes accordingly.
- Client config lives in `lib/supabase_config.dart` (URL + **publishable**
  key — safe to embed client-side, that's what publishable/anon keys are
  for). Never put the service role key in the repo.
- Schema: `foods`, `food_log` (now has `meal_type`), `recipes`,
  `recipe_ingredients`, plus newly added `daily_goals` (single row) and
  `weight_log`. Full column list in `docs/ARCHITECTURE.md`.
- **RLS:** enabled on every table with permissive `anon`-role policies
  (single-user app, no auth yet). This does not currently reduce exposure
  (the anon key still has full read/write) — it's a deliberate placeholder so
  the policy structure exists and swapping in `auth.uid()`-scoped policies
  later is a small diff, not a first-time rollout. Don't assume real
  per-user data isolation exists yet.
- Numeric Postgres columns (`numeric` type) come back through
  supabase_flutter as `String`, not `num` — models must `double.parse()`
  them, not cast.

## Feature scope decisions (already made, don't re-ask)

- **AI food recognition (Image 3 flow): stubbed**, not a real vision API
  call. Full UI flow is real; the recognition result is mocked behind
  `FoodRecognitionRepository`. Revisit in `docs/FUTURE_IMPROVEMENTS.md` when
  an API key/provider decision is made.
- **Barcode lookup (Image 2 flow): real**, via OpenFoodFacts (free, no API
  key).
- Bottom nav: Home / Recipes / [+ FAB] / Extras / Profile, where
  Extras = Trends/Analytics, Profile = stub (not a full feature yet), FAB =
  quick-add menu (scan barcode / take photo). Originally a literal mirror of
  the mockup's "Breakfast" tab (today's diary filtered to breakfast
  entries) — replaced when the user pointed out it was redundant with Home
  already showing every meal. Recipes was promoted from FAB-menu-only to a
  full tab at the same time.

## Dev workflow expectations

- **TDD red/green required** for domain logic and pages: write the failing
  test first, confirm it fails, implement, confirm it passes. Not optional —
  this was an explicit user requirement, not just a nice-to-have.
- **Closed-loop verification is mandatory, not just `flutter test`.** After
  building a feature, actually run the app on a device/emulator, interact
  with it, and screenshot the result — don't report a feature done off
  `flutter analyze`/`flutter test` alone. See `.github/workflows/ci.yml` for
  the same principle applied in CI (an Android emulator integration-test job
  exists specifically because unit/widget tests aren't sufficient proof).
- Local dev environment: Xcode's installed iOS Simulator runtime (17.5) is
  older than what Xcode 26.3 expects (26.2), so local iOS builds currently
  fail — use the **Android emulator** (`Pixel_9_Pro_API_35` via `flutter
  emulators --launch`) for local closed-loop verification instead. GitHub's
  macOS CI runners don't have this problem.
- The user also has a **physical Android phone** (Pixel 9 Pro Fold,
  `48241FDKD001BM`) available via USB with debugging enabled and this
  machine already authorized — `flutter run -d 48241FDKD001BM` deploys
  straight to it, same as the emulator. Useful as a second/alternate closed-
  loop target, or when the user wants to see a change on their actual
  device rather than the emulator. If it doesn't show up in `adb devices`,
  it usually means the phone's USB mode reset to "charging only" — switch it
  to File Transfer/MTP from the notification shade to re-trigger the
  connection.
- This directory is **not a git repo** (as of the Rep Counter / Nourish
  scaffold work) — nothing has been committed. Ask before running `git init`
  or making the first commit; it was previously declined once.
