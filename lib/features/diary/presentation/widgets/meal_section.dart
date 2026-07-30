import 'package:arndt_fitness/core/network/supabase_tables.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/use_cases/format_quantity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'edit_diary_entry_dialog.dart';

/// A `SectionCard` for one meal type: heading + a `ListTile` per entry
/// (each editable/deletable via the pencil icon), plus a small orange "+"
/// button that pushes the scanner.
class MealSection extends ConsumerWidget {
  const MealSection({super.key, required this.mealType, required this.entries});

  final MealType mealType;
  final List<DiaryEntry> entries;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            mealType.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          for (final entry in entries)
            Material(
              type: MaterialType.transparency,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: FoodThumbnail(imageUrl: entry.imageUrl, size: 48),
                title: Text(entry.foodName),
                subtitle: Text(
                  '${entry.calories.round()} calories · '
                  '${formatQuantity(entry)} · '
                  '${DateFormat('h:mm a').format(entry.loggedAt)}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      tooltip: 'Edit entry',
                      onPressed: () =>
                          showEditDiaryEntryDialog(context, ref, entry),
                    ),
                    if (entry.foodId != null || entry.recipeId != null)
                      const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: entry.foodId != null
                    ? () => context.push('/food-detail/${entry.foodId}')
                    : entry.recipeId != null
                    ? () => context.push('/recipes/detail/${entry.recipeId}')
                    : null,
              ),
            ),
          const SizedBox(height: 4),
          Center(
            child: IconButton(
              onPressed: () => context.push('/scanner'),
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
              ),
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}
