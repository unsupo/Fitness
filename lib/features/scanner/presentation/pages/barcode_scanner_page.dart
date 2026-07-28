import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/network/supabase_tables.dart';
import '../../../diary/domain/entities/remaining_after_adding.dart';
import '../../../diary/domain/use_cases/compute_daily_totals.dart';
import '../../../diary/domain/use_cases/compute_remaining_after_adding.dart';
import '../../../diary/presentation/controllers/diary_providers.dart';
import '../../domain/entities/scanned_product.dart';
import '../controllers/scanner_providers.dart';
import '../widgets/scanned_product_sheet.dart';

/// Mockup Image 2: full-screen barcode scanner with a result bottom sheet.
class BarcodeScannerPage extends ConsumerStatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  ConsumerState<BarcodeScannerPage> createState() =>
      _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends ConsumerState<BarcodeScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handling) return;
    if (capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue;
    if (value == null) return;

    setState(() => _handling = true);
    try {
      final repository = ref.read(barcodeLookupRepositoryProvider);
      final product = await repository.lookup(value);
      if (!mounted) return;

      if (product == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product not found')),
        );
        return;
      }

      final remaining = await _computeRemainingAfterAdding(product);
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return ScannedProductSheet(
            product: product,
            remaining: remaining,
            onAddToDiary: () => _addToDiary(sheetContext, product),
          );
        },
      );
    } finally {
      if (mounted) setState(() => _handling = false);
    }
  }

  /// Best-effort: a failed goals/entries fetch must never block showing the
  /// result sheet, it just means no caution is shown.
  Future<RemainingAfterAdding?> _computeRemainingAfterAdding(
    ScannedProduct product,
  ) async {
    try {
      final today = DateTime.now(); // always "today" — never selectedDateProvider
      final entries = await ref.read(diaryEntriesProvider(today).future);
      final goals = await ref.read(dailyGoalsProvider.future);
      return computeRemainingAfterAdding(
        currentTotals: computeDailyTotals(entries),
        goals: goals,
        addedCalories: product.calories,
        addedProteinG: product.proteinG,
        addedCarbsG: product.carbsG,
        addedFatG: product.fatG,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _addToDiary(
    BuildContext sheetContext,
    ScannedProduct product,
  ) async {
    await ref
        .read(foodLoggingRepositoryProvider)
        .logScannedProduct(product, MealType.snack);
    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(controller: _controller, onDetect: _onDetect),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Text(
                        'Nourish',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
