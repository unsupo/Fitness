# Workouts — Build Plan

New feature: a **Workouts** section, modeled on the Strong app, added
alongside the existing Nourish food-tracking surfaces. This doc is the
orchestration plan — how the work is scoped, split across parallel agents,
and verified. Contracts each agent must follow live in
`docs/features/workouts.md` (shared domain/data contract) and the three
per-tab specs (`workouts-log.md`, `workouts-history.md`,
`workouts-exercises.md`).

## Why a separate section, not a 5th bottom-nav tab

The bottom nav (Home/Recipes/[FAB]/Extras/Profile) is food-tracking IA and
already full. Workouts is a distinct domain sharing only the app shell and
theme. Every tab page (`DiaryPage`, `TrendsPage`, `ProfilePage`) already has
a **no-op `Icons.menu` leading IconButton in its AppBar** — a placeholder
sandwich icon that's never been wired to anything. That's the entry point:
it opens a new `Drawer` with a "Workouts" item pushing `/workouts`. This is
additive — no changes to the bottom nav or existing routes.

## Schema (already migrated, real project — see ARCHITECTURE.md conventions)

```
machines(id, name, aliases text[], muscle_group, created_at)

workout_sessions(id, session_date date, created_at)

workout_sets(id, logged_at, machine_id -> machines.id, set_number,
             weight numeric, reps int, unit text default 'lb', notes,
             session_id -> workout_sessions.id, machine_order int,
             incline numeric, speed numeric, duration_minutes numeric,
             seat_position text, rest_seconds int)
```

One table shape covers both strength machines (weight/reps) and cardio
machines (incline/speed/duration_minutes) — nullable fields depending on
`machines.muscle_group`. No workout name/title column exists — sessions are
identified by date; see "Scope decisions" below.

**RLS**: was disabled on all 3 tables (unlike the rest of the schema) —
already fixed via migration `enable_rls_workout_tables` (permissive
anon-role policies, matching every other table's placeholder pattern).

## Design reference: Strong app

Strong's bottom tabs are Workout / History / Exercises / Profile. We mirror
the first three as **internal tabs of one `/workouts` route** (Profile
already exists in this app). Per screen:

- **Log** — "Start Workout" CTA (or resume an in-progress one), a quick
  summary of the last session. Starting a workout opens an active-logging
  flow: add exercises (machines), log sets (weight/reps, or
  incline/speed/duration for cardio machines) with a running list of what's
  been logged, finish → writes `workout_sessions` + `workout_sets` rows.
- **History** — past sessions grouped by date with a short exercise/volume
  summary, tap through to a session detail page listing every set.
- **Exercises** — the machine library, filterable by `muscle_group`,
  searchable (name + `aliases`), tap through to an exercise detail page
  showing that machine's full set history and a simple PR (max weight)
  callout.

## Scope decisions (made now, don't re-litigate mid-build)

- No workout naming/templates — `workout_sessions` has no name column and
  no separate routines table. Sessions display as their date (formatted);
  exercises logged that day serve as the de facto summary, same as Strong's
  own history list before you name a workout. Templates are a
  `docs/FUTURE_IMPROVEMENTS.md` candidate, not in scope here.
- Rest timer: out of scope for this pass (schema has `rest_seconds` as a
  loggable field, but no active countdown UI) — logged as a plain optional
  number, not a running timer widget. Flagged for FUTURE_IMPROVEMENTS.
- The Log tab's "add exercise" picker and the Exercises tab's library list
  are two separate, intentionally-simple widgets (quick picker vs. browse
  library) rather than one shared component — different UX contexts, and
  keeping them separate avoids the two presentation agents fighting over one
  shared file.

## Parallel fan-out

Same "Built via parallel subagents" pattern the rest of Nourish used
(ARCHITECTURE.md), applied *within* one feature this time since Workouts is
one cohesive domain. To let 4 agents start simultaneously without blocking
on each other's output, the orchestrating session (this one) pre-creates the
shared, mechanical contract layer first — domain entities, the abstract
repository interface, the provider, and the `SupabaseTables` /
`Backend` hookups — small and low-risk, same as how `ARCHITECTURE.md` itself
is the shared contract for the original 4-feature build.

**Pre-work (orchestrator, before fan-out):**
- `lib/features/workouts/domain/entities/{machine,workout_session,workout_set}.dart`
- `lib/features/workouts/domain/repositories/workout_repository.dart`
- `lib/features/workouts/presentation/controllers/workout_repository_provider.dart`
- `SupabaseTables` additions (`machines`, `workoutSessions`, `workoutSets`)
- `Backend.createWorkoutRepository()` on the abstract interface (throws
  `UnimplementedError` in `SupabaseBackend` until Agent A lands — presentation
  agents never touch this provider in tests, only their own Fakes, so this
  doesn't block them)

**4 parallel agents, each isolated to its own files:**

| Agent | Owns | Spec |
|---|---|---|
| A — Data | `domain/use_cases/*`, `data/models/*`, `data/data_sources/*`, `data/repositories/*` | `docs/features/workouts.md` |
| B — Log | `presentation/pages/log_tab.dart` + widgets + own local providers | `docs/features/workouts-log.md` |
| C — History | `presentation/pages/history_tab.dart`, `presentation/pages/workout_session_detail_page.dart` + widgets | `docs/features/workouts-history.md` |
| D — Exercises | `presentation/pages/exercises_tab.dart`, `presentation/pages/exercise_detail_page.dart` + widgets | `docs/features/workouts-exercises.md` |

Each agent follows the mandatory TDD red/green workflow from
`docs/ARCHITECTURE.md` and builds against `Fake<X>Repository implements
WorkoutRepository` in its own tests — no agent needs another agent's actual
implementation to finish, only the pre-built interface/entities.

**Post fan-in (orchestrator — central integration, same boundary as the
original build):**
- Implement `SupabaseBackend.createWorkoutRepository()` for real (Agent A's
  concrete repository)
- Wire `/workouts`, `/workouts/session/:id`, `/workouts/exercise/:id` in
  `app_router.dart`, with `/workouts` hosting the 3-tab `WorkoutsShellPage`
- Add `lib/core/widgets/app_drawer.dart` and wire the existing no-op
  `Icons.menu` buttons in `DiaryPage`, `TrendsPage`, `ProfilePage` to open it
  (`RecipesListPage` gets a `drawer:` too; its `leading` is already `null`
  on the tab route, so Flutter's automatic drawer icon covers it)
- Whole-project `flutter analyze` + `flutter test`

## Closed-loop verification (mandatory per CLAUDE.md, not optional)

Run on the Android emulator (`Pixel_9_Pro_API_35`) or the physical Pixel 9
Pro Fold. Walk the golden path and screenshot each step:
1. Open the app, tap the hamburger icon on Home → Drawer shows "Workouts".
2. Tap it → lands on `/workouts`, Log tab, "Start Workout" visible.
3. Start a workout, add an exercise, log at least one real set, finish it.
4. Switch to History → the just-finished session appears; tap it → detail
   page shows the logged set(s).
5. Switch to Exercises → the machine just used appears in the library with
   correct `muscle_group`; tap it → detail page shows the set just logged.
6. Confirm via `execute_sql`/`list_tables` (or another `adb`/app round trip)
   that the rows landed in Supabase, not just local state.

Any bug found this way gets fixed and re-verified before calling the
feature done — screenshots + a description of what was tapped go in the
final report, per CLAUDE.md's "don't report done off `flutter test` alone."
