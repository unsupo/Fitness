import 'package:arndt_fitness/features/workouts/data/models/workout_set_model.dart';
import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'fromJson maps a workout_sets row joined with machines(name), '
    'parsing numeric columns that arrive as JSON strings (the known gotcha)',
    () {
      final json = {
        'id': 101,
        'logged_at': '2026-07-20T14:05:00Z',
        'machine_id': 7,
        'session_id': 4,
        'set_number': 1,
        'machine_order': 0,
        'weight': '135', // numeric arriving as a JSON string
        'reps': 8,
        'unit': 'lb',
        'incline': null,
        'speed': null,
        'duration_minutes': null,
        'seat_position': null,
        'rest_seconds': 90,
        'notes': null,
        'machines': {'name': 'Chest Press'},
      };

      final set = WorkoutSetModel.fromJson(json).toEntity();

      expect(set.id, 101);
      expect(set.loggedAt, DateTime.parse('2026-07-20T14:05:00Z'));
      expect(set.machineId, 7);
      expect(set.machineName, 'Chest Press');
      expect(set.sessionId, 4);
      expect(set.setNumber, 1);
      expect(set.machineOrder, 0);
      expect(set.weight, 135.0);
      expect(set.reps, 8);
      expect(set.unit, 'lb');
      expect(set.incline, isNull);
      expect(set.speed, isNull);
      expect(set.durationMinutes, isNull);
      expect(set.restSeconds, 90);
    },
  );

  test(
    'fromJson parses numeric cardio columns arriving as native num (not a String)',
    () {
      final json = {
        'id': 102,
        'logged_at': '2026-07-20T14:10:00Z',
        'machine_id': 12,
        'session_id': 4,
        'set_number': 1,
        'machine_order': 1,
        'weight': null,
        'reps': null,
        'unit': 'lb',
        'incline': 2.5, // native num, not a string
        'speed': 5.2,
        'duration_minutes': 20,
        'seat_position': null,
        'rest_seconds': null,
        'notes': 'felt easy',
        'machines': {'name': 'Treadmill'},
      };

      final set = WorkoutSetModel.fromJson(json).toEntity();

      expect(set.machineName, 'Treadmill');
      expect(set.weight, isNull);
      expect(set.incline, 2.5);
      expect(set.speed, 5.2);
      expect(set.durationMinutes, 20.0);
      expect(set.notes, 'felt easy');
    },
  );

  test('toInsertJson emits raw columns (no machines join) for write operations', () {
    final entity = WorkoutSet(
      id: 999, // ignored on insert, but present on the entity
      loggedAt: DateTime.parse('2026-07-20T14:05:00Z'),
      machineId: 7,
      machineName: 'Chest Press',
      sessionId: 4,
      setNumber: 2,
      machineOrder: 0,
      weight: 140,
      reps: 6,
      unit: 'lb',
      restSeconds: 90,
    );

    final model = WorkoutSetModel.fromEntity(entity);
    final json = model.toInsertJson();

    expect(json.containsKey('machines'), isFalse);
    expect(json['machine_id'], 7);
    expect(json['session_id'], 4);
    expect(json['set_number'], 2);
    expect(json['weight'], 140);
    expect(json['reps'], 6);
    expect(json['unit'], 'lb');
    expect(json['rest_seconds'], 90);
  });
}
