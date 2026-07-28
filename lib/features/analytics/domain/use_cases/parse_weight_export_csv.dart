import 'package:intl/intl.dart';

import 'weight_unit.dart';

/// Parses a smart-scale CSV export (e.g. Renpho/Etekcity-style: a header
/// row followed by `Time,Weight,BMI,Body Fat,...` rows, weight always in
/// `lb` regardless of the app's own unit-system preference) into
/// `(loggedAt, weightKg)` pairs. Only the `Time`/`Weight` columns are read —
/// every other column (BMI, body fat, etc.) isn't stored anywhere in this
/// app's schema. Looks up column positions from the header rather than
/// assuming a fixed order, since real exports vary. Malformed rows are
/// skipped rather than aborting the whole import.
List<({DateTime loggedAt, double weightKg})> parseWeightExportCsv(
  String csvContent,
) {
  final lines = csvContent
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toList();
  if (lines.length < 2) return [];

  final header = lines.first.split(',');
  final timeIndex = header.indexOf('Time');
  final weightIndex = header.indexOf('Weight');
  if (timeIndex == -1 || weightIndex == -1) return [];

  final dateFormat = DateFormat('M/d/yyyy h:mm a');
  final results = <({DateTime loggedAt, double weightKg})>[];

  for (final line in lines.skip(1)) {
    final columns = line.split(',');
    if (columns.length <= timeIndex || columns.length <= weightIndex) continue;

    DateTime loggedAt;
    try {
      loggedAt = dateFormat.parseStrict(columns[timeIndex].trim());
    } on FormatException {
      continue;
    }

    final weightLb = double.tryParse(
      columns[weightIndex].trim().replaceAll(RegExp('[^0-9.]'), ''),
    );
    if (weightLb == null) continue;

    results.add((loggedAt: loggedAt, weightKg: lbToKg(weightLb)));
  }

  return results;
}
