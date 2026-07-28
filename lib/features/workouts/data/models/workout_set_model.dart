import 'package:arndt_fitness/core/network/supabase_json.dart'
    show parseSupabaseNum, parseSupabaseTimestamp;
import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';

double? _parseNullableNum(Object? value) =>
    value == null ? null : parseSupabaseNum(value);

/// Maps a `workout_sets` row **joined with `machines(name)`**
/// (`.select('*, machines(name)')`) to a [WorkoutSet]. Covers both strength
/// fields (`weight`/`reps`) and cardio fields (`incline`/`speed`/
/// `duration_minutes`) — whichever group is populated depends on the
/// machine.
class WorkoutSetModel {
  const WorkoutSetModel({
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

  factory WorkoutSetModel.fromJson(Map<String, dynamic> json) {
    final machine = json['machines'] as Map<String, dynamic>;

    return WorkoutSetModel(
      id: json['id'] as int,
      loggedAt: parseSupabaseTimestamp(json['logged_at'] as String),
      machineId: json['machine_id'] as int,
      machineName: machine['name'] as String,
      sessionId: json['session_id'] as int,
      setNumber: json['set_number'] as int,
      machineOrder: json['machine_order'] as int?,
      // Numeric columns don't consistently arrive as String — always go
      // through parseSupabaseNum, never `double.parse(... as String)`.
      weight: _parseNullableNum(json['weight']),
      reps: json['reps'] as int?,
      unit: json['unit'] as String? ?? 'lb',
      incline: _parseNullableNum(json['incline']),
      speed: _parseNullableNum(json['speed']),
      durationMinutes: _parseNullableNum(json['duration_minutes']),
      seatPosition: json['seat_position'] as String?,
      restSeconds: json['rest_seconds'] as int?,
      notes: json['notes'] as String?,
    );
  }

  /// Builds a model from a domain entity — used before writes (`logSet`/
  /// `updateSet`), where there's no `machines` join to parse.
  factory WorkoutSetModel.fromEntity(WorkoutSet set) => WorkoutSetModel(
    id: set.id,
    loggedAt: set.loggedAt,
    machineId: set.machineId,
    machineName: set.machineName,
    sessionId: set.sessionId,
    setNumber: set.setNumber,
    machineOrder: set.machineOrder,
    weight: set.weight,
    reps: set.reps,
    unit: set.unit,
    incline: set.incline,
    speed: set.speed,
    durationMinutes: set.durationMinutes,
    seatPosition: set.seatPosition,
    restSeconds: set.restSeconds,
    notes: set.notes,
  );

  WorkoutSet toEntity() => WorkoutSet(
    id: id,
    loggedAt: loggedAt,
    machineId: machineId,
    machineName: machineName,
    sessionId: sessionId,
    setNumber: setNumber,
    machineOrder: machineOrder,
    weight: weight,
    reps: reps,
    unit: unit,
    incline: incline,
    speed: speed,
    durationMinutes: durationMinutes,
    seatPosition: seatPosition,
    restSeconds: restSeconds,
    notes: notes,
  );

  /// Raw columns for `logSet`/`updateSet` writes — no `machines` join on
  /// write, just the underlying `workout_sets` columns. `id` is
  /// deliberately omitted: ignored on insert, and update targets the row by
  /// id separately (`.eq('id', id)`), not via the payload.
  Map<String, dynamic> toInsertJson() => {
    'logged_at': loggedAt.toUtc().toIso8601String(),
    'machine_id': machineId,
    'session_id': sessionId,
    'set_number': setNumber,
    'machine_order': machineOrder,
    'weight': weight,
    'reps': reps,
    'unit': unit,
    'incline': incline,
    'speed': speed,
    'duration_minutes': durationMinutes,
    'seat_position': seatPosition,
    'rest_seconds': restSeconds,
    'notes': notes,
  };
}
