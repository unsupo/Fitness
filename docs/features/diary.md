# Feature: Diary (Dashboard / Home)

Read `docs/ARCHITECTURE.md` first — it defines the layer contract, tech stack,
schema, route contract, and the mandatory TDD workflow. This doc only covers
what's specific to this feature.

Reference: mockup "Image 1" — a Home dashboard with a date selector, meal
sections grouped by category, a daily calorie progress bar, and three macro
rings.

## What to build

### Domain (`lib/features/diary/domain/`)

`entities/food_item.dart`:
```dart
class FoodItem {
  final int id;
  final String name;
  final String? brand;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  // + servingSize, servingUnit, fiberG, sugarG, sodiumMg, isEstimate — all
  // nullable/optional except id/name/calories/proteinG/carbsG/fatG
}
```

`entities/diary_entry.dart` — one logged food (a `food_log` row):
```dart
class DiaryEntry {
  final int id;
  final DateTime loggedAt;
  final MealType mealType;   // from core/network/supabase_tables.dart
  final String foodName;     // denormalized from the joined foods row
  final double quantity;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
}
```

`entities/daily_goals.dart` — `calorieGoal`, `proteinGoalG`, `carbsGoalG`, `fatGoalG` (all `double`).

`entities/daily_totals.dart` — `calories`, `proteinG`, `carbsG`, `fatG` (all `double`).

`use_cases/compute_daily_totals.dart` — pure function:
```dart
DailyTotals computeDailyTotals(List<DiaryEntry> entries)
```
Sums calories/protein/carbs/fat across entries. **Write the test for this
first** (`test/features/diary/domain/compute_daily_totals_test.dart`): given a
list of 2-3 `DiaryEntry` fixtures, assert the summed `DailyTotals` is correct,
and assert an empty list produces all-zero totals.

`repositories/diary_repository.dart` — abstract interface:
```dart
abstract class DiaryRepository {
  Future<List<DiaryEntry>> getEntriesForDate(DateTime date);
  Future<DailyGoals> getDailyGoals();
}
```

### Data (`lib/features/diary/data/`)

- `models/diary_entry_model.dart`: `DiaryEntryModel` with
  `DiaryEntryModel.fromJson(Map<String, dynamic> json)` mapping a `food_log`
  row (joined with `foods.name`) to a `DiaryEntry`. Query the join via
  Supabase embedded resource syntax:
  `.select('*, foods(name)')` — the joined food comes back as
  `json['foods']['name']`. `meal_type` may be `null` for legacy rows; default
  to `MealType.snack` if so (use `MealType.fromString`, or handle null
  explicitly). Remember: numeric columns don't consistently arrive as
  `String` — use `parseSupabaseNum` from `core/network/supabase_json.dart`.
- `data_sources/diary_remote_data_source.dart`: wraps `SupabaseClient`,
  queries `food_log` where `logged_at >= startOfDay(date)` and
  `< startOfDay(date) + 1 day`, ordered by `logged_at`. Also fetches the
  single `daily_goals` row (`.select().limit(1).single()`).
- `repositories/supabase_diary_repository.dart`: `SupabaseDiaryRepository
  implements DiaryRepository`, delegates to the data source and maps models to
  entities. This is the Supabase **adapter** — the concrete implementation the
  app defaults to.

### Presentation (`lib/features/diary/presentation/`)

`controllers/diary_providers.dart`:
```dart
final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => SupabaseDiaryRepository(Supabase.instance.client),
);
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());
final diaryEntriesProvider = FutureProvider.family<List<DiaryEntry>, DateTime>(
  (ref, date) => ref.watch(diaryRepositoryProvider).getEntriesForDate(date),
);
final dailyGoalsProvider = FutureProvider<DailyGoals>(
  (ref) => ref.watch(diaryRepositoryProvider).getDailyGoals(),
);
```

`pages/diary_page.dart` — **`class DiaryPage extends ConsumerWidget`**,
constructor `const DiaryPage({super.key, this.mealTypeFilter})` where
`mealTypeFilter` is `MealType?`. Layout, top to bottom:

1. `AppBar`: leading `Icon(Icons.menu)` (no-op button is fine), title `Text('Nourish')`
   (styled via the theme's `appBarTheme`, already green/bold), trailing
   `Icon(Icons.notifications_none)`.
2. Date selector row: `<  Date: Jul 21, 2026  >` — left/right chevron
   `IconButton`s that shift `selectedDateProvider` by ±1 day, formatted with
   `intl`'s `DateFormat('MMM d, yyyy')`. Skip this row entirely when
   `mealTypeFilter != null` (the Breakfast tab is always "today").
3. If `mealTypeFilter == null`: one `SectionCard` per `MealType` (Breakfast,
   Lunch, Dinner, Snacks) that has at least one entry for the selected date —
   heading + a `ListTile` per `DiaryEntry` (leading a plain circular
   `CircleAvatar` with a food icon since there are no food images, title =
   food name, subtitle = "`${calories.round()} calories`"), plus a small
   circular orange `+` `IconButton` under the list that does
   `context.push('/scanner')`.
   If `mealTypeFilter != null`: a single `SectionCard` titled with
   `mealTypeFilter.label`, listing only entries matching that meal type.
4. `SectionCard` "Daily Calories": consumed/goal as `"${totals.calories.round()} / ${goals.calorieGoal.round()} cal"`,
   a `LinearProgressIndicator` (`value: totals.calories / goals.calorieGoal`,
   clamped 0-1, colored `AppColors.brandGreen`).
5. Row of three `MacroRing`s (from `core/widgets/macro_ring.dart`): Protein
   (`AppColors.proteinRing`), Carbs (`AppColors.carbsRing`), Fat
   (`AppColors.fatRing`), each `progress: totals.x / goals.xGoal`.

Use `ref.watch(diaryEntriesProvider(date))` and
`ref.watch(dailyGoalsProvider)` — handle `AsyncValue` loading/error states
with a simple centered `CircularProgressIndicator` / error text; don't over-engineer.

`widgets/meal_section.dart` and `widgets/daily_calorie_card.dart`: extract the
meal-list card and calorie card into their own widgets if `diary_page.dart`
gets long — your call, not required.

## Tests to write (red, then green)

- `test/features/diary/domain/compute_daily_totals_test.dart` (see above).
- `test/features/diary/presentation/diary_page_test.dart`: a
  `FakeDiaryRepository implements DiaryRepository` returning 2-3 fixed
  `DiaryEntry`s across two meal types and a fixed `DailyGoals`. Pump
  `ProviderScope(overrides: [diaryRepositoryProvider.overrideWithValue(fake)], child: MaterialApp(home: DiaryPage()))`.
  Assert: meal section headers are present, a food name from the fixture is
  found, the calorie text shows the expected computed total, at least one
  `MacroRing` renders. Also test the `mealTypeFilter` constructor path with
  its own case.

## Acceptance

`flutter analyze` clean, both test files pass, `DiaryPage` compiles standalone
(don't worry that `/scanner` doesn't exist yet — `context.push` is fine to
reference, it just won't be reachable from your tests unless you wrap in a
`MaterialApp` with no real router, which is fine for these widget tests).
