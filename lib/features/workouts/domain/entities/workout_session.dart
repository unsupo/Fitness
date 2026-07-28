/// A logged workout session (`workout_sessions` row). Date-only — no name
/// or template concept in the schema; sessions are identified by date and
/// summarized from the sets logged within them.
class WorkoutSession {
  const WorkoutSession({required this.id, required this.sessionDate});

  final int id;
  final DateTime sessionDate;
}
