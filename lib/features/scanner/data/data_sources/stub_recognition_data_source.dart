import '../../domain/entities/recognized_meal.dart';

/// Canned, plausible recognition results cycled through in order. Stands in
/// for a real vision model call — see
/// `data/repositories/stub_food_recognition_repository.dart`.
class StubRecognitionDataSource {
  int _index = 0;

  static const _cannedMeals = [
    RecognizedMeal(
      name: 'Arugula Salad with Grilled Chicken',
      estimatedCalories: 380,
      proteinG: 38,
      carbsG: 12,
      fatG: 22,
      servings: 1,
    ),
    RecognizedMeal(
      name: 'Grilled Salmon with Quinoa',
      estimatedCalories: 460,
      proteinG: 34,
      carbsG: 40,
      fatG: 18,
      servings: 1,
    ),
    RecognizedMeal(
      name: 'Turkey Avocado Wrap',
      estimatedCalories: 410,
      proteinG: 28,
      carbsG: 36,
      fatG: 20,
      servings: 1,
    ),
  ];

  RecognizedMeal next() {
    final meal = _cannedMeals[_index % _cannedMeals.length];
    _index++;
    return meal;
  }
}
