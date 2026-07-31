import 'package:arndt_fitness/features/workouts/presentation/controllers/overload_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrainingFocusNotifier', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('defaults to hypertrophy', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(trainingFocusProvider), equals('hypertrophy'));
    });

    test('saves and loads value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(trainingFocusProvider.notifier).setFocus('strength');
      expect(container.read(trainingFocusProvider), equals('strength'));

      // Preset the mock initial values for the next container to simulate persistence
      SharedPreferences.setMockInitialValues({'training_focus': 'strength'});

      // Create a new container to simulate reload
      final container2 = ProviderContainer();
      addTearDown(container2.dispose);

      // Trigger the lazy build so _load starts executing
      container2.read(trainingFocusProvider);

      // Let the asynchronous load complete
      await Future.delayed(const Duration(milliseconds: 50));

      expect(container2.read(trainingFocusProvider), equals('strength'));
    });
  });
}
