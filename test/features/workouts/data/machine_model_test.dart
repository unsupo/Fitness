import 'package:arndt_fitness/features/workouts/data/models/machine_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromJson maps a machines row, casting aliases text[] elements to String', () {
    final json = {
      'id': 7,
      'name': 'Chest Press',
      'aliases': ['Pec Deck', 'Chest Fly Machine'],
      'muscle_group': 'chest',
    };

    final machine = MachineModel.fromJson(json).toEntity();

    expect(machine.id, 7);
    expect(machine.name, 'Chest Press');
    expect(machine.aliases, ['Pec Deck', 'Chest Fly Machine']);
    expect(machine.muscleGroup, 'chest');
  });

  test('fromJson tolerates null aliases and null muscle_group', () {
    final json = {
      'id': 8,
      'name': 'Mystery Machine',
      'aliases': null,
      'muscle_group': null,
    };

    final machine = MachineModel.fromJson(json).toEntity();

    expect(machine.aliases, isEmpty);
    expect(machine.muscleGroup, isNull);
  });
}
