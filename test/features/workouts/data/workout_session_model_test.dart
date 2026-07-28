import 'package:arndt_fitness/features/workouts/data/models/workout_session_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson maps a workout_sessions row, parsing session_date as date-only', () {
    final json = {'id': 4, 'session_date': '2026-07-20', 'created_at': '2026-07-20T14:03:00Z'};

    final session = WorkoutSessionModel.fromJson(json).toEntity();

    expect(session.id, 4);
    expect(session.sessionDate, DateTime.parse('2026-07-20'));
  });
}
