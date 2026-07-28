import 'package:flutter/material.dart';

import '../../../../core/network/external_link_launcher.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/food_thumbnail.dart';
import '../../../diary/domain/entities/remaining_after_adding.dart';
import '../../domain/entities/scanned_product.dart';
import 'stat_column.dart';

/// The barcode-scan result bottom-sheet content (mockup Image 2), extracted
/// so it's unit-testable given a fixed [ScannedProduct] without needing a
/// real camera/[MobileScanner] in the test.
class ScannedProductSheet extends StatelessWidget {
  const ScannedProductSheet({
    super.key,
    required this.product,
    required this.onAddToDiary,
    this.remaining,
  });

  final ScannedProduct product;
  final VoidCallback onAddToDiary;

  /// How much of today's goal would be left after adding this product —
  /// computed by the caller (which has `ref` access), `null` when unknown
  /// (e.g. the goals/entries fetch failed) so nothing is shown.
  final RemainingAfterAdding? remaining;

  @override
  Widget build(BuildContext context) {
    final weight = (product.servingWeightG ?? 100).round();

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.ringTrack,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FoodThumbnail(imageUrl: product.imageUrl, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (product.sourceUrl != null)
                        TextButton.icon(
                          onPressed: () => openExternalUrl(product.sourceUrl!),
                          icon: const Icon(Icons.open_in_new, size: 16),
                          label: const Text('View source'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            alignment: Alignment.centerLeft,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (product.brand != null) ...[
              const SizedBox(height: 2),
              Text(
                product.brand!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              'Weight: ${weight}g',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                StatColumn(
                  label: 'Calories',
                  value: product.calories.round().toString(),
                  color: AppColors.accentOrange,
                ),
                StatColumn(
                  label: 'Protein',
                  value: '${product.proteinG.round()}g',
                  color: AppColors.proteinRing,
                ),
                StatColumn(
                  label: 'Sugar',
                  value: '${product.sugarG.round()}g',
                  color: AppColors.carbsRing,
                ),
                StatColumn(
                  label: 'Fat',
                  value: '${product.fatG.round()}g',
                  color: AppColors.fatRing,
                ),
              ],
            ),
            if (remaining != null) ...[
              const SizedBox(height: 12),
              Text(
                '${remaining!.remainingCalories.round()} kcal left today after adding this',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              if (remaining!.isOverCalorieGoal) ...[
                const SizedBox(height: 4),
                Text(
                  'This puts you ${(-remaining!.remainingCalories).round()} kcal over your daily goal.',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAddToDiary,
                child: const Text('Add to Diary'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
