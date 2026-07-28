import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/backend.dart';
import '../../domain/repositories/workout_repository.dart';

/// Composition root for the Workouts feature — see docs/ARCHITECTURE.md's
/// "Composition root" section. Every Workouts presentation provider depends
/// on this, never on a concrete `SupabaseWorkoutRepository` directly.
final workoutRepositoryProvider = Provider<WorkoutRepository>(
  (ref) => ref.watch(backendProvider).createWorkoutRepository(),
);
