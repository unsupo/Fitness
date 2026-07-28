import '../../../../core/network/supabase_json.dart';
import '../../domain/entities/weight_entry.dart';

/// Maps a `weight_log` Supabase row to a [WeightEntry]. Postgres `numeric`
/// columns don't consistently arrive as `String` via supabase_flutter, so
/// `weight_kg` goes through [parseSupabaseNum] rather than a raw cast.
class WeightEntryModel {
  static WeightEntry fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as int,
      loggedAt: DateTime.parse(json['logged_at'] as String).toLocal(),
      weightKg: parseSupabaseNum(json['weight_kg']),
      goalType: json['goal_type'] as String,
    );
  }

  static Map<String, dynamic> toInsertJson({
    required double weightKg,
    required String goalType,
  }) {
    return {
      'weight_kg': weightKg,
      'goal_type': goalType,
      'logged_at': DateTime.now().toUtc().toIso8601String(),
    };
  }
}
