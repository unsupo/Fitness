import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/machine.dart';
import '../controllers/exercises_providers.dart';

/// Strong's "Exercises" tab: a searchable, muscle-group-grouped machine
/// library. Tapping a machine opens `ExerciseDetailPage` via
/// `/workouts/exercise/:id` (wired centrally by the router).
class ExercisesTab extends ConsumerStatefulWidget {
  const ExercisesTab({super.key});

  @override
  ConsumerState<ExercisesTab> createState() => _ExercisesTabState();
}

class _ExercisesTabState extends ConsumerState<ExercisesTab> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final machinesAsync = ref.watch(machinesProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search exercises',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: machinesAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) =>
                    Center(child: Text('Could not load exercises: $error')),
                data: (machines) =>
                    _ExercisesList(machines: machines, query: _query),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisesList extends StatelessWidget {
  const _ExercisesList({required this.machines, required this.query});

  final List<Machine> machines;
  final String query;

  @override
  Widget build(BuildContext context) {
    if (machines.isEmpty) {
      return const _EmptyExercises();
    }

    final needle = query.trim().toLowerCase();
    final filtered = needle.isEmpty
        ? machines
        : machines.where((machine) {
            if (machine.name.toLowerCase().contains(needle)) return true;
            return machine.aliases.any(
              (alias) => alias.toLowerCase().contains(needle),
            );
          }).toList();

    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No exercises match your search',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    // Manual groupBy (no package dependency): fold into an insertion-order
    // map keyed by muscle group, null -> "Other".
    final grouped = <String, List<Machine>>{};
    for (final machine in filtered) {
      final key = _titleCase(machine.muscleGroup) ?? 'Other';
      grouped.putIfAbsent(key, () => []).add(machine);
    }

    final groupNames = grouped.keys.toList();

    return ListView.separated(
      itemCount: groupNames.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final groupName = groupNames[index];
        final groupMachines = grouped[groupName]!;

        return SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupName,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              for (final machine in groupMachines)
                Material(
                  type: MaterialType.transparency,
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(machine.name),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/workouts/exercise/${machine.id}'),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _EmptyExercises extends StatelessWidget {
  const _EmptyExercises();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SectionCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.fitness_center,
              size: 40,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'No exercises yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Exercises will show up here once machines are added.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Title-cases free-text muscle group values (`'chest'` -> `'Chest'`,
/// `'lower back'` -> `'Lower Back'`). Returns `null` for a null/blank input
/// so the caller can substitute the "Other" heading.
String? _titleCase(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value
      .trim()
      .split(RegExp(r'\s+'))
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
}
