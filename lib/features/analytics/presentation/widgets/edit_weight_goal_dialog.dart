import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/use_cases/estimate_tdee.dart';
import '../../domain/use_cases/height_unit.dart';
import '../../domain/use_cases/weight_unit.dart';
import '../controllers/analytics_providers.dart';

const _activityLabels = {
  'sedentary': 'Sedentary (little/no exercise)',
  'light': 'Light (1-3 days/week)',
  'moderate': 'Moderate (3-5 days/week)',
  'active': 'Active (6-7 days/week)',
  'extra_active': 'Extra active (very hard exercise)',
};

/// Captures the profile inputs needed to estimate TDEE (see
/// [estimateTdee]) plus a target weight, so the Weight Goal projection can
/// be computed. One Metric/US toggle drives both the weight unit (kg/lb)
/// and the height input (a single cm field vs. separate feet/inches
/// fields) — weight and height are always stored in kg/cm regardless.
/// Submits via [AnalyticsRepository.updateUserProfile] and invalidates
/// [userProfileProvider].
Future<void> showEditWeightGoalDialog(
  BuildContext context,
  WidgetRef ref,
  UserProfile current,
) {
  var unitSystem = current.unitSystem;

  final targetWeightController = TextEditingController(
    text: current.targetWeightKg == null
        ? ''
        : formatNumberForDisplay(
            displayWeight(current.targetWeightKg!, unit: weightUnitFor(unitSystem)),
          ),
  );
  final ageController = TextEditingController(
    text: current.age?.toString() ?? '',
  );

  final heightCmController = TextEditingController(
    text: unitSystem == 'metric' ? (current.heightCm?.toString() ?? '') : '',
  );
  final initialFeetInches = current.heightCm == null
      ? null
      : cmToFeetInches(current.heightCm!);
  final heightFeetController = TextEditingController(
    text: unitSystem == 'us' ? (initialFeetInches?.feet.toString() ?? '') : '',
  );
  final heightInchesController = TextEditingController(
    text: unitSystem == 'us'
        ? (initialFeetInches == null
              ? ''
              : formatNumberForDisplay(initialFeetInches.inches))
        : '',
  );

  var sex = current.sex ?? 'male';
  var activityLevel = current.activityLevel ?? 'sedentary';

  /// Reads whichever height fields are currently active and returns cm, or
  /// null if incomplete/unparseable.
  double? currentHeightCm() {
    if (unitSystem == 'metric') {
      return double.tryParse(heightCmController.text);
    }
    final feet = int.tryParse(heightFeetController.text);
    final inches = double.tryParse(heightInchesController.text);
    if (feet == null || inches == null) return null;
    return feetInchesToCm(feet: feet, inches: inches);
  }

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Weight goal'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SegmentedButton<String>(
                    key: const Key('goal-unit-system-toggle'),
                    segments: const [
                      ButtonSegment(value: 'metric', label: Text('Metric')),
                      ButtonSegment(value: 'us', label: Text('US')),
                    ],
                    selected: {unitSystem},
                    onSelectionChanged: (selection) {
                      final newSystem = selection.first;
                      if (newSystem == unitSystem) return;

                      final oldWeightUnit = weightUnitFor(unitSystem);
                      final newWeightUnit = weightUnitFor(newSystem);
                      final enteredWeight = double.tryParse(
                        targetWeightController.text,
                      );
                      final heightCm = currentHeightCm();

                      setState(() {
                        if (enteredWeight != null) {
                          final kg = parseDisplayWeight(
                            enteredWeight,
                            unit: oldWeightUnit,
                          );
                          targetWeightController.text = formatNumberForDisplay(
                            displayWeight(kg, unit: newWeightUnit),
                          );
                        }
                        if (heightCm != null) {
                          if (newSystem == 'metric') {
                            heightCmController.text = formatNumberForDisplay(heightCm);
                          } else {
                            final feetInches = cmToFeetInches(heightCm);
                            heightFeetController.text = feetInches.feet
                                .toString();
                            heightInchesController.text = formatNumberForDisplay(
                              feetInches.inches,
                            );
                          }
                        }
                        unitSystem = newSystem;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('goal-target-weight-field'),
                    controller: targetWeightController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Target weight (${weightUnitFor(unitSystem)})',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('goal-sex-dropdown'),
                    initialValue: sex,
                    decoration: const InputDecoration(labelText: 'Sex'),
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => sex = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('goal-age-field'),
                    controller: ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age'),
                  ),
                  const SizedBox(height: 12),
                  if (unitSystem == 'metric')
                    TextField(
                      key: const Key('goal-height-cm-field'),
                      controller: heightCmController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            key: const Key('goal-height-feet-field'),
                            controller: heightFeetController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Feet'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            key: const Key('goal-height-inches-field'),
                            controller: heightInchesController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(labelText: 'Inches'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('goal-activity-dropdown'),
                    initialValue: activityLevel,
                    decoration: const InputDecoration(labelText: 'Activity level'),
                    items: [
                      for (final entry in _activityLabels.entries)
                        DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => activityLevel = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'TDEE is estimated (Mifflin-St Jeor) — treat the '
                    'projection as directional, not exact.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  final enteredTargetWeight = double.tryParse(
                    targetWeightController.text,
                  );
                  final age = int.tryParse(ageController.text);
                  final height = currentHeightCm();
                  if (enteredTargetWeight == null || age == null || height == null) {
                    return;
                  }

                  final profile = UserProfile(
                    targetWeightKg: parseDisplayWeight(
                      enteredTargetWeight,
                      unit: weightUnitFor(unitSystem),
                    ),
                    sex: sex,
                    age: age,
                    heightCm: height,
                    activityLevel: activityLevel,
                    unitSystem: unitSystem,
                  );
                  await ref
                      .read(analyticsRepositoryProvider)
                      .updateUserProfile(profile);
                  ref.invalidate(userProfileProvider);
                  if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                },
                style: TextButton.styleFrom(foregroundColor: AppColors.brandGreen),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    },
  );
}
