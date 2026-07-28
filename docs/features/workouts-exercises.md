# Feature: Workouts — Exercises Tab (Agent D)

Read `docs/ARCHITECTURE.md` (layer contract, TDD workflow) and
`docs/WORKOUTS_PLAN.md` (overall plan, IA, scope decisions) first. Read
`docs/features/workouts.md` for the entity/repository shapes you build
against — don't edit anything in that doc's scope.

Reference: Strong app's "Exercises" tab — a searchable/filterable exercise
library, tapping one shows that exercise's history and personal record.

## Only touch these paths

- `lib/features/workouts/presentation/pages/exercises_tab.dart`
- `lib/features/workouts/presentation/pages/exercise_detail_page.dart`
- `lib/features/workouts/presentation/widgets/exercises_*`
- `lib/features/workouts/presentation/controllers/exercises_providers.dart`
  (your own provider file — import `workoutRepositoryProvider` from the
  existing `workout_repository_provider.dart`, don't redefine it)
- `test/features/workouts/presentation/exercises_tab_test.dart`,
  `exercise_detail_page_test.dart`, and
  `test/features/workouts/fakes/fake_workout_repository.dart` (add to it if
  another agent already created it — check first)

Do **not** touch `domain/`, `data/`, other agents' `presentation/pages/*`,
the router (the orchestrator wires `/workouts/exercise/:id` to your detail
page centrally — just make sure `ExerciseDetailPage` has a plain constructor
taking a required `machineId` int param), or `app_shell.dart`. No
`flutter run`/emulator/screenshots — central verification happens later.

## What to build

### `ExercisesTab` — `ConsumerStatefulWidget` (needs local search-text state)

- `ref.watch(machinesProvider)` — a `FutureProvider<List<Machine>>` wrapping
  `WorkoutRepository.getMachines()`, defined in your own
  `exercises_providers.dart`.
- A search `TextField` at top filtering by `name` or any entry in `aliases`
  (case-insensitive substring match, client-side over the already-fetched
  list — no new repository method needed).
- Group the filtered list by `muscleGroup` (simple `groupBy`-style fold, or
  a package-free manual grouping — don't add a new dependency), each group a
  `SectionCard` with the muscle group as heading (title-case it; `null`
  group → heading "Other") and a `ListTile` per machine. Tapping one does
  `context.push('/workouts/exercise/${machine.id}')`.
- Empty state (no machines at all — unlikely given seed data, but the query
  could still return `[]`): centered icon + "No exercises yet" text, same
  `SectionCard` icon+heading+subtext pattern as `_EmptyDiaryDay`.

### `ExerciseDetailPage` — `ConsumerWidget`

Constructor: `const ExerciseDetailPage({super.key, required this.machineId})`,
`final int machineId`.

- `AppBar`: leading close/back (`Navigator.of(context).canPop()` ?
  `context.pop()` : nothing), title the machine's name (fetch via
  `machinesProvider` and find-by-id, or add a small
  `machineByIdProvider(machineId)` family in your own providers file if
  that's cleaner — your call).
- `ref.watch(setsForMachineProvider(machineId))` —
  `FutureProvider.family<List<WorkoutSet>, int>` wrapping
  `getSetsForMachine(machineId)`, your own provider.
- A "Personal Record" `SectionCard` at top using
  `computePersonalRecord` (domain use case, `docs/features/workouts.md`) —
  show "No PR yet" if it returns `null` (e.g. a pure-cardio machine or no
  sets logged), otherwise `"${pr.weight} ${pr.unit} x ${pr.reps} — ${date}"`.
- Below it, the full set history as a simple reverse-chronological list
  (date + `weight/reps` or cardio fields, whichever are non-null — same
  branch convention as the Log/History tabs) grouped by session date if you
  want it tidier, or a flat list — your call, don't over-engineer.
- Empty state (no sets logged for this machine yet): "Not logged yet" text
  instead of an empty list.

## Tests to write (red, then green)

`test/features/workouts/presentation/exercises_tab_test.dart`: a
`FakeWorkoutRepository` (reuse/extend the shared fake under
`test/features/workouts/fakes/` if present) returning 3-4 fixed `Machine`s
across at least 2 `muscleGroup`s. Pump with the provider overridden, assert:
group headings render, a known machine name renders under the right
heading, and typing a search term that matches only one machine's `aliases`
(not its `name`) filters the list down to it.

`test/features/workouts/presentation/exercise_detail_page_test.dart`: fake
returning a fixed set list (including one clear max-weight set) for one
`machineId`, pump `ExerciseDetailPage(machineId: ...)`, assert the PR
section shows that max set's weight/reps and the full history includes
every fixture set. Also test the "no sets yet" / "no PR yet" empty-state
path with an empty list.

Confirm each test fails first against the not-yet-built widget, implement,
confirm green.

## Acceptance

`flutter analyze` clean, both test files pass. Report files created,
red→green transcript, and any deviation with reasoning.
