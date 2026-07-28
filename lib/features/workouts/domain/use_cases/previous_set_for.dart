import '../entities/workout_set.dart';

/// Given [history] (all past sets for one machine, any session), returns the
/// set with the same [setNumber] from the most recent session other than
/// [currentSessionId] — falling back to that session's last set if it had
/// fewer sets than [setNumber]. Returns `null` if there's no other session
/// in [history] to compare against. Powers the "Previous" hint shown per
/// set row in the Log tab (docs/features/workouts-log-redesign.md).
WorkoutSet? previousSetFor(
  List<WorkoutSet> history,
  int setNumber, {
  required int currentSessionId,
}) {
  final byOtherSession = <int, List<WorkoutSet>>{};
  for (final set in history) {
    if (set.sessionId == currentSessionId) continue;
    byOtherSession.putIfAbsent(set.sessionId, () => []).add(set);
  }
  if (byOtherSession.isEmpty) return null;

  final mostRecentSessionId = byOtherSession.entries
      .reduce(
        (a, b) =>
            _latest(a.value).loggedAt.isAfter(_latest(b.value).loggedAt)
            ? a
            : b,
      )
      .key;
  final setsInSession = byOtherSession[mostRecentSessionId]!
    ..sort((a, b) => a.setNumber.compareTo(b.setNumber));

  for (final set in setsInSession) {
    if (set.setNumber == setNumber) return set;
  }
  return setsInSession.last;
}

WorkoutSet _latest(List<WorkoutSet> sets) =>
    sets.reduce((a, b) => a.loggedAt.isAfter(b.loggedAt) ? a : b);
