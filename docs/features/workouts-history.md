# Feature: Workouts — History Tab (Agent C)

Read `docs/ARCHITECTURE.md` (layer contract, TDD workflow) and
`docs/WORKOUTS_PLAN.md` (overall plan, IA, scope decisions) first. Read
`docs/features/workouts.md` for the entity/repository shapes you build
against — don't edit anything in that doc's scope.

Reference: Strong app's "History" tab — a reverse-chronological list of past
workouts (date + short exercise summary), tapping one opens a full
session detail with every set.

## Only touch these paths

- `lib/features/workouts/presentation/pages/history_tab.dart`
- `lib/features/workouts/presentation/pages/workout_session_detail_page.dart`
- `lib/features/workouts/presentation/widgets/history_*`
- `lib/features/workouts/presentation/controllers/history_providers.dart`
  (your own provider file — import `workoutRepositoryProvider` from the
  existing `workout_repository_provider.dart`, don't redefine it)
- `test/features/workouts/presentation/history_tab_test.dart`,
  `workout_session_detail_page_test.dart`, and
  `test/features/workouts/fakes/fake_workout_repository.dart` (add to it if
  another agent already created it — check first)

Do **not** touch `domain/`, `data/`, other agents' `presentation/pages/*`,
the router (the orchestrator wires `/workouts/session/:id` to your detail
page centrally — just make sure `WorkoutSessionDetailPage` has a plain
constructor taking a required `sessionId` int param), or `app_shell.dart`.
No `flutter run`/emulator/screenshots — central verification happens later.

## What to build

### `HistoryTab` — `ConsumerWidget`, no required constructor args

- `ref.watch(sessionHistoryProvider)` — a `FutureProvider<List<WorkoutSession>>`
  wrapping `WorkoutRepository.getSessionHistory()` (already ordered newest
  first by the data layer), defined in your own `history_providers.dart`.
- For each session, a `ListTile`/`SectionCard` row: date (formatted with
  `intl`'s `DateFormat('MMM d, yyyy')`) as the title, and a subtitle built
  from that session's sets via `summarizeSession` (domain use case in
  `docs/features/workouts.md`'s scope — fetch sets per session with
  `getSetsForSession(session.id)`, a
  `FutureProvider.family<List<WorkoutSet>, int>` in your own providers
  file). Tapping a row does `context.push('/workouts/session/${session.id}')`.
- Empty state (no sessions yet): centered icon + "No workouts logged yet"
  text, matching the style of `_EmptyDiaryDay` in `diary_page.dart` (icon +
  heading + subtext in a `SectionCard`) — don't invent a different pattern.

### `WorkoutSessionDetailPage` — `ConsumerWidget`

Constructor: `const WorkoutSessionDetailPage({super.key, required this.sessionId})`,
`final int sessionId`.

- `AppBar`: leading close/back (`Navigator.of(context).canPop()` ?
  `context.pop()` : nothing — same pattern as `RecipesListPage`), title the
  session's formatted date.
- Body: `ref.watch(setsForSessionProvider(sessionId))`, group via
  `groupSetsByMachine` (domain), one `SectionCard` per machine with its name
  as heading and every set as a row (`Set 1: 135 lb x 8` for strength,
  `12 min @ 5.5 mph` style for cardio — branch on which fields are
  non-null, same convention as the Log tab). No editing/deleting in this
  pass — view-only, matching the "Deferred" note pattern elsewhere in this
  codebase if you want to flag it, not required to build it.

## Tests to write (red, then green)

`test/features/workouts/presentation/history_tab_test.dart`: a
`FakeWorkoutRepository` (reuse/extend the shared fake under
`test/features/workouts/fakes/` if present) returning 2-3 fixed
`WorkoutSession`s and canned `getSetsForSession` results per id. Pump with
the provider overridden, assert: each session's formatted date renders, the
summary text is correct for at least one session, and tapping a row
attempts navigation (test via a `GoRouter`-wrapped `MaterialApp.router` with
a stub `/workouts/session/:id` route, or just assert the `InkWell`/`ListTile`
`onTap` fires — your call, keep it simple). Also test the empty-state path
with `getSessionHistory` returning `[]`.

`test/features/workouts/presentation/workout_session_detail_page_test.dart`:
fake returning a fixed set list across 2 machines for one `sessionId`, pump
`WorkoutSessionDetailPage(sessionId: ...)`, assert both machine names render
as section headings and a known set's weight/reps text is found.

Confirm each test fails first against the not-yet-built widget, implement,
confirm green.

## Acceptance

`flutter analyze` clean, both test files pass. Report files created,
red→green transcript, and any deviation with reasoning.
