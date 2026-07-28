# Feature: Scanner (Barcode Scan + AI Food Recognition)

Read `docs/ARCHITECTURE.md` first — layer contract, tech stack, schema, route
contract, and the mandatory TDD workflow are defined there. This doc only
covers what's specific to this feature.

References: mockup "Image 2" (barcode scan → bottom sheet with KIND Bar
example) and "Image 3" (AI photo recognition → hero image + macro
breakdown + save).

This feature has **two** independent flows sharing one data-writing path.

## Decisions already made (don't re-litigate)

- Barcode lookup: real integration with **OpenFoodFacts**, no API key needed.
  Endpoint: `GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json`.
- AI food recognition: **stubbed**. Build the full UI flow (capture photo →
  hero image → macro breakdown → adjust serving → save) but the "recognition"
  call returns a mocked, plausible result. Mark the seam clearly with a
  `// TODO(vision-api):` comment — do not wire a real vision model.

## Domain (`lib/features/scanner/domain/`)

`entities/scanned_product.dart`:
```dart
class ScannedProduct {
  final String barcode;
  final String name;
  final String? brand;
  final double? servingWeightG;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double sugarG;
  final double fatG;
}
```

`entities/recognized_meal.dart`:
```dart
class RecognizedMeal {
  final String name;
  final double estimatedCalories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double servings; // adjustable by the user before saving
}
```

`repositories/barcode_lookup_repository.dart`:
```dart
abstract class BarcodeLookupRepository {
  Future<ScannedProduct?> lookup(String barcode); // null = not found
}
```

`repositories/food_recognition_repository.dart`:
```dart
abstract class FoodRecognitionRepository {
  Future<RecognizedMeal> recognize(XFile image); // XFile from image_picker/camera
}
```

`repositories/food_logging_repository.dart` (shared write path for both flows):
```dart
abstract class FoodLoggingRepository {
  /// Inserts into `foods` if the barcode isn't already known there, then
  /// inserts a `food_log` row referencing it.
  Future<void> logScannedProduct(ScannedProduct product, MealType mealType);

  /// Inserts a `foods` row for the recognized meal (source = 'ai_estimate',
  /// is_estimate = true) then a `food_log` row referencing it.
  Future<void> logRecognizedMeal(RecognizedMeal meal, MealType mealType);
}
```

## Data (`lib/features/scanner/data/`)

- `models/scanned_product_model.dart` — `ScannedProductModel.fromOpenFoodFactsJson(Map<String, dynamic> json)`
  mapping OpenFoodFacts' response shape: `json['product']['product_name']`,
  `json['product']['brands']`, `json['product']['nutriments']['energy-kcal_100g']`,
  `['proteins_100g']`, `['carbohydrates_100g']`, `['sugars_100g']`, `['fat_100g']`.
  OpenFoodFacts nutriments are **per 100g**; if `product_quantity` (grams) is
  present, scale to that serving size for display, else default to showing
  per-100g values with `servingWeightG = 100`. Handle missing/null nutriment
  fields by defaulting to `0`. **Write the mapping test first**
  (`test/features/scanner/data/scanned_product_model_test.dart`) using a
  hardcoded JSON fixture string (a real-shaped OpenFoodFacts payload you write
  by hand — do not make a network call in the test) — assert the parsed
  fields. Confirm it fails before the mapper exists, then implement.
- `data_sources/open_food_facts_data_source.dart` — wraps `Dio`, GET the
  endpoint above, returns the raw decoded JSON (or throws on non-200 /
  `status: 0` meaning "not found" → return `null` upstream).
- `repositories/open_food_facts_repository.dart` — `OpenFoodFactsBarcodeRepository implements BarcodeLookupRepository`. This is the **adapter** — swappable for FatSecret/Edamam later without touching the scanner UI.
- `data_sources/stub_recognition_data_source.dart` /
  `repositories/stub_food_recognition_repository.dart` —
  `StubFoodRecognitionRepository implements FoodRecognitionRepository`.
  Returns a fixed or lightly-randomized plausible `RecognizedMeal` (e.g. cycle
  through 2-3 canned meals like "Arugula Salad with Grilled Chicken" /
  380 kcal / 38g protein / 12g carbs / 22g fat, matching mockup Image 3,
  after an `await Future.delayed(const Duration(milliseconds: 600))` to
  simulate latency). `// TODO(vision-api): replace with a real multimodal
  vision call (e.g. Claude/GPT vision) — see docs/FUTURE_IMPROVEMENTS.md`.
- `repositories/supabase_food_logging_repository.dart` —
  `SupabaseFoodLoggingRepository implements FoodLoggingRepository`, using
  `Supabase.instance.client`. For `logScannedProduct`: check if a `foods` row
  with that `source = 'openfoodfacts'` and matching `name`+`brand` exists
  (simplest: just always insert a new `foods` row per scan — do not
  over-engineer dedup logic — set `source: 'openfoodfacts'`), then insert
  `food_log` with `logged_at: DateTime.now().toUtc()`, computed
  calories/protein/carbs/fat for the serving, and `meal_type: mealType.name`.
  For `logRecognizedMeal`: same pattern with `source: 'ai_estimate'`,
  `is_estimate: true`, quantities scaled by `servings`.

## Presentation (`lib/features/scanner/presentation/`)

`controllers/scanner_providers.dart` — `barcodeLookupRepositoryProvider`,
`foodRecognitionRepositoryProvider`, `foodLoggingRepositoryProvider`, each a
plain `Provider` wiring the Supabase/OpenFoodFacts/stub implementations above.

`pages/barcode_scanner_page.dart` — **`class BarcodeScannerPage extends ConsumerStatefulWidget`**,
no-arg const constructor. Matches mockup Image 2:
- Full-screen `MobileScanner` widget (from `mobile_scanner`) as the
  background/viewfinder, with a close `X` button top-left (`context.pop()`)
  and title `Nourish` centered in a translucent app bar.
- On `onDetect`, take the first barcode value, call
  `barcodeLookupRepositoryProvider`'s `lookup()`, and if a product is found,
  show a bottom sheet (`showModalBottomSheet`, or an animated bottom panel
  that doesn't block the camera preview like the mockup) with: product name,
  `"Weight: ${servingWeightG}g"`, then a row of 4 stat columns — Calories /
  Protein / Sugar / Fat, each with a small colored underline bar (mimic the
  mockup's little progress bars under each stat) — and an "Add to Diary"
  button that calls `logScannedProduct` with `MealType.snack` (simplest
  default; a meal-type picker is a nice-to-have, not required) then
  `context.pop()` back to the diary. Debounce `onDetect` (e.g. a `bool
  _handling` flag) so the same barcode doesn't trigger multiple lookups per
  frame.
- If `lookup()` returns `null` (not found), show a small "Product not found"
  snackbar instead of a sheet, and keep scanning.

`pages/food_recognition_page.dart` — **`class FoodRecognitionPage extends ConsumerStatefulWidget`**,
no-arg const constructor. Matches mockup Image 3:
- Uses the `camera` package to show a live preview with a shutter button
  (bottom center circular button, mimicking the mockup's capture UI), OR — if
  camera initialization fails/is unavailable (e.g. no camera permission in an
  emulator), fall back gracefully to an `Icons.photo_camera` button that
  invokes recognition directly on a placeholder without crashing (don't let a
  missing camera hard-fail the screen).
- After capture (or immediately in the fallback path), show a loading state,
  call `foodRecognitionRepositoryProvider.recognize(...)`, then transition to
  a result view: a large rounded hero image area (use the captured photo if
  available, else a plain colored placeholder container — do not fetch a
  stock photo), the recognized meal name as a heading, `"~${calories.round()} kcal"`
  subtitle, and a stat row Calories / Protein / Carbs / Fat matching the
  diary's macro styling. A `Stepper`-like serving adjuster (a simple `Row`
  with `-`/`+` `IconButton`s around the `servings` value is enough — no need
  for the full `Stepper` widget) and a "Save to Diary" button calling
  `logRecognizedMeal` then `context.pop()`.

## Tests to write (red, then green)

- `test/features/scanner/data/scanned_product_model_test.dart` (see above,
  write first).
- `test/features/scanner/presentation/barcode_scanner_page_test.dart` or
  a narrower widget test for just the result bottom-sheet content widget
  (extract it as `widgets/scanned_product_sheet.dart` if that makes it
  testable without mocking the camera plugin — `MobileScanner` itself needs a
  real platform camera and is awkward to pump in a widget test, so test the
  **sheet content widget** in isolation given a fixed `ScannedProduct`, not
  the whole scan flow).
- `test/features/scanner/presentation/food_recognition_result_test.dart`:
  extract the result view (hero + macros + serving stepper + save button)
  into its own widget (e.g. `widgets/recognized_meal_result.dart`) so it's
  testable given a fixed `RecognizedMeal`, independent of the camera package.

## Acceptance

`flutter analyze` clean, all scanner tests pass. It's fine — expected, even —
that the full camera/scanner widget classes themselves aren't unit-tested
end-to-end; that's proven visually in the centralized closed-loop pass on a
real emulator afterward.
