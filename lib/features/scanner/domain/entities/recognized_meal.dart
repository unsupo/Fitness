/// The (stubbed) result of AI food-photo recognition. Pure Dart — no
/// Flutter/Supabase imports.
class RecognizedMeal {
  const RecognizedMeal({
    required this.name,
    required this.estimatedCalories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.servings,
  });

  final String name;
  final double estimatedCalories;
  final double proteinG;
  final double carbsG;
  final double fatG;

  /// Adjustable by the user before saving.
  final double servings;

  RecognizedMeal copyWith({double? servings}) {
    return RecognizedMeal(
      name: name,
      estimatedCalories: estimatedCalories,
      proteinG: proteinG,
      carbsG: carbsG,
      fatG: fatG,
      servings: servings ?? this.servings,
    );
  }
}
