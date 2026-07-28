import 'package:arndt_fitness/features/workouts/domain/entities/machine.dart';

/// Maps a `machines` row to a [Machine].
class MachineModel {
  const MachineModel({
    required this.id,
    required this.name,
    required this.aliases,
    this.muscleGroup,
  });

  final int id;
  final String name;
  final List<String> aliases;
  final String? muscleGroup;

  factory MachineModel.fromJson(Map<String, dynamic> json) {
    // `aliases` is a Postgres text[] — arrives as a Dart List<dynamic>; cast
    // each element to String. Tolerate a null column (no aliases set).
    final rawAliases = json['aliases'] as List?;

    return MachineModel(
      id: json['id'] as int,
      name: json['name'] as String,
      aliases: rawAliases == null
          ? const []
          : rawAliases.map((e) => e as String).toList(),
      muscleGroup: json['muscle_group'] as String?,
    );
  }

  Machine toEntity() => Machine(
    id: id,
    name: name,
    aliases: aliases,
    muscleGroup: muscleGroup,
  );
}
