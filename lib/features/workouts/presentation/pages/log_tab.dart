import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/machine.dart';
import '../../domain/entities/workout_session.dart';
import '../../domain/entities/workout_set.dart';
import '../controllers/log_providers.dart';
import '../controllers/workout_repository_provider.dart';
import '../widgets/log_active_view.dart';
import '../widgets/log_add_exercise_sheet.dart';
import '../widgets/log_idle_view.dart';

/// The Workouts feature's "Log" tab (Strong's "Workout" tab equivalent) —
/// one child of the `/workouts` route's `TabBarView` (wired centrally).
/// Deliberately has no `Scaffold`/`AppBar` of its own; the host page owns
/// those.
///
/// Idle: a "last workout" summary + "Start Workout" CTA. Active: the
/// in-progress session's exercises with inline set logging. The active
/// session is local-only UI state, not persisted across app restarts — the
/// session and each set are written to Supabase as they happen, so
/// "finishing" a workout is just clearing local state back to idle, not a
/// write of its own (the schema has no "session ended" column).
class LogTab extends ConsumerStatefulWidget {
  const LogTab({super.key});

  @override
  ConsumerState<LogTab> createState() => _LogTabState();
}

class _LogTabState extends ConsumerState<LogTab> {
  WorkoutSession? _activeSession;
  final List<Machine> _activeMachines = [];

  Future<void> _startWorkout() async {
    final session = await ref
        .read(workoutRepositoryProvider)
        .startSession(DateTime.now());
    if (!mounted) return;
    setState(() {
      _activeSession = session;
      _activeMachines.clear();
    });
  }

  void _finishWorkout() {
    setState(() {
      _activeSession = null;
      _activeMachines.clear();
    });
  }

  void _addMachine(Machine machine) {
    if (_activeMachines.any((m) => m.id == machine.id)) return;
    setState(() => _activeMachines.add(machine));
  }

  Future<void> _openAddExerciseSheet() async {
    final machines = await ref.read(machinesProvider.future);
    if (!mounted) return;
    final selected = await showModalBottomSheet<Machine>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LogAddExerciseSheet(machines: machines),
    );
    if (selected != null) _addMachine(selected);
  }

  Future<void> _logSet(WorkoutSet draft) async {
    await ref.read(workoutRepositoryProvider).logSet(draft);
    ref.invalidate(sessionSetsProvider(draft.sessionId));
  }

  @override
  Widget build(BuildContext context) {
    final session = _activeSession;
    if (session == null) {
      return LogIdleView(onStartWorkout: _startWorkout);
    }
    return LogActiveView(
      session: session,
      machines: _activeMachines,
      onFinish: _finishWorkout,
      onAddExercise: _openAddExerciseSheet,
      onLogSet: (draft) => _logSet(draft),
    );
  }
}
