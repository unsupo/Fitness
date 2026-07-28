import 'package:arndt_fitness/core/network/external_link_launcher.dart';
import 'package:arndt_fitness/core/theme/app_theme.dart';
import 'package:arndt_fitness/core/widgets/food_thumbnail.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/presentation/controllers/diary_providers.dart';
import 'package:arndt_fitness/features/diary/presentation/widgets/edit_food_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full nutrition detail for a single food, reached by tapping a diary entry.
class FoodDetailPage extends ConsumerWidget {
  const FoodDetailPage({super.key, required this.foodId});

  final int foodId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final foodAsync = ref.watch(foodDetailsProvider(foodId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nourish'),
        actions: [
          foodAsync.maybeWhen(
            data: (food) => IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit food',
              onPressed: () => showEditFoodDialog(context, ref, food),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: SafeArea(
        child: foodAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) =>
              Center(child: Text('Could not load food: $error')),
          data: (food) => _FoodDetailBody(food: food),
        ),
      ),
    );
  }
}

class _FoodDetailBody extends StatelessWidget {
  const _FoodDetailBody({required this.food});

  final FoodItem food;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _FoodHero(imageUrl: food.imageUrl),
        const SizedBox(height: 16),
        Text(
          food.name,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (food.sourceUrl != null) ...[
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => openExternalUrl(food.sourceUrl!),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View source'),
            ),
          ),
        ],
        if (food.brand != null) ...[
          const SizedBox(height: 4),
          Text(
            food.brand!,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
        if (food.servingSize != null) ...[
          const SizedBox(height: 4),
          Text('Serving: ${food.servingSize} ${food.servingUnit ?? ''}'),
        ],
        const SizedBox(height: 16),
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${food.calories.round()} calories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _MacroRow(label: 'Protein', grams: food.proteinG),
              _MacroRow(label: 'Carbs', grams: food.carbsG),
              _MacroRow(label: 'Fat', grams: food.fatG),
              if (food.fiberG != null)
                _MacroRow(label: 'Fiber', grams: food.fiberG!),
              if (food.sugarG != null)
                _MacroRow(label: 'Sugar', grams: food.sugarG!),
              if (food.sodiumMg != null)
                _MacroRow(label: 'Sodium', grams: food.sodiumMg!, unit: 'mg'),
            ],
          ),
        ),
        if (food.isEstimate == true) ...[
          const SizedBox(height: 12),
          const Text(
            'Estimated values',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }
}

/// A full-width, rounded, shadowed banner when the food has a real photo —
/// a showcase, not just a list-row icon. Falls back to the compact
/// [FoodThumbnail] placeholder treatment (matching every other place a food
/// image can appear) when there's no photo at all. A photo that's set but
/// fails to load (dead link, hotlink-blocked CDN, etc.) still renders the
/// banner shape with a large centered placeholder icon inside it, rather
/// than silently shrinking back down — the URL is real, it just isn't
/// loading right now.
class _FoodHero extends StatelessWidget {
  const _FoodHero({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null) {
      return Center(child: FoodThumbnail(imageUrl: url, size: 128));
    }

    return Container(
      key: const Key('food-hero-banner'),
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : _bannerPlaceholder(),
        errorBuilder: (context, error, stackTrace) => _bannerPlaceholder(),
      ),
    );
  }

  Widget _bannerPlaceholder() => Container(
    color: AppColors.background,
    alignment: Alignment.center,
    child: const Icon(
      Icons.restaurant,
      size: 56,
      color: AppColors.textSecondary,
    ),
  );
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({required this.label, required this.grams, this.unit = 'g'});

  final String label;
  final double grams;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text('${grams.round()}$unit')],
      ),
    );
  }
}
