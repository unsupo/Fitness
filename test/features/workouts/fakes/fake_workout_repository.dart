import 'package:arndt_fitness/features/workouts/domain/entities/machine.dart';
import 'package:arndt_fitness/features/workouts/domain/entities/workout_session.dart';
import 'package:arndt_fitness/features/workouts/domain/entities/workout_set.dart';
import 'package:arndt_fitness/features/workouts/domain/repositories/workout_repository.dart';

/// A canned [WorkoutRepository] for widget tests — no real network/Supabase
/// calls. Returns fixed sessions/sets and records calls made against it so
/// tests can assert the presentation layer talked to the adapter correctly.
///
/// Shared across the Workouts presentation agents' test suites (History,
/// Log, Exercises) — extend with more fields/overrides rather than
/// duplicating this file if your scope needs additional fixtures.
class FakeWorkoutRepository implements WorkoutRepository {
  FakeWorkoutRepository({
    List<Machine>? machines,
    List<WorkoutSession>? sessions,
    Map<int, List<WorkoutSet>>? setsBySession,
  }) : machines = List.of(machines ?? defaultMachines),
       sessions = List.of(sessions ?? defaultSessions),
       setsBySession = {
         for (final entry in (setsBySession ?? defaultSetsBySession).entries)
           entry.key: List.of(entry.value),
       };

  final List<Machine> machines;
  final List<WorkoutSession> sessions;
  final Map<int, List<WorkoutSet>> setsBySession;

  static const defaultMachines = <Machine>[
    Machine(id: 1, name: 'Bench Press', muscleGroup: 'chest'),
    Machine(id: 2, name: 'Squat', muscleGroup: 'legs'),
    Machine(id: 3, name: 'Treadmill', muscleGroup: 'cardio'),
  ];

  /// Newest first — matches the real data layer's ordering contract (see
  /// docs/features/workouts-history.md), which callers rely on rather than
  /// re-sorting themselves.
  static final defaultSessions = <WorkoutSession>[
    WorkoutSession(id: 1, sessionDate: DateTime(2026, 7, 20)),
    WorkoutSession(id: 2, sessionDate: DateTime(2026, 7, 15)),
    WorkoutSession(id: 3, sessionDate: DateTime(2026, 7, 10)),
  ];

  static final defaultSetsBySession = <int, List<WorkoutSet>>{
    1: [
      WorkoutSet(
        id: 1,
        loggedAt: DateTime(2026, 7, 20, 9, 0),
        machineId: 1,
        machineName: 'Bench Press',
        sessionId: 1,
        setNumber: 1,
        machineOrder: 1,
        weight: 135,
        reps: 8,
        unit: 'lb',
      ),
      WorkoutSet(
        id: 2,
        loggedAt: DateTime(2026, 7, 20, 9, 5),
        machineId: 1,
        machineName: 'Bench Press',
        sessionId: 1,
        setNumber: 2,
        machineOrder: 1,
        weight: 145,
        reps: 6,
        unit: 'lb',
      ),
      WorkoutSet(
        id: 3,
        loggedAt: DateTime(2026, 7, 20, 9, 15),
        machineId: 2,
        machineName: 'Squat',
        sessionId: 1,
        setNumber: 1,
        machineOrder: 2,
        weight: 225,
        reps: 5,
        unit: 'lb',
      ),
    ],
    2: [
      WorkoutSet(
        id: 4,
        loggedAt: DateTime(2026, 7, 15, 8, 0),
        machineId: 3,
        machineName: 'Treadmill',
        sessionId: 2,
        setNumber: 1,
        machineOrder: 1,
        durationMinutes: 12,
        speed: 5.5,
        incline: 1.0,
      ),
    ],
    3: [
      WorkoutSet(
        id: 5,
        loggedAt: DateTime(2026, 7, 10, 7, 0),
        machineId: 2,
        machineName: 'Squat',
        sessionId: 3,
        setNumber: 1,
        machineOrder: 1,
        weight: 205,
        reps: 5,
        unit: 'lb',
      ),
      WorkoutSet(
        id: 6,
        loggedAt: DateTime(2026, 7, 10, 7, 10),
        machineId: 1,
        machineName: 'Bench Press',
        sessionId: 3,
        setNumber: 1,
        machineOrder: 2,
        weight: 130,
        reps: 8,
        unit: 'lb',
      ),
    ],
  };

  /// Records the [DateTime] passed to the last `startSession` call.
  DateTime? lastStartSessionCall;

  /// Records the last `logSet` call.
  WorkoutSet? lastLogSetCall;

  /// Records the last `updateSet` call.
  WorkoutSet? lastUpdateSetCall;

  /// Records the id passed to the last `deleteSet` call.
  int? lastDeleteSetCall;

  /// Call counters for the read methods — used by pull-to-refresh /
  /// resume-refresh tests to assert a re-fetch actually happened, not just
  /// that the initial build rendered fixture data.
  int getMachinesCallCount = 0;
  int getLastSessionCallCount = 0;
  int getSessionHistoryCallCount = 0;
  final Map<int, int> getSetsForSessionCallCounts = {};
  final Map<int, int> getSetsForMachineCallCounts = {};

  @override
  Future<List<Machine>> getMachines() async {
    getMachinesCallCount++;
    return machines;
  }

  @override
  Future<WorkoutSession?> getLastSession() async {
    getLastSessionCallCount++;
    return sessions.isEmpty ? null : sessions.first;
  }

  @override
  Future<List<WorkoutSession>> getSessionHistory() async {
    getSessionHistoryCallCount++;
    return sessions;
  }

  @override
  Future<List<WorkoutSet>> getSetsForSession(int sessionId) async {
    getSetsForSessionCallCounts.update(
      sessionId,
      (n) => n + 1,
      ifAbsent: () => 1,
    );
    return setsBySession[sessionId] ?? const [];
  }

  @override
  Future<List<WorkoutSet>> getSetsForMachine(int machineId) async {
    getSetsForMachineCallCounts.update(
      machineId,
      (n) => n + 1,
      ifAbsent: () => 1,
    );
    return [
      for (final sets in setsBySession.values)
        for (final set in sets)
          if (set.machineId == machineId) set,
    ];
  }

  @override
  Future<WorkoutSession> startSession(DateTime sessionDate) async {
    lastStartSessionCall = sessionDate;
    final session = WorkoutSession(
      id: sessions.length + 1,
      sessionDate: sessionDate,
    );
    sessions.insert(0, session);
    return session;
  }

  @override
  Future<WorkoutSet> logSet(WorkoutSet set) async {
    lastLogSetCall = set;
    final created = WorkoutSet(
      id: 1000 + (setsBySession.values.fold(0, (n, l) => n + l.length)),
      loggedAt: set.loggedAt,
      machineId: set.machineId,
      machineName: set.machineName,
      sessionId: set.sessionId,
      setNumber: set.setNumber,
      machineOrder: set.machineOrder,
      weight: set.weight,
      reps: set.reps,
      unit: set.unit,
      incline: set.incline,
      speed: set.speed,
      durationMinutes: set.durationMinutes,
      seatPosition: set.seatPosition,
      restSeconds: set.restSeconds,
      notes: set.notes,
    );
    setsBySession.putIfAbsent(set.sessionId, () => []).add(created);
    return created;
  }

  @override
  Future<void> updateSet(WorkoutSet set) async {
    lastUpdateSetCall = set;
    final list = setsBySession[set.sessionId];
    if (list == null) return;
    final index = list.indexWhere((s) => s.id == set.id);
    if (index != -1) list[index] = set;
  }

  @override
  Future<void> deleteSet(int id) async {
    lastDeleteSetCall = id;
    for (final list in setsBySession.values) {
      list.removeWhere((s) => s.id == id);
    }
  }
}
