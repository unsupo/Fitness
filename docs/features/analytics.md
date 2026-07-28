# Feature: Analytics (Trends)

Read `docs/ARCHITECTURE.md` first — layer contract, tech stack, schema, route
contract, and the mandatory TDD workflow are defined there. This doc only
covers what's specific to this feature.

Reference: mockup "Image 4" — a Trends screen with a segmented control
(Weekly / Progress / Trends), a weekly calories bar chart with a goal line, a
macro breakdown donut chart, and a weight line chart with current
weight/goal.

## Domain (`lib/features/analytics/domain/`)

`entities/daily_calories.dart` — `date` (`DateTime`, truncated to day),
`totalCalories` (`double`).

`entities/macro_breakdown.dart` — `proteinG`, `carbsG`, `fatG` (`double`),
plus a computed getter `proteinPercent`/`carbsPercent`/`fatPercent` (share of
total grams — not calories; matches the mockup's simple 3-way split).

`entities/weight_entry.dart` — `id` (`int`), `loggedAt` (`DateTime`),
`weightKg` (`double`), `goalType` (`String`: `'maintain' | 'lose' | 'gain'`).

`use_cases/group_calories_by_day.dart` — pure function:
```dart
List<DailyCalories> groupCaloriesByDay(
  List<({DateTime loggedAt, double calories})> rawEntries,
  DateTime weekStart, // inclusive, 7 days from here
)
```
Buckets raw `food_log`-shaped tuples into exactly 7 `DailyCalories`, one per
day of the week starting at `weekStart` (days with no entries get `0`).
**Write the test first**
(`test/features/analytics/domain/group_calories_by_day_test.dart`): feed a
handful of entries across 3 different days within the week plus one entry
outside the range, assert the returned list has 7 entries in date order, the
right days have the right summed totals, the out-of-range entry is excluded,
and days with no entries are `0`. Confirm red, then implement, confirm green.

`use_cases/compute_macro_breakdown.dart` — pure function summing
protein/carbs/fat across a list of `({double proteinG, double carbsG, double
fatG})`-shaped entries into one `MacroBreakdown`. Same TDD approach, its own
test file.

`repositories/analytics_repository.dart`:
```dart
abstract class AnalyticsRepository {
  Future<List<DailyCalories>> getWeeklyCalories(DateTime weekStart);
  Future<MacroBreakdown> getMacroBreakdown(DateTime rangeStart, DateTime rangeEnd);
  Future<List<WeightEntry>> getWeightHistory();
  Future<double> getCalorieGoal();
  Future<void> logWeight(double weightKg, String goalType);
}
```

## Data (`lib/features/analytics/data/`)

- `models/weight_entry_model.dart` — maps a `weight_log` row
  (`id`, `logged_at`, `weight_kg`, `goal_type`) to `WeightEntry`. Numeric
  columns don't consistently arrive as `String` — use
  `parseSupabaseNum` from `core/network/supabase_json.dart`, not `double.parse(... as String)`.
- `data_sources/analytics_remote_data_source.dart` — wraps `SupabaseClient`:
  - fetch `food_log` rows (`logged_at`, `calories`, `protein_g`, `carbs_g`,
    `fat_g` columns only) within a date range, for both the weekly-calories
    and macro-breakdown queries (aggregate client-side using the domain use
    cases above — no SQL aggregation needed).
  - fetch all `weight_log` rows ordered by `logged_at`.
  - fetch the single `daily_goals` row for `calorie_goal`.
  - insert a `weight_log` row for `logWeight`.
- `repositories/supabase_analytics_repository.dart` —
  `SupabaseAnalyticsRepository implements AnalyticsRepository`. This is the
  **adapter** — delegates raw fetches to the data source, then calls
  `groupCaloriesByDay` / `computeMacroBreakdown` from domain to shape the
  result. Repository implementations should contain no aggregation logic
  themselves — that belongs in the domain use cases (keeps them unit
  testable without Supabase).

## Presentation (`lib/features/analytics/presentation/`)

`controllers/analytics_providers.dart` — `analyticsRepositoryProvider`, plus
`FutureProvider`s: `weeklyCaloriesProvider(weekStart)`,
`macroBreakdownProvider((start, end))` (family with a record or a small
params class), `weightHistoryProvider`, `calorieGoalProvider`.

`pages/trends_page.dart` — **`class TrendsPage extends ConsumerWidget`**,
const no-arg constructor. Matches mockup Image 4:

1. `AppBar`: leading hamburger, title `Nourish`, trailing close `X` (`context.pop()` if there's somewhere to pop, otherwise omit — this is a bottom-nav tab so likely no pop target; a no-op or omitted trailing icon is fine).
2. A week-range header row: `< Oct 20-26 >`-style with chevrons shifting a
   local "week start" `StateProvider<DateTime>`, and a segmented control /
   `TabBar` with three labels **Weekly / Progress / Trends** (cosmetic — see
   below for what each shows; don't overthink this, closely matching the look
   matters more than the tab semantics).
3. `SectionCard` "Weekly Calories": a `fl_chart` `BarChart`, 7 bars (one per
   day, `DailyCalories.totalCalories`), an `x`-axis of day-of-month numbers, a
   dashed horizontal goal line at `calorieGoalProvider`'s value (fl_chart
   `extraLinesData`), bars colored using a small rotating palette from
   `AppColors` (protein/carbs/fat/brandGreen — doesn't need semantic meaning
   per bar, just visual variety matching the mockup).
4. `SectionCard` "Macro Breakdown": a `fl_chart` `PieChart` donut (use
   `sections` with a hole via `centerSpaceRadius`) with 3 sections
   (Protein/Carbs/Fat, colored via `AppColors.proteinRing/carbsRing/fatRing`),
   a small legend to the side listing each with its percent, matching the
   mockup's "Fat 30% / Fat 30%" style labels (use the entity's percent
   getters).
5. `SectionCard` "Weight": current weight (`"Current Weight: ${last entry's
   weightKg} kg"`) and goal (`"Goal: ${goalType}"` — capitalize) as header
   text, an `fl_chart` `LineChart` below plotting `weightKg` over
   `loggedAt` for all `WeightEntry` history (x-axis labelled by month via
   `intl`'s `DateFormat('MMM')`). If `weightHistoryProvider` returns an empty
   list, show a friendly empty state instead of an empty chart: centered text
   "No weigh-ins yet" plus a small "Log weight" `TextButton` that opens a
   `showDialog` with a single numeric `TextField` (kg) and a `DropdownButton`
   for goal type (`maintain`/`lose`/`gain`), calling `logWeight` on submit and
   invalidating `weightHistoryProvider`.

Use `AsyncValue` loading/error handling consistent with the diary feature —
simple centered spinner/error text, don't over-engineer.

## Tests to write (red, then green)

- `test/features/analytics/domain/group_calories_by_day_test.dart` (see above).
- `test/features/analytics/domain/compute_macro_breakdown_test.dart` (see above).
- `test/features/analytics/presentation/trends_page_test.dart`: a
  `FakeAnalyticsRepository implements AnalyticsRepository` returning fixed
  `DailyCalories`/`MacroBreakdown`/`WeightEntry` lists and a fixed calorie
  goal. Pump `TrendsPage` with the provider overridden, assert the section
  headings render, a known weight value's text is found, and the empty-state
  path (empty `weightHistoryProvider` list → "No weigh-ins yet" text) also
  has its own test case with a repository returning `[]`.

## Acceptance

`flutter analyze` clean, all analytics tests pass.
