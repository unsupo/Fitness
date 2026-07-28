import 'package:camera/camera.dart';

import '../../domain/entities/recognized_meal.dart';
import '../../domain/repositories/food_recognition_repository.dart';
import '../data_sources/stub_recognition_data_source.dart';

/// Stubbed [FoodRecognitionRepository]. Builds the full capture -> result ->
/// save UI flow for real, but the "recognition" itself is mocked.
///
/// TODO(vision-api): replace with a real multimodal vision call (e.g.
/// Claude/GPT vision) — see docs/FUTURE_IMPROVEMENTS.md.
class StubFoodRecognitionRepository implements FoodRecognitionRepository {
  StubFoodRecognitionRepository({StubRecognitionDataSource? dataSource})
    : _dataSource = dataSource ?? StubRecognitionDataSource();

  final StubRecognitionDataSource _dataSource;

  @override
  Future<RecognizedMeal> recognize(XFile image) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _dataSource.next();
  }
}
