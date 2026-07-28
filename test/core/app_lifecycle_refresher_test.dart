import 'package:arndt_fitness/core/app_lifecycle_refresher.dart';
import 'package:arndt_fitness/features/workouts/presentation/controllers/workout_repository_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../features/workouts/fakes/fake_workout_repository.dart';

/// A minimal widget that watches [machinesProvider] just enough to make it
/// "live" — invalidating a provider nothing is watching is a harmless no-op,
/// so the test needs an active listener to observe the resume-triggered
/// refetch.
class _WatchesMachines extends ConsumerWidget {
  const _WatchesMachines();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(machinesProvider);
    return const SizedBox.shrink();
  }
}

void main() {
  testWidgets(
    'resuming the app re-fetches Workouts data (machines, sessions, sets)',
    (tester) async {
      final fake = FakeWorkoutRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [workoutRepositoryProvider.overrideWithValue(fake)],
          child: const MaterialApp(
            home: AppLifecycleRefresher(child: _WatchesMachines()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final callsBefore = fake.getMachinesCallCount;
      expect(callsBefore, greaterThan(0));

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );
      await tester.pumpAndSettle();

      expect(fake.getMachinesCallCount, greaterThan(callsBefore));
    },
  );
}
