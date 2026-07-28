import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/use_cases/dedupe_new_weight_entries.dart';
import '../../domain/use_cases/parse_weight_export_csv.dart';
import '../controllers/analytics_providers.dart';

/// Entry point wired to the UI button: picks a `.csv` file from device
/// storage, reads it, and delegates to [importWeightCsvContent]. The file
/// picker itself is a thin platform wrapper, untested directly (same
/// convention as this codebase's other plugin calls) — the interesting
/// logic (parse, confirm, import) lives in [importWeightCsvContent] so it
/// can be exercised in a widget test without a real file dialog.
Future<void> importWeightCsv(BuildContext context, WidgetRef ref) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['csv'],
  );
  final path = result?.files.single.path;
  if (path == null) return; // user cancelled the picker

  final content = await File(path).readAsString();
  if (!context.mounted) return;
  await importWeightCsvContent(context, ref, content);
}

/// Parses [csvContent] (see `parseWeightExportCsv`), drops any reading
/// already present in `weight_log` (see `dedupeNewWeightEntries` — smart-
/// scale exports are cumulative, so re-importing the same or an overlapping
/// later export must not create duplicate rows), confirms with the user
/// (reading count + date range), then bulk-imports via
/// [AnalyticsRepository.importWeightEntries] and invalidates
/// [weightHistoryProvider] so the Weight history and goal-projection charts
/// both refresh immediately.
Future<void> importWeightCsvContent(
  BuildContext context,
  WidgetRef ref,
  String csvContent,
) async {
  final entries = parseWeightExportCsv(csvContent);
  if (entries.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No readings found in that file.')),
    );
    return;
  }

  final repository = ref.read(analyticsRepositoryProvider);
  final history = await repository.getWeightHistory();
  final newEntries = dedupeNewWeightEntries(entries, history);
  final skipped = entries.length - newEntries.length;

  if (newEntries.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All readings in that file are already imported.'),
        ),
      );
    }
    return;
  }
  if (!context.mounted) return;

  final sorted = [...newEntries]..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  final dateFormat = DateFormat('MMM d, yyyy');
  final rangeText =
      'from ${dateFormat.format(sorted.first.loggedAt)} to '
      '${dateFormat.format(sorted.last.loggedAt)}';
  final dialogMessage = skipped == 0
      ? 'Found ${newEntries.length} readings $rangeText. Import them?'
      : 'Found ${newEntries.length} new readings $rangeText '
          '($skipped already imported, skipped). Import them?';

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Import weigh-ins?'),
      content: Text(dialogMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Import'),
        ),
      ],
    ),
  );
  if (confirmed != true) return;

  final goalType = history.isEmpty ? 'maintain' : history.last.goalType;
  await repository.importWeightEntries(newEntries, goalType: goalType);
  ref.invalidate(weightHistoryProvider);

  if (context.mounted) {
    final message = skipped == 0
        ? 'Imported ${newEntries.length} weigh-ins.'
        : 'Imported ${newEntries.length} weigh-ins '
            '($skipped already imported, skipped).';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
