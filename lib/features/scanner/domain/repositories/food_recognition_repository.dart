// XFile lives in `cross_file`, but that's only a transitive dependency here
// (via `camera`, which is a direct pubspec dependency and re-exports it) —
// import through `camera` so the dependency graph stays explicit.
import 'package:camera/camera.dart';

import '../entities/recognized_meal.dart';

/// Adapter seam for AI food-photo recognition. Stubbed today (see
/// data/repositories/stub_food_recognition_repository.dart); swappable for a
/// real multimodal vision call later without touching scanner UI/domain.
abstract class FoodRecognitionRepository {
  Future<RecognizedMeal> recognize(XFile image);
}
