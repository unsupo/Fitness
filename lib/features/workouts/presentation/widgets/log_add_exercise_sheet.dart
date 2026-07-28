import 'package:flutter/material.dart';

import '../../domain/entities/machine.dart';

/// "Add Exercise" bottom sheet content: a searchable (name + aliases) list
/// of [Machine]s. Tapping one pops the sheet with that machine as the
/// result — the caller (`LogTab`) adds it to the active session's local
/// exercise list. No repository write happens here; a machine is only
/// persisted once a set is logged against it.
class LogAddExerciseSheet extends StatefulWidget {
  const LogAddExerciseSheet({super.key, required this.machines});

  final List<Machine> machines;

  @override
  State<LogAddExerciseSheet> createState() => _LogAddExerciseSheetState();
}

class _LogAddExerciseSheetState extends State<LogAddExerciseSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.toLowerCase();
    final filtered = query.isEmpty
        ? widget.machines
        : widget.machines.where((machine) {
            if (machine.name.toLowerCase().contains(query)) return true;
            return machine.aliases.any(
              (alias) => alias.toLowerCase().contains(query),
            );
          }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                key: const Key('add-exercise-search-field'),
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search machines',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
            ),
            Flexible(
              child: filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No machines match your search.'),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: [
                        for (final machine in filtered)
                          ListTile(
                            key: Key('add-exercise-option-${machine.id}'),
                            title: Text(machine.name),
                            subtitle: machine.muscleGroup == null
                                ? null
                                : Text(machine.muscleGroup!),
                            onTap: () => Navigator.of(context).pop(machine),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
