# Feature: Workouts — Log Tab (Agent B)

Read `docs/ARCHITECTURE.md` (layer contract, TDD workflow) and
`docs/WORKOUTS_PLAN.md` (overall plan, IA, scope decisions) first. Read
`docs/features/workouts.md` for the entity/repository shapes you build
against — **do not edit anything in that doc's scope** (domain
entities/repositories, data layer). The interface and entities already exist
in the repo; import them, don't redefine them.

Reference: Strong app's "Workout" tab — a Start Workout CTA when idle, and
an active in-progress logging screen (exercise list, each with rows of
sets) once a workout has started.

## Only touch these paths

- `lib/features/workouts/presentation/pages/log_tab.dart`
- `lib/features/workouts/presentation/widgets/log_*` (your own widgets,
  prefix filenames `log_` to avoid collisions with the other two agents)
- `lib/features/workouts/presentation/controllers/log_providers.dart`
  (your own provider file — do not add to or rename
  `workout_repository_provider.dart`, which already exists; import
  `workoutRepositoryProvider` from it)
- `test/features/workouts/presentation/log_tab_test.dart` and any fakes you
  need under `test/features/workouts/fakes/` (if a fake already exists
  there from another agent, add to it rather than duplicating — check
  first)

Do **not** touch `domain/`, `data/`, other agents' `presentation/pages/*`,
the router, or `app_shell.dart`. Do not run `flutter run`/boot an
emulator/take screenshots — central closed-loop verification happens after
all agents land.

## What to build

`LogTab` — a `ConsumerWidget` (or `ConsumerStatefulWidget` if you need local
mutable state for the in-progress session, which you will), no required
constructor args, embedded as one child of the `/workouts` route's
`TabBarView` (built centrally — don't wrap it in its own `Scaffold`/`AppBar`,
just return the tab's body content).

**Idle state** (no session in progress this app-session):
- A summary card: "Last workout" — date + `summarizeSession(sets)` (from
  `domain/use_cases/summarize_session.dart`) for the most recent session via
  `ref.watch(lastSessionProvider)` / its sets. If there's no history at all,
  show "No workouts yet" instead.
- A prominent "Start Workout" button (`FilledButton`, full-width, using
  `AppColors.accentOrange` or the theme default — match existing button
  styling elsewhere in the app, e.g. `edit_weight_goal_dialog.dart`'s
  buttons). Tapping it calls `WorkoutRepository.startSession(DateTime.now())`
  and transitions local state to "active".

**Active state** (session in progress):
- Header: session date + an "Finish Workout" `TextButton`/`AppBar`-style
  action that just clears local state back to idle (the session and any
  logged sets are already persisted per-set, so "finishing" is not itself a
  write — no separate "end session" column exists in the schema).
- A list of exercises added so far, each a `SectionCard` with the machine
  name as heading and its logged sets as rows (`Set 1: 135 lb x 8`, etc, or
  for cardio machines something like `12 min @ 5.5 mph, incline 2`) — reuse
  `MachineSetGroup`/`groupSetsByMachine` from domain to shape this from the
  flat set list you're accumulating locally + already-persisted via
  `getSetsForSession`.
- An "Add Exercise" button opening a simple bottom sheet: a searchable list
  of `Machine`s (from `machinesProvider` — a `FutureProvider<List<Machine>>`
  wrapping `getMachines()`, define it in your own `log_providers.dart`),
  tap one to add it to the active list (no repository write yet — a machine
  only gets persisted once a set is logged against it).
- Per added exercise, an inline "Add Set" affordance: a small form (weight +
  reps for strength machines, or incline/speed/duration for
  `muscleGroup == 'cardio'` — branch on that) that on submit calls
  `WorkoutRepository.logSet(...)` with the next `setNumber` for that machine
  (`existingSets.length + 1`) and `sessionId` from the active session,
  invalidates/refetches so the new set shows immediately.

Loading/error states: simple centered spinner/error text, consistent with
the rest of the app (see `diary_page.dart`). Don't over-engineer the active-
session state management — a `ConsumerStatefulWidget` holding
`WorkoutSession? _activeSession` and a locally-refetched
`FutureProvider.family<List<WorkoutSet>, int>(sessionId)` for its sets is
enough; no need for a full state machine.

## Tests to write (red, then green)

`test/features/workouts/presentation/log_tab_test.dart`: a
`FakeWorkoutRepository implements WorkoutRepository` (put it in
`test/features/workouts/fakes/fake_workout_repository.dart` if it doesn't
exist yet, so History/Exercises agents can reuse it — check first, add to
it rather than duplicating if it's already there) returning a fixed
`getLastSession`/`getSetsForSession` and a canned `getMachines()` list. Pump
`ProviderScope(overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
child: MaterialApp(home: Scaffold(body: LogTab())))`. Assert:
- Idle state shows the last-workout summary text and a "Start Workout"
  button.
- Tapping "Start Workout" calls `startSession` and the widget transitions to
  showing "Add Exercise" (verify via a `fake.startSessionCallCount` or
  similar tracked field on your fake).
- Adding an exercise then logging a set calls `logSet` with the right
  `sessionId`/`machineId`/`setNumber` and the new set's summary text appears.

Confirm each assertion fails first (red) against a stub `LogTab` (or the
real widget before the relevant logic exists), then implement, then green.

## Acceptance

`flutter analyze` clean, `flutter test test/features/workouts/presentation/log_tab_test.dart`
passes. Report files created, red→green transcript, and any deviation with
reasoning.
