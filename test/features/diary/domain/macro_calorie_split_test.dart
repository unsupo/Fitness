import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/diary/domain/use_cases/macro_calorie_split.dart';

void main() {
  group('macroCalorieSplitFromGrams / macroGramsFromCalorieSplit', () {
    test('converts grams to kcal using 4/4/9 kcal-per-gram', () {
      final split = macroCalorieSplitFromGrams(
        proteinG: 150,
        carbsG: 200,
        fatG: 65,
      );

      expect(split.proteinKcal, 600);
      expect(split.carbsKcal, 800);
      expect(split.fatKcal, 585);
      expect(split.totalKcal, 1985);
    });

    test('round-trips back to the same grams', () {
      final split = macroCalorieSplitFromGrams(
        proteinG: 150,
        carbsG: 200,
        fatG: 65,
      );
      final grams = macroGramsFromCalorieSplit(split);

      expect(grams.proteinG, 150);
      expect(grams.carbsG, 200);
      expect(grams.fatG, 65);
    });

    test('fractions are each slice\'s share of the total, not equal thirds', () {
      // 600/1985, 800/1985, 585/1985 — this is exactly the "40% protein
      // dominant, near-even carbs, smaller fat slice" split a pie chart
      // needs to render correctly.
      final split = macroCalorieSplitFromGrams(
        proteinG: 150,
        carbsG: 200,
        fatG: 65,
      );

      expect(split.proteinFraction, closeTo(0.3023, 0.001));
      expect(split.carbsFraction, closeTo(0.4030, 0.001));
      expect(split.fatFraction, closeTo(0.2947, 0.001));
      expect(
        split.proteinFraction + split.carbsFraction + split.fatFraction,
        closeTo(1.0, 0.0001),
      );
    });

    test('fractions are all zero for a zero-calorie split (no divide-by-zero)', () {
      const split = MacroCalorieSplit(proteinKcal: 0, carbsKcal: 0, fatKcal: 0);

      expect(split.proteinFraction, 0);
      expect(split.carbsFraction, 0);
      expect(split.fatFraction, 0);
    });
  });

  group('adjustMacroSliceBoundary', () {
    test(
      'proteinCarbs: positive delta moves kcal from carbs to protein, '
      'total and fat both unchanged',
      () {
        const current = MacroCalorieSplit(
          proteinKcal: 600,
          carbsKcal: 800,
          fatKcal: 585,
        );

        final adjusted = adjustMacroSliceBoundary(
          current,
          MacroSliceBoundary.proteinCarbs,
          100,
        );

        expect(adjusted.proteinKcal, 700);
        expect(adjusted.carbsKcal, 700);
        expect(adjusted.fatKcal, 585);
        expect(adjusted.totalKcal, current.totalKcal);
      },
    );

    test('proteinCarbs: negative delta moves kcal from protein to carbs', () {
      const current = MacroCalorieSplit(
        proteinKcal: 600,
        carbsKcal: 800,
        fatKcal: 585,
      );

      final adjusted = adjustMacroSliceBoundary(
        current,
        MacroSliceBoundary.proteinCarbs,
        -100,
      );

      expect(adjusted.proteinKcal, 500);
      expect(adjusted.carbsKcal, 900);
      expect(adjusted.fatKcal, 585);
    });

    test('carbsFat: positive delta moves kcal from fat to carbs', () {
      const current = MacroCalorieSplit(
        proteinKcal: 600,
        carbsKcal: 800,
        fatKcal: 585,
      );

      final adjusted = adjustMacroSliceBoundary(
        current,
        MacroSliceBoundary.carbsFat,
        85,
      );

      expect(adjusted.proteinKcal, 600);
      expect(adjusted.carbsKcal, 885);
      expect(adjusted.fatKcal, 500);
    });

    test('fatProtein: positive delta moves kcal from protein to fat', () {
      const current = MacroCalorieSplit(
        proteinKcal: 600,
        carbsKcal: 800,
        fatKcal: 585,
      );

      final adjusted = adjustMacroSliceBoundary(
        current,
        MacroSliceBoundary.fatProtein,
        100,
      );

      expect(adjusted.proteinKcal, 500);
      expect(adjusted.carbsKcal, 800);
      expect(adjusted.fatKcal, 685);
    });

    test('clamps so the shrinking slice never goes negative', () {
      const current = MacroCalorieSplit(
        proteinKcal: 600,
        carbsKcal: 800,
        fatKcal: 585,
      );

      // Trying to move 10000 kcal from carbs to protein — carbs can only
      // give up its own 800 kcal.
      final adjusted = adjustMacroSliceBoundary(
        current,
        MacroSliceBoundary.proteinCarbs,
        10000,
      );

      expect(adjusted.carbsKcal, 0);
      expect(adjusted.proteinKcal, 1400);
      expect(adjusted.totalKcal, current.totalKcal);
    });

    test('clamps symmetrically for a too-large negative delta', () {
      const current = MacroCalorieSplit(
        proteinKcal: 600,
        carbsKcal: 800,
        fatKcal: 585,
      );

      final adjusted = adjustMacroSliceBoundary(
        current,
        MacroSliceBoundary.proteinCarbs,
        -10000,
      );

      expect(adjusted.proteinKcal, 0);
      expect(adjusted.carbsKcal, 1400);
      expect(adjusted.totalKcal, current.totalKcal);
    });
  });
}
