import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/supabase_tables.dart';
import '../../../diary/domain/entities/daily_goals.dart';
import '../../../diary/domain/entities/daily_totals.dart';
import '../../../diary/domain/use_cases/compute_daily_totals.dart';
import '../../../diary/presentation/controllers/diary_providers.dart';
import '../../domain/entities/recognized_meal.dart';
import '../controllers/scanner_providers.dart';
import '../widgets/recognized_meal_result.dart';

enum _Stage { capturing, loading, result }

/// Mockup Image 3: capture photo -> hero image + macro breakdown -> adjust
/// serving -> save. The recognition call itself is stubbed (see
/// `data/repositories/stub_food_recognition_repository.dart`); the UI flow
/// here is real.
class FoodRecognitionPage extends ConsumerStatefulWidget {
  const FoodRecognitionPage({super.key});

  @override
  ConsumerState<FoodRecognitionPage> createState() =>
      _FoodRecognitionPageState();
}

class _FoodRecognitionPageState extends ConsumerState<FoodRecognitionPage> {
  CameraController? _cameraController;
  bool _cameraAvailable = true;
  _Stage _stage = _Stage.capturing;
  XFile? _capturedImage;
  RecognizedMeal? _result;
  DailyTotals? _currentTotals;
  DailyGoals? _goals;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _cameraAvailable = false);
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _cameraController = controller);
    } catch (_) {
      // No camera/permission available (e.g. emulator) — fall back to the
      // placeholder capture button rather than crashing the screen.
      if (mounted) setState(() => _cameraAvailable = false);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    XFile? image;
    final controller = _cameraController;
    if (controller != null && controller.value.isInitialized) {
      try {
        image = await controller.takePicture();
      } catch (_) {
        image = null;
      }
    }

    setState(() {
      _capturedImage = image;
      _stage = _Stage.loading;
    });

    final result = await ref
        .read(foodRecognitionRepositoryProvider)
        .recognize(image ?? XFile(''));

    // Best-effort: a failed goals/entries fetch must never block showing the
    // recognition result, it just means no caution is shown.
    try {
      final entries = await ref.read(diaryEntriesProvider(DateTime.now()).future);
      final goals = await ref.read(dailyGoalsProvider.future);
      _currentTotals = computeDailyTotals(entries);
      _goals = goals;
    } catch (_) {
      _currentTotals = null;
      _goals = null;
    }

    if (!mounted) return;
    setState(() {
      _result = result;
      _stage = _Stage.result;
    });
  }

  Future<void> _save(RecognizedMeal meal) async {
    await ref
        .read(foodLoggingRepositoryProvider)
        .logRecognizedMeal(meal, MealType.snack);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case _Stage.capturing:
        return _buildCapturing(context);
      case _Stage.loading:
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      case _Stage.result:
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => context.pop(),
            ),
          ),
          body: RecognizedMealResult(
            meal: _result!,
            capturedImage: _capturedImage,
            onSave: _save,
            currentTotals: _currentTotals,
            goals: _goals,
          ),
        );
    }
  }

  Widget _buildCapturing(BuildContext context) {
    final controller = _cameraController;
    final previewReady = controller != null && controller.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (previewReady)
            CameraPreview(controller)
          else
            const ColoredBox(color: Colors.black87),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: GestureDetector(
                onTap: _capture,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white54, width: 4),
                  ),
                  child: _cameraAvailable && previewReady
                      ? null
                      : const Icon(
                          Icons.photo_camera,
                          color: Colors.black54,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
