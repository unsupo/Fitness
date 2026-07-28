import 'package:arndt_fitness/features/workouts/domain/entities/workout_session.dart';

/// Maps a `workout_sessions` row to a [WorkoutSession].
class WorkoutSessionModel {
  const WorkoutSessionModel({required this.id, required this.sessionDate});

  final int id;
  final DateTime sessionDate;

  factory WorkoutSessionModel.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionModel(
      id: json['id'] as int,
      // `session_date` is a Postgres `date` (no time component) — parses to
      // midnight UTC, which is fine to treat as date-only.
      sessionDate: DateTime.parse(json['session_date'] as String),
    );
  }

  WorkoutSession toEntity() =>
      WorkoutSession(id: id, sessionDate: sessionDate);
}
