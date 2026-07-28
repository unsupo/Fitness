import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/backend.dart';
import '../../domain/repositories/barcode_lookup_repository.dart';
import '../../domain/repositories/food_logging_repository.dart';
import '../../domain/repositories/food_recognition_repository.dart';

final barcodeLookupRepositoryProvider = Provider<BarcodeLookupRepository>(
  (ref) => ref.watch(backendProvider).createBarcodeLookupRepository(),
);

final foodRecognitionRepositoryProvider = Provider<FoodRecognitionRepository>(
  (ref) => ref.watch(backendProvider).createFoodRecognitionRepository(),
);

final foodLoggingRepositoryProvider = Provider<FoodLoggingRepository>(
  (ref) => ref.watch(backendProvider).createFoodLoggingRepository(),
);
