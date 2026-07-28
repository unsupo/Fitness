import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/rep_counter.dart';

void main() {
  group('RepCounter', () {
    test('starts at zero reps and zero sets', () {
      final counter = RepCounter(targetReps: 10);
      expect(counter.reps, 0);
      expect(counter.completedSets, 0);
    });

    test('increments reps', () {
      final counter = RepCounter(targetReps: 10);
      counter.incrementRep();
      counter.incrementRep();
      expect(counter.reps, 2);
    });

    test('rolls over into a completed set at the target', () {
      final counter = RepCounter(targetReps: 3);
      counter.incrementRep();
      counter.incrementRep();
      counter.incrementRep();
      expect(counter.reps, 0);
      expect(counter.completedSets, 1);
    });

    test('reset clears reps and completed sets', () {
      final counter = RepCounter(targetReps: 3)
        ..incrementRep()
        ..incrementRep()
        ..incrementRep()
        ..incrementRep();
      counter.reset();
      expect(counter.reps, 0);
      expect(counter.completedSets, 0);
    });
  });
}
