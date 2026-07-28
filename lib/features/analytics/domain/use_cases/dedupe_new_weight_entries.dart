import '../entities/weight_entry.dart';

/// Filters [parsed] CSV rows down to the ones not already in [existing] —
/// matched by exact `loggedAt` instant, ignoring weight. Smart-scale exports
/// are cumulative (each new export re-includes every prior reading), so
/// without this a re-import — or an import of a later, overlapping export —
/// would insert duplicate `weight_log` rows.
List<({DateTime loggedAt, double weightKg})> dedupeNewWeightEntries(
  List<({DateTime loggedAt, double weightKg})> parsed,
  List<WeightEntry> existing,
) {
  final existingTimestamps = existing.map((e) => e.loggedAt).toSet();
  return [
    for (final entry in parsed)
      if (!existingTimestamps.contains(entry.loggedAt)) entry,
  ];
}
