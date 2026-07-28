/// Pure logic for tracking reps within a set, and completed sets.
///
/// Kept separate from widgets so it can be unit tested without pumping
/// a widget tree.
class RepCounter {
  RepCounter({this.targetReps = 10});

  final int targetReps;

  int reps = 0;
  int completedSets = 0;

  bool get setComplete => reps >= targetReps;

  void incrementRep() {
    reps++;
    if (setComplete) {
      completedSets++;
      reps = 0;
    }
  }

  void reset() {
    reps = 0;
    completedSets = 0;
  }
}
