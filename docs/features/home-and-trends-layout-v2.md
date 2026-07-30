# Feature request: Home/Diary and Trends layout changes

Status: **not yet scoped for implementation** — captured from user feedback,
2026-07-29.

## 1. Foods should render as a list of items

On Home (`lib/features/diary/presentation/pages/diary_page.dart` /
`meal_section.dart`), logged foods within a meal section are currently
`ListTile`s with a placeholder `CircleAvatar` icon (no food image, see
`diary.md`'s original spec). Request: make this an actual list-of-items
presentation — likely meaning show the food's `imageUrl` (already on
`FoodItem`/`DiaryEntry`? check — `FoodItem.imageUrl` exists today,
`DiaryEntry` does not, so it needs to flow through the join) instead of a
generic icon, so each row reads as a distinct item rather than an icon +
text row.

## 2. Weight list → horizontal scrolling

Trends page (`trends_page.dart`, `_WeightBody`/weigh-in history list below
the chart — the "Show all (N)" `ListTile`-per-entry list) should become a
horizontally-scrolling row of cards instead of a vertical list. Same visual
pattern should apply to whatever weekly-calories list looks like once #3
below is built (i.e. both should scroll horizontally, not stack vertically).

## 3. Weekly Calories → stacked macro chart

The "Weekly Calories" section (`trends_page.dart`, the `Weekly` tab /
`_CaloriesSection` — need to find/confirm the actual widget name at
implementation time) currently shows... (confirm current chart type before
starting — this doc doesn't assume calorie-only bars vs already-stacked).
Requested end state: a **stacked bar/area chart per week**, each bar split
into protein/carbs/fat segments (like `fl_chart`'s `BarChartGroupData` with
multiple `BarChartRodStackItem`s), not just a single total-calories value —
so macro composition trends are visible at a glance, not just total intake.

## 4. Extras tab structure doesn't make sense — collapse to just Trends

`trends_page.dart:139`: `static const _labels = ['Weekly', 'Progress',
'Trends']`. Per `trends_page_test.dart`, today's three tab-like views are:

- Default/"Trends": all three sections (Weekly Calories, Macro Breakdown,
  Weight) shown together.
- "Weekly": only the calories chart.
- "Progress": macro breakdown + weight, not calories.

User feedback: this three-way split has no logical grouping that makes
sense — splitting "Weekly" and "Progress" out from the combined view just
fragments one page into three for no clear reason. **Requested: remove the
tab bar entirely (or at minimum remove the Weekly/Progress tabs) and always
show the unified Trends view** (calories + macros + weight together, which
is what "Trends" already shows). Needs re-checking whatever routes/deep
links currently target the Weekly/Progress tabs specifically before ripping
the tab bar out.

## Notes for whoever picks this up

These four are related but separable — the tab-collapse (#4) is probably
the highest-leverage/lowest-risk one to do alone first, since it's UI-only
around an existing single page, no new repository methods needed. #1-#3
each likely need at least one new domain/data change (image join for #1,
new stacked-series shape for #3) — scope them independently rather than as
one PR.
