import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:arndt_fitness/features/analytics/domain/entities/user_profile.dart';
import 'package:arndt_fitness/features/analytics/presentation/controllers/analytics_providers.dart';
import 'package:arndt_fitness/features/analytics/presentation/widgets/edit_weight_goal_dialog.dart';

import '../fakes/fake_analytics_repository.dart';

void main() {
  const startingProfile = UserProfile(
    sex: 'male',
    age: 30,
    heightCm: 180,
    activityLevel: 'sedentary',
    targetWeightKg: 80,
    unitSystem: 'metric',
  );

  Future<FakeAnalyticsRepository> pumpDialog(WidgetTester tester) async {
    final fake = FakeAnalyticsRepository(userProfile: startingProfile);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(fake)],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => ElevatedButton(
              onPressed: () =>
                  showEditWeightGoalDialog(context, ref, startingProfile),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('starts on Metric, showing kg weight and a single cm height field', (
    tester,
  ) async {
    await pumpDialog(tester);

    final weightField = tester.widget<TextField>(
      find.byKey(const Key('goal-target-weight-field')),
    );
    expect(weightField.controller!.text, '80');
    expect(find.byKey(const Key('goal-height-cm-field')), findsOneWidget);
    expect(find.byKey(const Key('goal-height-feet-field')), findsNothing);
  });

  testWidgets('switching to US converts weight to lb and height to ft/in', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.tap(find.text('US'));
    await tester.pumpAndSettle();

    final weightField = tester.widget<TextField>(
      find.byKey(const Key('goal-target-weight-field')),
    );
    expect(double.parse(weightField.controller!.text), closeTo(176.37, 0.01));

    expect(find.byKey(const Key('goal-height-cm-field')), findsNothing);
    final feetField = tester.widget<TextField>(
      find.byKey(const Key('goal-height-feet-field')),
    );
    final inchesField = tester.widget<TextField>(
      find.byKey(const Key('goal-height-inches-field')),
    );
    // 180 cm = 5 ft 10.87 in.
    expect(feetField.controller!.text, '5');
    expect(double.parse(inchesField.controller!.text), closeTo(10.87, 0.01));
  });

  testWidgets('saving after switching to US converts both values back to metric', (
    tester,
  ) async {
    final fake = await pumpDialog(tester);

    await tester.tap(find.text('US'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('goal-target-weight-field')),
      '176.37',
    );
    await tester.enterText(
      find.byKey(const Key('goal-height-feet-field')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('goal-height-inches-field')),
      '10.87',
    );

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(fake.userProfile.unitSystem, 'us');
    expect(fake.userProfile.targetWeightKg, closeTo(80, 0.01));
    expect(fake.userProfile.heightCm, closeTo(180, 0.01));
  });
}
