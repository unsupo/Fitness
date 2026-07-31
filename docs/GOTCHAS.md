# Gotchas

Recurring pitfalls and non-obvious fixes discovered while building this app —
distinct from `FUTURE_IMPROVEMENTS.md` (which is a chronological "what we
built and why" log). This file is a reference: read it before touching an
area it covers, so the same bug doesn't get rediscovered from scratch.

## Flutter / widget-layer

### `ListTile` with `onTap` needs a `Material` ancestor
A `ListTile` (or anything ink-splash-based) nested directly inside a
`Container`/`DecoratedBox` with a background color — with no `Material`
ancestor in between — renders fine locally on some Flutter versions but trips
a stricter framework assertion on others (see "CI Flutter version" below).
Symptom: ink splashes/background don't render, or a CI-only test failure with
no local repro. Fix: wrap in `Material(type: MaterialType.transparency, child:
ListTile(...))`. Hit and fixed three times so far: `meal_section.dart`,
`exercises_tab.dart`, `quick_add_modal.dart`. If you add a new `ListTile`
inside a colored container, wrap it preemptively.

### `RefreshIndicator` needs a genuinely scrollable child
`RefreshIndicator` only detects the pull gesture if its child is a real
`Scrollable` (`ListView`, etc.) — wrapping a `Column`/`Padding` does nothing,
including for empty states. If a page's empty state is a bare `SectionCard` in
a `Padding`, pull-to-refresh silently won't work on it. Fix: make the empty
state a single-item `ListView` containing that same `SectionCard`, so both
the populated and empty states share one genuinely scrollable widget tree.
See `recipes_list_page.dart`.

### `Dismissible` + async delete: track "locally removed" ids
Swipe-to-delete against a Riverpod-provided list has a timing gap: the item
is dismissed from the tree immediately (visually), but the underlying list
provider won't refresh until the delete request resolves and
`ref.invalidate(...)` runs — in between, Flutter throws "A dismissed
Dismissible widget is still part of the tree." Fix: keep a local
`Set<int> _locallyDeletedRecipeIds` in a `ConsumerStatefulWidget`, add the id
via `setState` in `onDismissed` *before* awaiting the delete call, and filter
the rendered list against that set. See `recipes_list_page.dart`.

### Gesture-arena conflicts inside a `Scrollable`
A `GestureDetector`'s `onPan*` callbacks can lose the gesture arena to an
ancestor `Scrollable`'s own drag recognizer whenever the gesture has any
vertical component — this passes in isolation (a standalone widget test with
no scrollable ancestor) and silently fails to fire once the same widget is
embedded inside a `SingleChildScrollView`/`ListView` (e.g. a dialog's
content). Symptom: drag produces zero change, no error, no exception — just
nothing happens. Fix: use `Listener` (raw `onPointerDown`/`onPointerMove`/
`onPointerUp` via `event.localPosition`) instead of `GestureDetector` —
`Listener` reads the raw pointer stream and bypasses the gesture arena
entirely, so it always wins over an ancestor scrollable. `Listener` is a
drop-in replacement for `flutter_test`'s `startGesture`/`moveTo`/`up` pointer
stream, so existing widget tests don't need to change. See
`adjustable_macro_pie_chart.dart` (caught via an integration test against the
real dialog, not the widget's own standalone tests, which all still passed).

### `AsyncValue` accessor convention in this codebase
Use `asyncValue.asData?.value` to read a possibly-not-yet-loaded value,
returning `null` while loading/erroring — not `.valueOrNull` (not available
on this project's `flutter_riverpod` version; using it is a silent
`undefined_getter` analyzer error, not a runtime one). Search the codebase for
the existing pattern before introducing a new accessor.

### adb tap coordinates are in native device pixels, not screenshot-preview pixels
Screenshots surfaced back to the assistant are scaled down for display (e.g.
a 1280×2856 device screenshot shown at 896×2000, with a "multiply by 1.43"
note). `adb shell input tap X Y` needs *native* device coordinates
(`adb shell wm size`), not the coordinates you'd read off the scaled preview
image. Forgetting the multiply is the most common cause of a tap that
silently lands on the wrong element.

### Lazy Riverpod Notifier build in unit tests
In Riverpod v3, `Notifier.build()` is executed lazily. When writing unit tests for a provider that performs asynchronous initialization inside its `build()` method (e.g. loading configurations from `SharedPreferences`), simply instantiating the `ProviderContainer` will not trigger `build()`. If you immediately await a delay or check state, the initialization code never runs. To fix this, you must explicitly read or listen to the provider (`container.read(provider)`) *before* introducing any asynchronous delays.

### Avoid ambiguous icon finders in widget tests
Using generic icon finders like `find.byIcon(Icons.delete_outline)` will throw a `TestFailure` due to ambiguous matches if the widget tree grows to include multiple instances of that icon (e.g., adding delete actions to individual list items while a parent delete action exists in the App Bar). Always assign unique keys or explicit tooltips to actions (e.g., `tooltip: 'Delete recipe'`) and locate them in tests using `find.byTooltip(...)` or `find.byKey(...)`.

## Domain logic

### Don't impose a percentage floor to make a drag-target "always grabbable"
When a draggable pie/ring's slice can shrink to literal 0% width, its two
boundaries collapse onto the same angle — annoying to grab precisely, but
**0% is a real, legitimate target state** (e.g. a keto diet wants 0% carbs).
The tempting fix — clamp every slice to a minimum floor (e.g. 5%) so it can
never fully collapse — silently makes a real goal unreachable. The correct
fix is a UI affordance, not a data constraint: draw a persistent, fixed-size
handle marker at every boundary angle regardless of how small (even zero) the
adjacent slices are, so there's always something visible and grabbable, while
the underlying domain logic (`adjustMacroSliceBoundary` in
`macro_calorie_split.dart`) still clamps at literal zero. See
`adjustable_macro_pie_chart.dart`'s white knob markers.

### A rounded display value must not silently become the source of truth
`edit_daily_goals_dialog.dart`'s weekly-rate slider snapped its *displayed*
label to the nearest 0.25 grid on load, while the calorie field showed the
exact stored value — so a goal of "2000 cal" could show next to a rounded
"1.25 lb/week" label that didn't actually correspond to 2000 cal (the real
rate was ~1.20). Interacting with the slider then recomputed calories *from*
the rounded label, visibly changing the calorie number the user hadn't
touched. Rule: when deriving a display label from an exact value, don't round
it just to align with a control's step grid — only round the value that
control itself produces when the user actually moves it. The `Slider`
widget's `divisions` already snaps drag *input*; it doesn't require the
*initial* `value` to be pre-snapped, and forcing it to be introduces exactly
this kind of drift.

### `numeric` Postgres columns come back as `String` via `supabase_flutter`
Every model reading a `numeric` column must `double.parse()` it, not cast —
casting compiles but throws at runtime the first time real data flows
through. Easy to miss when a column is nullable, since a null short-circuits
past the parse in testing but a real non-null string won't.

### Postgrest `.order('col')` defaults to descending, not ascending
`fetchAllWeightLogRows`/`getEntriesForDate` both silently returned
newest-first because `.order()` had no explicit `ascending:` argument.
Fake-repository-backed widget tests never catch this class of bug (they don't
go through the real Postgrest query builder) — only live/integration testing
does. Always pass `ascending: true` explicitly when order matters.

### Timezone conversions belong at the read/write boundary, not at display time
Convert once, at the model layer: `.toLocal()` when parsing a Supabase
timestamp into a model, `.toUtc()` before sending a `DateTime` into a query
filter or insert payload. Scattering conversions at display time instead
(or, worse, skipping them and relying on `DateTime`'s ambient UTC/local flag)
reliably produces off-by-timezone-offset bugs that reappear in multiple
places independently — this happened three separate times in this codebase
(`DiaryEntryModel`/`WeightEntryModel.loggedAt`, `fetchFoodLogEntries`'s range
query, `WeightEntryModel.toInsertJson`) before the pattern was applied
everywhere consistently.

## CI / tooling

### CI's `channel: stable` can silently drift ahead of your local Flutter
`subosito/flutter-action@v2` with `channel: stable` (no pinned version)
resolves to whatever `stable` currently is *at CI run time* — this can be
newer than a long-lived local install, and a newer Flutter can enforce a
stricter framework assertion (see the `ListTile`/`Material` gotcha above)
that an older local Flutter doesn't catch. A test that fails only in CI,
passing 100% locally across repeated runs, is a version-skew signal — compare
`flutter --version` locally against the `FLUTTER_ROOT` path in the CI log
before assuming flakiness.

### `integration_test`/widget-test string assertions go stale when copy changes
`find.text('Macro Breakdown')` broke silently (CI-only, since that's the only
job that exercises it) after the heading became `'Macro Breakdown ($weekRange)'`
— the assertion wasn't updated in the same change, and this went unnoticed
for two pushes since the CI failure output wasn't checked immediately after
each one. When changing user-facing copy, `grep` the test suite (including
`integration_test/`) for the old literal string, not just the `lib/` call
site. Prefer `find.textContaining(...)` over `find.text(...)` for assertions
on copy that's likely to grow a suffix/prefix later (dates, counts, units).
