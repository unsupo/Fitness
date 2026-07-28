# Feature: Workouts — Data Layer (Agent A)

Read `docs/ARCHITECTURE.md` first (layer contract, TDD workflow, numeric
parsing gotcha) and `docs/WORKOUTS_PLAN.md` (overall plan, IA, scope
decisions). This doc covers your scope only: **domain use cases + the full
data layer** for the Workouts feature.

**The domain entities and repository interface already exist** — created by
the orchestrating session as the shared contract every Workouts agent builds
against (`lib/features/workouts/domain/entities/*.dart`,
`lib/features/workouts/domain/repositories/workout_repository.dart`). Read
them before starting; do not redefine or rename them. Your job is the use
cases (pure functions operating on those entities) and everything in
`data/`.

## Only touch these paths

- `lib/features/workouts/domain/use_cases/*`
- `lib/features/workouts/data/**`
- `test/features/workouts/domain/*` (use case tests)
- `test/features/workouts/data/*` (model/mapping tests)

Do not edit `domain/entities/`, `domain/repositories/`,
`presentation/controllers/workout_repository_provider.dart`, `SupabaseTables`,
`Backend`/`SupabaseBackend`, the router, or any `presentation/pages/`
directory — those are owned centrally or by the three presentation agents.

## Entities (already created — reference, do not redefine)

```dart
// domain/entities/machine.dart
class Machine {
  final int id;
  final String name;
  final List<String> aliases;
  final String? muscleGroup; // e.g. 'chest', 'back', 'legs', 'cardio' — free text in the DB, no enum
}

// domain/entities/workout_session.dart
class WorkoutSession {
  final int id;
  final DateTime sessionDate; // date-only (from Postgres `date` column)
}

// domain/entities/workout_set.dart
class WorkoutSet {
  final int id;
  final DateTime loggedAt;
  final int machineId;
  final String machineName; // denormalized from the joined machines row
  final int sessionId;
  final int setNumber;
  final int? machineOrder;
  // Strength fields (nullable — null for pure-cardio machines):
  final double? weight;
  final int? reps;
  final String unit; // 'lb' | 'kg', defaults 'lb'
  // Cardio fields (nullable — null for strength machines):
  final double? incline;
  final double? speed;
  final double? durationMinutes;
  final String? seatPosition;
  final int? restSeconds;
  final String? notes;
}
```

## Repository interface (already created — implement this)

```dart
// domain/repositories/workout_repository.dart
abstract class WorkoutRepository {
  Future<List<Machine>> getMachines();
  Future<WorkoutSession?> getLastSession();
  Future<List<WorkoutSession>> getSessionHistory();
  Future<List<WorkoutSet>> getSetsForSession(int sessionId);
  Future<List<WorkoutSet>> getSetsForMachine(int machineId);
  Future<WorkoutSession> startSession(DateTime sessionDate);
  Future<WorkoutSet> logSet(WorkoutSet set); // set.id is ignored on insert; returns the row with its real id
  Future<void> updateSet(WorkoutSet set);
  Future<void> deleteSet(int id);
}
```

## Domain use cases (`lib/features/workouts/domain/use_cases/`) — TDD, write the test first

- `group_sets_by_machine.dart` — pure function:
  ```dart
  List<MachineSetGroup> groupSetsByMachine(List<WorkoutSet> sets)
  ```
  Groups a flat list of `WorkoutSet` into one entry per `machineId`,
  preserving first-seen order (use `machineOrder` if present, else input
  order), each holding the machine's sets sorted by `setNumber`. Introduce a
  small `MachineSetGroup` record/class (`machineId`, `machineName`,
  `List<WorkoutSet> sets`) alongside this file — used by both the History
  detail page and the Log tab's in-progress list.
  **Test first**
  (`test/features/workouts/domain/group_sets_by_machine_test.dart`): feed
  sets across 2 machines interleaved by `setNumber`, assert each group's
  sets come back in `setNumber` order and groups preserve first-seen machine
  order. Confirm red, implement, confirm green.

- `compute_personal_record.dart` — pure function:
  ```dart
  WorkoutSet? computePersonalRecord(List<WorkoutSet> setsForOneMachine)
  ```
  Returns the set with the highest `weight` (nulls treated as lowest / never
  a PR — cardio machines with no weight data return `null`). Ties keep the
  earliest `loggedAt`. **Test first**: mixed weights including nulls and a
  tie, assert the right one wins.

- `summarize_session.dart` — pure function:
  ```dart
  String summarizeSession(List<WorkoutSet> sets) // e.g. "Chest Press, Squat, Treadmill"
  ```
  Comma-joins the distinct `machineName`s in first-seen order (reuses
  `groupSetsByMachine` internally, or its own light grouping — your call).
  Used by the History list row and the Log tab's "last workout" summary.
  **Test first**: sets across 3 machines with repeats, assert distinct names
  in first-seen order, comma-joined; empty list → `''`.

## Data layer (`lib/features/workouts/data/`)

- `models/machine_model.dart` — `MachineModel.fromJson` mapping a `machines`
  row to `Machine`. `aliases` is a Postgres `text[]` — arrives as a Dart
  `List<dynamic>`, cast each element to `String`.
- `models/workout_session_model.dart` — maps a `workout_sessions` row.
  `session_date` is a Postgres `date` (no time component) — parse with
  `DateTime.parse`, it'll come back as midnight UTC, that's fine to treat as
  date-only.
- `models/workout_set_model.dart` — maps a `workout_sets` row **joined with
  `machines(name)`** for `machineName` (`.select('*, machines(name)')`,
  `json['machines']['name']`). Numeric columns (`weight`, `incline`,
  `speed`, `duration_minutes`) don't consistently arrive as `String` — use
  `parseSupabaseNum` from `core/network/supabase_json.dart` for every
  nullable-numeric field, not `double.parse(... as String)`. Also needs a
  `toInsertJson()` for `logSet`/`updateSet` (no `machines` join on write,
  just the raw columns).
- `data_sources/workouts_remote_data_source.dart` — wraps `SupabaseClient`,
  one method per repository call:
  - `fetchMachines()` — all `machines` rows, ordered by `name`.
  - `fetchLastSession()` — `workout_sessions` ordered by `session_date`
    descending, `.limit(1).maybeSingle()`.
  - `fetchSessionHistory()` — all `workout_sessions` ordered by
    `session_date` **descending** (most recent first — see
    `docs/FUTURE_IMPROVEMENTS.md` Round 9 for a real bug this app hit before
    from an implicit ascending default; always pass `ascending:` explicitly).
  - `fetchSetsForSession(sessionId)` — `workout_sets` where `session_id =
    sessionId`, joined with `machines(name)`, ordered by `set_number`
    ascending.
  - `fetchSetsForMachine(machineId)` — same join, where `machine_id =
    machineId`, ordered by `logged_at` ascending.
  - `insertSession(sessionDate)` — insert into `workout_sessions`, return
    the created row.
  - `insertSet(WorkoutSetModel)` — insert into `workout_sets`, return the
    created row (re-fetch or use `.select()` after insert to get the real
    `id`).
  - `updateSet(WorkoutSetModel)` — update by `id`.
  - `deleteSet(id)` — delete by `id`.
  Use `SupabaseTables.machines` / `.workoutSessions` / `.workoutSets`
  constants (already added to `core/network/supabase_tables.dart` — don't
  hardcode table name strings).
- `repositories/supabase_workout_repository.dart` —
  `SupabaseWorkoutRepository implements WorkoutRepository`. Delegates raw
  fetches to the data source, maps models to entities. No aggregation logic
  here — `groupSetsByMachine`/`summarizeSession`/`computePersonalRecord`
  live in domain and get called by presentation, not by this repository.

## Tests to write (red, then green)

- The three domain use case tests above.
- `test/features/workouts/data/machine_model_test.dart`,
  `workout_set_model_test.dart`: feed realistic Supabase JSON (including a
  numeric field arriving as a JSON string, per the known gotcha) and assert
  correct parsing.

## Acceptance

`flutter analyze` clean, `flutter test test/features/workouts/domain
test/features/workouts/data` all green. Report the red→green transcript
summary and exact test output per `docs/ARCHITECTURE.md`.
