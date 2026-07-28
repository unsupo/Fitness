/// An exercise machine/movement (`machines` row) — strength or cardio.
/// `muscleGroup` is free text from the DB (e.g. 'chest', 'legs', 'cardio'),
/// not a closed enum.
class Machine {
  const Machine({
    required this.id,
    required this.name,
    this.aliases = const [],
    this.muscleGroup,
  });

  final int id;
  final String name;
  final List<String> aliases;
  final String? muscleGroup;
}
