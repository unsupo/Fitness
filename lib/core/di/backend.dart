import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/diary/domain/repositories/diary_repository.dart';
import '../../features/recipes/domain/repositories/recipe_repository.dart';
import '../../features/scanner/domain/repositories/barcode_lookup_repository.dart';
import '../../features/scanner/domain/repositories/food_logging_repository.dart';
import '../../features/scanner/domain/repositories/food_recognition_repository.dart';
import '../../features/workouts/domain/repositories/workout_repository.dart';

/// A factory for one concrete set of backend adapters — one implementation
/// per storage/service technology the app could run against. Every feature
/// depends only on this abstract factory (via [backendProvider]), never on
/// a concrete class like `SupabaseDiaryRepository` directly. Swapping
/// backends means writing a new [Backend] implementation and changing the
/// single override in `main.dart` — no feature code changes.
abstract class Backend {
  DiaryRepository createDiaryRepository();
  RecipeRepository createRecipeRepository();
  AnalyticsRepository createAnalyticsRepository();
  BarcodeLookupRepository createBarcodeLookupRepository();
  FoodRecognitionRepository createFoodRecognitionRepository();
  FoodLoggingRepository createFoodLoggingRepository();
  WorkoutRepository createWorkoutRepository();
}

/// No default implementation on purpose: every entry point (`main.dart`,
/// widget tests that exercise more than one feature) must explicitly choose
/// a [Backend]. Feature-level widget tests instead override each feature's
/// own `xRepositoryProvider` directly with a fake — they never need this
/// provider at all.
final backendProvider = Provider<Backend>(
  (ref) => throw UnimplementedError(
    'No Backend configured. Override backendProvider — see '
    'lib/core/di/supabase_backend.dart for the default (Supabase) adapter set.',
  ),
);
