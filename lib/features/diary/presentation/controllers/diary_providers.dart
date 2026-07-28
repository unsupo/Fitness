import 'package:arndt_fitness/core/di/backend.dart';
import 'package:arndt_fitness/features/diary/domain/entities/daily_goals.dart';
import 'package:arndt_fitness/features/diary/domain/entities/diary_entry.dart';
import 'package:arndt_fitness/features/diary/domain/entities/food_item.dart';
import 'package:arndt_fitness/features/diary/domain/entities/online_food_candidate.dart';
import 'package:arndt_fitness/features/diary/domain/repositories/diary_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart' show StateProvider;

final diaryRepositoryProvider = Provider<DiaryRepository>(
  (ref) => ref.watch(backendProvider).createDiaryRepository(),
);

final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

final diaryEntriesProvider = FutureProvider.family<List<DiaryEntry>, DateTime>(
  (ref, date) => ref.watch(diaryRepositoryProvider).getEntriesForDate(date),
);

final dailyGoalsProvider = FutureProvider<DailyGoals>(
  (ref) => ref.watch(diaryRepositoryProvider).getDailyGoals(),
);

final foodDetailsProvider = FutureProvider.family<FoodItem, int>(
  (ref, foodId) => ref.watch(diaryRepositoryProvider).getFoodDetails(foodId),
);

final recentFoodsProvider = FutureProvider<List<FoodItem>>(
  (ref) => ref.watch(diaryRepositoryProvider).getRecentFoods(),
);

final onlineFoodSearchProvider =
    FutureProvider.family<List<OnlineFoodCandidate>, String>(
      (ref, query) => ref.watch(diaryRepositoryProvider).searchOnlineFoods(query),
    );
