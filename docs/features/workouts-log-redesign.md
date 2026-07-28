# Workouts — Log Tab Redesign (Strong-style set rows + workout reuse)

**Status: spec only, not implemented.** Written at the user's request to
scope out before any code changes. Read `docs/ARCHITECTURE.md` (TDD
workflow) and `docs/WORKOUTS_PLAN.md` (overall Workouts context) first —
this doc only covers what's changing in the Log tab.

## Why

The current Log tab's active-session exercise card
(`lib/features/workouts/presentation/widgets/log_exercise_card.dart`) shows
already-logged sets as plain read-only text rows (tap to open an edit
dialog), plus one shared inline form below them to add a new set. The user
wants this closer to how Strong actually works:

1. **Swipe to remove a set** — no dialog needed for a simple delete.
2. **Two always-visible fields per row** (Weight, Reps) — not a separate
   form section below the list; every set, logged or not-yet-logged, is a
   row with its own inline editable fields.
3. **"Previous" shown right in the row** — a hint of what you did last time
   for that set, so you know what to beat without leaving the screen.
4. **No separate "Add Set" button as the primary affordance** — Strong adds
   a new blank row inline (a lightweight "+ Add Set" row at the bottom of
   the table, not a distinct form/button below unrelated content).
5. **Reuse a previous workout** — starting a new session should let you
   pick a past session as a template, pre-loading the same exercises (not
   their weights/reps) so you're not re-adding each exercise from scratch
   every time you repeat a routine.

## Current schema recap (unchanged — no migration needed for this redesign)

`workout_sets(id, logged_at, machine_id, set_number, weight, reps, unit,
notes, session_id, machine_order, incline, speed, duration_minutes,
seat_position, rest_seconds)` — see `docs/WORKOUTS_PLAN.md`. No "completed"
boolean, no template/routine table. This redesign works within the existing
schema; "reuse a previous workout" is a **client-side copy of exercise
selection**, not a new persisted "template" concept (see Open Questions).

## 1. Set-row redesign (`LogExerciseCard`)

Replace the current "list of read-only rows + one form below" with a
Strong-style table: **every set for this machine, logged or in-progress, is
one row** with its own inline `Weight`/`Reps` (or cardio equivalent) fields.

Per row, left to right:
- `Set N` label.
- **Previous** — greyed-out hint text showing what was logged for set N of
  this machine the *last time it was performed* (see "Previous" semantics
  below). Rendered as placeholder-style text, not a real value — matches
  Strong's greyed "135 x 8" hint in the previous-value column.
- `Weight` text field — for a not-yet-confirmed row, empty with the
  previous value as its placeholder (so leaving it blank and confirming
  reuses last time's weight, matching Strong's real behavior).
- `Reps` text field — same placeholder behavior.
- A confirm/check icon button — tapping it calls `logSet` (new row) or
  `updateSet` (already-logged row being edited) with whatever's in the
  fields, falling back to the previous value for any field left blank.
  Matches Strong's checkmark-to-log interaction; there is no separate
  "Add Set" submit button anymore.
- Swipe left on the row (`Dismissible`) removes it: if the set was already
  persisted, calls `WorkoutRepository.deleteSet`; if it's a local
  not-yet-confirmed blank row, just removes it from local state (no
  repository call). Show a `SnackBar` with "Set removed" — no Undo action
  for v1 (keep it simple; add Undo later if requested).

Below the last row, a lightweight `+ Add Set` row/link (not a big
`FilledButton`) appends one more blank, not-yet-confirmed row locally
(`setNumber = existing count + 1`), with **Previous** pre-filled from that
same set number last time, or from the *last* previous set if this is a new
set number beyond what was done last time (e.g. doing a 4th set when last
time only had 3 — fall back to set 3's previous value).

### "Previous" semantics — new domain use case needed

Add `domain/use_cases/previous_set_for.dart` (TDD, own test file):

```dart
/// Given [history] (all past sets for one machine, any session) and the
/// [setNumber] being logged now, returns the set with that same setNumber
/// from the most recent *prior* session that logged this machine — or, if
/// that session didn't have that many sets, the last set of that session
/// (closest available). Returns null if there's no history at all.
WorkoutSet? previousSetFor(List<WorkoutSet> history, int setNumber)
```
Test cases: exact set-number match in the most recent prior session; falls
back to the last set of that session when it had fewer sets than requested;
returns null for no history; ignores sets from the *current* in-progress
session (caller passes history that excludes it, or the function filters by
an explicit `excludeSessionId` param — TBD during implementation, whichever
keeps the function pure and easily testable).

This needs `WorkoutRepository.getSetsForMachine(machineId)` (already
exists) called from the Log tab when an exercise is added, to have history
available for the "Previous" column without a new repository method.

## 2. "Reuse a previous workout"

On the Log tab's **idle state**, next to (or replacing part of) the "Last
workout" summary card: a "Repeat this workout" action that starts a new
session and pre-populates the active exercise list with the *same machines*
(not sets/values) from that past session, in the same order
(`machineOrder`/first-seen order via `groupSetsByMachine`). The user still
logs fresh sets against each — this only saves re-adding exercises one by
one via the picker sheet.

Likely also worth a lightweight "or pick a different past workout" path
from the **History tab** — e.g. an action on `WorkoutSessionDetailPage`
("Repeat this workout") that navigates to `/workouts` (Log tab) with that
session's machine list pre-loaded. Exact entry point (idle-card button vs.
History-page action vs. both) — see Open Questions.

Mechanically: `LogTab`/`LogActiveView`'s local `_activeMachines` list (the
already-existing client-side tracked list, see `log_tab.dart`) gets
seeded from `groupSetsByMachine(pastSessionSets).map((g) => machine-for(g))`
instead of starting empty. No new repository method needed —
`getSetsForSession(pastSessionId)` (already exists) supplies the machine
list.

## Files touched (estimate, not final)

- `lib/features/workouts/domain/use_cases/previous_set_for.dart` (new) +
  test.
- `lib/features/workouts/presentation/widgets/log_exercise_card.dart`
  (rewrite: table-row model instead of list-of-text + form).
- `lib/features/workouts/presentation/widgets/log_active_view.dart` (pass
  per-machine history into each `LogExerciseCard` for the Previous column).
- `lib/features/workouts/presentation/widgets/log_idle_view.dart` /
  `log_last_workout_card.dart` (add the "Repeat this workout" action).
- `lib/features/workouts/presentation/pages/log_tab.dart` (seed
  `_activeMachines` when repeating).
- Possibly `workout_session_detail_page.dart` (repeat-from-History entry
  point, if in scope).
- Test files for each of the above, red/green per `docs/ARCHITECTURE.md`.

## Open questions (need your call before implementation starts)

1. **Confirm-per-row vs. auto-save**: should tapping the checkmark be the
   only way a row's weight/reps gets saved, or should it also auto-save on
   losing focus (tab to next field)? Recommend checkmark-only for v1 —
   matches Strong exactly, and avoids partial/accidental writes while
   typing.
2. **Swipe-delete confirmation**: no confirmation dialog (immediate
   delete + SnackBar, no Undo) — matches Strong's speed, but is a step back
   from the current tap-to-edit dialog's explicit "Delete set" button. Fine
   to ship as-is, or do you want an Undo action on the SnackBar?
3. **"Repeat this workout" entry point**: idle-card button only, a History
   action only, or both? Recommend both, but only-idle-card is a smaller
   first cut.
4. **Should "Previous" also show for cardio machines** (incline/speed/
   duration instead of weight/reps)? Recommend yes, same mechanism, just
   different fields — but confirm before implementation to avoid scope
   surprise.

## Acceptance (once scoped/approved)

Same bar as the rest of Workouts: TDD red/green for the new domain use
case and every changed widget, `flutter analyze` clean, closed-loop
verification on a real device against live Supabase data before calling it
done.
