/// Calculates the estimated One-Rep Max (1RM) using the Epley formula:
/// 1RM = weight * (1 + reps / 30.0)
double calculateOneRepMax({required double weight, required int reps}) {
  if (reps <= 0) return 0.0;
  if (reps == 1) return weight;
  return weight * (1.0 + reps / 30.0);
}
