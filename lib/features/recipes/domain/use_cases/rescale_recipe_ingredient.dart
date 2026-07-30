import '../../../../core/entities/logged_quantity.dart';
import '../../../diary/domain/use_cases/logged_quantity_converter.dart';
import '../entities/recipe_ingredient.dart';

/// Returns a copy of [ingredient] with [newQuantity] and calories/macros
/// scaled proportionally — the recipe-ingredient equivalent of
/// `rescaleDiaryEntry`, used when editing an ingredient's quantity inline
/// (e.g. from the recipe accordion on Home) without re-deriving its
/// per-unit food macros from scratch.
RecipeIngredient rescaleRecipeIngredient(
  RecipeIngredient ingredient, {
  required LoggedQuantity newQuantity,
}) {
  if (newQuantity.amount <= 0) {
    throw ArgumentError.value(newQuantity.amount, 'newQuantity.amount', 'must be positive');
  }

  final oldMultiplier = LoggedQuantityConverter.toServingMultiplier(
    ingredient.quantity,
    servingSize: ingredient.servingSize,
    servingUnit: ingredient.servingUnit,
  );

  final newMultiplier = LoggedQuantityConverter.toServingMultiplier(
    newQuantity,
    servingSize: ingredient.servingSize,
    servingUnit: ingredient.servingUnit,
  );

  final ratio = oldMultiplier == 0.0 ? 1.0 : newMultiplier / oldMultiplier;

  return RecipeIngredient(
    foodId: ingredient.foodId,
    foodName: ingredient.foodName,
    quantity: newQuantity,
    calories: ingredient.calories * ratio,
    proteinG: ingredient.proteinG * ratio,
    carbsG: ingredient.carbsG * ratio,
    fatG: ingredient.fatG * ratio,
    servingSize: ingredient.servingSize,
    servingUnit: ingredient.servingUnit,
  );
}
