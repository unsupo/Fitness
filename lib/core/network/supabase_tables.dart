/// Table name constants for the shared Supabase schema. Every feature's data
/// layer reads/writes through these instead of hardcoding table name strings.
abstract final class SupabaseTables {
  static const foods = 'foods';
  static const foodLog = 'food_log';
  static const recipes = 'recipes';
  static const recipeIngredients = 'recipe_ingredients';
  static const dailyGoals = 'daily_goals';
  static const weightLog = 'weight_log';
  static const machines = 'machines';
  static const workoutSessions = 'workout_sessions';
  static const workoutSets = 'workout_sets';
}

/// Valid values for `food_log.meal_type`.
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get label => switch (this) {
    MealType.breakfast => 'Breakfast',
    MealType.lunch => 'Lunch',
    MealType.dinner => 'Dinner',
    MealType.snack => 'Snacks',
  };

  static MealType fromString(String value) => MealType.values.firstWhere(
    (e) => e.name == value,
    orElse: () => MealType.snack,
  );
}
