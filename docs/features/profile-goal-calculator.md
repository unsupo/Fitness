# Feature request: Profile — bidirectional weekly-loss ↔ calorie-goal calculator

Status: **not yet scoped for implementation** — captured from user feedback,
2026-07-29.

## Request

On the Profile page, the user should be able to set either:
- a **targeted weekly weight loss/gain rate** (e.g. "lose 1 lb/week"), or
- a **daily calorie goal** directly,

and changing one should automatically recompute the other. Today these are
disconnected: `_DailyGoalsSection` (`profile_page.dart`) edits
`DailyGoals.calorieGoal` via `showEditDailyGoalsDialog` as a flat number with
no relationship to weight-change rate, and `_BiometricProfileSection`'s
`showEditWeightGoalDialog` only captures TDEE inputs + a target *weight*
(not a rate) — used purely for the Trends projection graph, not for setting
`calorieGoal`.

## What's already there to build on

- `estimateTdee({required UserProfile profile, required double weightKg})`
  (`analytics/domain/use_cases/estimate_tdee.dart`) — Mifflin-St Jeor TDEE
  estimate, already used for the weight-projection graph.
- Standard conversion: 1 lb of body fat ≈ 3500 kcal (≈ 7700 kcal/kg). A
  weekly rate → daily calorie delta is `rate_per_week * kcal_per_unit / 7`.

## Shape of the calculation

```dart
double calorieGoalForWeeklyRate({
  required double tdee,
  required double weeklyRateKg, // negative = loss, positive = gain
}) => tdee - (weeklyRateKg * 7700 / 7);

double weeklyRateForCalorieGoal({
  required double tdee,
  required double calorieGoal,
}) => (tdee - calorieGoal) * 7 / 7700;
```
(Write these as a pure, TDD'd use case — e.g.
`domain/use_cases/weekly_rate_calorie_goal.dart` — before wiring up any UI,
per the project's mandatory red/green workflow.)

## UI implications

- This calculator needs `UserProfile` (for TDEE inputs) **and** a current
  weight (for `estimateTdee`'s `weightKg` param — probably the latest
  `WeightEntry`) available wherever the calorie goal is edited. Today
  `_DailyGoalsSection` and `_BiometricProfileSection` are separate cards
  with separate providers (`dailyGoalsProvider` vs `userProfileProvider`) —
  this feature effectively couples them, so the edit surface may need to
  become one combined section/dialog rather than two independent ones, or
  the daily-goals dialog needs to reach into `userProfileProvider` /
  `weightHistoryProvider` as additional inputs.
- If `UserProfile` is incomplete (no TDEE inputs yet — same
  `isCompleteForTdee` gate already used elsewhere), the rate-based input
  should prompt to complete the profile first, same pattern as the existing
  Weight Goal projection card's empty state.
- Decide on rate step granularity in the UI (e.g. slider in 0.25 lb/kg
  increments vs free-text) — not specified by the user, flag as an open
  question rather than guessing.

## Sequencing note

Do the pure calculation use case + its tests first (cheap, no UI
ambiguity), then decide the combined-vs-separate-dialog question above
before touching `profile_page.dart`.
