import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for user training focus preference ('hypertrophy' or 'strength').
final trainingFocusProvider = NotifierProvider<TrainingFocusNotifier, String>(() {
  return TrainingFocusNotifier();
});

class TrainingFocusNotifier extends Notifier<String> {
  static const _key = 'training_focus';

  @override
  String build() {
    _load();
    return 'hypertrophy';
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (ref.mounted) {
      state = prefs.getString(_key) ?? 'hypertrophy';
    }
  }

  Future<void> setFocus(String focus) async {
    state = focus;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, focus);
  }
}
