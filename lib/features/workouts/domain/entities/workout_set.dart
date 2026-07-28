/// One logged set (`workout_sets` row), joined with its machine's name.
/// Covers both strength machines (`weight`/`reps`) and cardio machines
/// (`incline`/`speed`/`durationMinutes`) — whichever group applies is
/// non-null depending on the machine.
class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.loggedAt,
    required this.machineId,
    required this.machineName,
    required this.sessionId,
    required this.setNumber,
    this.machineOrder,
    this.weight,
    this.reps,
    this.unit = 'lb',
    this.incline,
    this.speed,
    this.durationMinutes,
    this.seatPosition,
    this.restSeconds,
    this.notes,
  });

  final int id;
  final DateTime loggedAt;
  final int machineId;
  final String machineName;
  final int sessionId;
  final int setNumber;
  final int? machineOrder;

  final double? weight;
  final int? reps;
  final String unit;

  final double? incline;
  final double? speed;
  final double? durationMinutes;
  final String? seatPosition;
  final int? restSeconds;
  final String? notes;
}
