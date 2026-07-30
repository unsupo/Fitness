import '../entities/diary_entry.dart';
import '../../../../core/entities/logged_quantity.dart';
import 'logged_quantity_converter.dart';

/// Returns a copy of [entry] with [newQuantity] and calories/macros scaled.
DiaryEntry rescaleDiaryEntry(DiaryEntry entry, {required LoggedQuantity newQuantity}) {
  if (newQuantity.amount <= 0) {
    throw ArgumentError.value(newQuantity.amount, 'newQuantity.amount', 'must be positive');
  }

  final oldMultiplier = LoggedQuantityConverter.toServingMultiplier(
    entry.quantity,
    servingSize: entry.servingSize,
    servingUnit: entry.servingUnit,
  );

  final newMultiplier = LoggedQuantityConverter.toServingMultiplier(
    newQuantity,
    servingSize: entry.servingSize,
    servingUnit: entry.servingUnit,
  );

  final ratio = oldMultiplier == 0.0 ? 1.0 : newMultiplier / oldMultiplier;

  return DiaryEntry(
    id: entry.id,
    loggedAt: entry.loggedAt,
    mealType: entry.mealType,
    foodName: entry.foodName,
    foodId: entry.foodId,
    recipeId: entry.recipeId,
    quantity: newQuantity,
    calories: entry.calories * ratio,
    proteinG: entry.proteinG * ratio,
    carbsG: entry.carbsG * ratio,
    fatG: entry.fatG * ratio,
    servingSize: entry.servingSize,
    servingUnit: entry.servingUnit,
    imageUrl: entry.imageUrl,
  );
}
