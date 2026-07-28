import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/use_cases/parse_weight_export_csv.dart';

void main() {
  group('parseWeightExportCsv', () {
    // Real export format from the user's smart scale (columns beyond
    // Time/Weight are intentionally not stored anywhere in this app).
    const csv =
        'Time,Weight,BMI,Body Fat,Fat-Free Body Weight,Subcutaneous Fat,'
        'Visceral Fat,Body Water,Muscle Mass,Skeletal Muscles,Bone Mass,'
        'Protein,BMR,Metabolic Age\n'
        '7/12/2026 9:47 PM,248.2lb,30.2 ,26.5 %,182.5lb,22.8%,12,53.0%,'
        '173.1lb,47.4 %,9.1lb,16.7 %,2326kcal,38\n'
        '7/12/2026 9:48 PM,248.2lb,30.2 ,26.5 %,182.5lb,22.8%,12,53.0%,'
        '173.1lb,47.4 %,9.1lb,16.7 %,2326kcal,38\n'
        '7/13/2026 11:55 PM,248.2lb,30.2 ,26.5 %,182.5lb,22.8%,12,53.0%,'
        '173.1lb,47.4 %,9.1lb,16.7 %,2326kcal,38\n'
        '7/13/2026 11:55 PM,248.2lb,30.2 ,26.5 %,182.5lb,22.8%,12,53.0%,'
        '173.1lb,47.4 %,9.1lb,16.7 %,2326kcal,38\n'
        '7/14/2026 10:03 PM,249.6lb,30.4 ,26.8 %,182.7lb,23.0%,13,52.8%,'
        '173.3lb,47.2 %,9.1lb,16.6 %,2334kcal,38\n'
        '7/14/2026 10:03 PM,249.6lb,30.4 ,26.8 %,182.7lb,23.0%,13,52.8%,'
        '173.3lb,47.2 %,9.1lb,16.6 %,2334kcal,38\n'
        '7/15/2026 10:49 PM,249.1lb,30.3 ,26.6 %,182.7lb,22.9%,13,52.9%,'
        '173.4lb,47.3 %,9.1lb,16.7 %,2332kcal,38\n'
        '7/19/2026 9:40 PM,250.9lb,30.6 ,27.1 %,182.9lb,23.3%,13,52.5%,'
        '173.5lb,47.0 %,9.1lb,16.6 %,2342kcal,38\n';

    test('parses every data row, converting lb to kg', () {
      final entries = parseWeightExportCsv(csv);

      expect(entries.length, 8);
      expect(entries.first.loggedAt, DateTime(2026, 7, 12, 21, 47));
      expect(entries.first.weightKg, closeTo(112.583, 0.01)); // 248.2 lb
      expect(entries.last.loggedAt, DateTime(2026, 7, 19, 21, 40));
      expect(entries.last.weightKg, closeTo(113.806, 0.01)); // 250.9 lb
    });

    test('keeps exact-duplicate timestamp rows as-is (no dedup)', () {
      final entries = parseWeightExportCsv(csv);

      final duplicateTimestamp = DateTime(2026, 7, 13, 23, 55);
      final matches = entries.where((e) => e.loggedAt == duplicateTimestamp);
      expect(matches.length, 2);
    });

    test('returns an empty list for an empty/header-only input', () {
      expect(parseWeightExportCsv(''), isEmpty);
      expect(parseWeightExportCsv('Time,Weight\n'), isEmpty);
    });

    test('skips malformed rows instead of throwing', () {
      const badCsv =
          'Time,Weight\n'
          'not-a-date,248.2lb\n'
          '7/12/2026 9:47 PM,not-a-weight\n'
          '7/12/2026 9:47 PM,248.2lb\n';

      final entries = parseWeightExportCsv(badCsv);

      expect(entries.length, 1);
      expect(entries.single.loggedAt, DateTime(2026, 7, 12, 21, 47));
    });

    test('finds Time/Weight columns regardless of position', () {
      const reordered = 'BMI,Weight,Time\n30.2,248.2lb,7/12/2026 9:47 PM\n';

      final entries = parseWeightExportCsv(reordered);

      expect(entries.single.loggedAt, DateTime(2026, 7, 12, 21, 47));
      expect(entries.single.weightKg, closeTo(112.583, 0.01));
    });
  });
}
