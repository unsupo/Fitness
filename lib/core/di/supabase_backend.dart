import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/analytics/data/data_sources/analytics_remote_data_source.dart';
import '../../features/analytics/data/repositories/supabase_analytics_repository.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/diary/data/repositories/supabase_diary_repository.dart';
import '../../features/diary/domain/repositories/diary_repository.dart';
import '../../features/recipes/data/repositories/supabase_recipe_repository.dart';
import '../../features/recipes/domain/repositories/recipe_repository.dart';
import '../../features/scanner/data/repositories/open_food_facts_repository.dart';
import '../../features/scanner/data/repositories/stub_food_recognition_repository.dart';
import '../../features/scanner/data/repositories/supabase_food_logging_repository.dart';
import '../../features/scanner/domain/repositories/barcode_lookup_repository.dart';
import '../../features/scanner/domain/repositories/food_logging_repository.dart';
import '../../features/scanner/domain/repositories/food_recognition_repository.dart';
import '../../features/workouts/data/repositories/supabase_workout_repository.dart';
import '../../features/workouts/domain/repositories/workout_repository.dart';
import 'backend.dart';

/// The app's default [Backend]: Supabase for persistence, OpenFoodFacts for
/// barcode lookups, and a stubbed vision call for AI food recognition (see
/// docs/FUTURE_IMPROVEMENTS.md). This is the **only** file in the app that
/// imports `supabase_flutter` and references concrete `SupabaseX` adapter
/// classes — every feature reaches these through the abstract [Backend]
/// interface instead.
class SupabaseBackend implements Backend {
  SupabaseBackend(this._client);

  final SupabaseClient _client;

  @override
  DiaryRepository createDiaryRepository() => SupabaseDiaryRepository(_client);

  @override
  RecipeRepository createRecipeRepository() =>
      SupabaseRecipeRepository(_client);

  @override
  AnalyticsRepository createAnalyticsRepository() =>
      SupabaseAnalyticsRepository(AnalyticsRemoteDataSource(_client));

  @override
  BarcodeLookupRepository createBarcodeLookupRepository() =>
      OpenFoodFactsBarcodeRepository();

  @override
  FoodRecognitionRepository createFoodRecognitionRepository() =>
      StubFoodRecognitionRepository();

  @override
  FoodLoggingRepository createFoodLoggingRepository() =>
      SupabaseFoodLoggingRepository(client: _client);

  @override
  WorkoutRepository createWorkoutRepository() =>
      SupabaseWorkoutRepository(_client);
}
