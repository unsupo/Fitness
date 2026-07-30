import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../../features/analytics/presentation/pages/trends_page.dart';
import '../../features/diary/presentation/pages/diary_page.dart';
import '../../features/diary/presentation/pages/food_detail_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/recipes/domain/entities/recipe.dart';
import '../../features/recipes/presentation/pages/add_recipe_page.dart';
import '../../features/recipes/presentation/pages/recipe_detail_page.dart';
import '../../features/recipes/presentation/pages/recipes_list_page.dart';
import '../../features/scanner/presentation/pages/barcode_scanner_page.dart';
import '../../features/scanner/presentation/pages/food_recognition_page.dart';
import '../../features/workouts/presentation/pages/exercise_detail_page.dart';
import '../../features/workouts/presentation/pages/workout_session_detail_page.dart';
import '../../features/workouts/presentation/pages/workouts_shell_page.dart';
import 'app_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const DiaryPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/recipes',
              builder: (context, state) => const RecipesListPage(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/trends', builder: (context, state) => const TrendsPage()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/scanner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BarcodeScannerPage(),
    ),
    GoRoute(
      path: '/food-recognition',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FoodRecognitionPage(),
    ),
    GoRoute(
      path: '/food-detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => FoodDetailPage(
        foodId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/recipes/add',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) =>
          AddRecipePage(recipeToEdit: state.extra as Recipe?),
    ),
    GoRoute(
      path: '/recipes/detail/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => RecipeDetailPage(
        recipeId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/workouts',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const WorkoutsShellPage(),
    ),
    GoRoute(
      path: '/workouts/session/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => WorkoutSessionDetailPage(
        sessionId: int.parse(state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/workouts/exercise/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => ExerciseDetailPage(
        machineId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);
