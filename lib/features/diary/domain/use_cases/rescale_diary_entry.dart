import '../entities/diary_entry.dart';

/// Returns a copy of [entry] with [newQuantity] and calories/macros scaled
/// by the same ratio (`newQuantity / entry.quantity`).
///
/// Works uniformly for both food-based and recipe-based entries: `food_log`
/// always stores the already-computed total for the logged quantity (not a
/// per-unit value), so scaling by ratio is correct without needing to know
/// which food or recipe underlies the entry.
DiaryEntry rescaleDiaryEntry(DiaryEntry entry, {required double newQuantity}) {
  if (newQuantity <= 0) {
    throw ArgumentError.value(newQuantity, 'newQuantity', 'must be positive');
  }

  final ratio = newQuantity / entry.quantity;

  return DiaryEntry(
    id: entry.id,
    loggedAt: entry.loggedAt,
    mealType: entry.mealType,
    foodName: entry.foodName,
    foodId: entry.foodId,
    quantity: newQuantity,
    calories: entry.calories * ratio,
    proteinG: entry.proteinG * ratio,
    carbsG: entry.carbsG * ratio,
    fatG: entry.fatG * ratio,
  );
}
