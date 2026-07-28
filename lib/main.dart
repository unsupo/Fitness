import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/app_lifecycle_refresher.dart';
import 'core/di/backend.dart';
import 'core/di/supabase_backend.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const NourishApp());
}

/// Root widget. Includes its own [ProviderScope] so both `main()` and tests
/// can instantiate `NourishApp()` directly without external wrapping.
class NourishApp extends StatelessWidget {
  const NourishApp({super.key, this.backend});

  /// Injects a [Backend] (e.g. a fake for full-app integration tests).
  /// Defaults to [SupabaseBackend]. Overridden lazily — via `overrideWith`,
  /// not `overrideWithValue` — so `Supabase.instance.client` is only
  /// touched if a provider actually reads [backendProvider]; feature-level
  /// widget tests that override each `xRepositoryProvider` directly never
  /// trigger this and don't need Supabase initialized at all.
  final Backend? backend;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        backendProvider.overrideWith(
          (ref) => backend ?? SupabaseBackend(Supabase.instance.client),
        ),
      ],
      child: AppLifecycleRefresher(
        child: MaterialApp.router(
          title: 'Nourish',
          theme: AppTheme.light(),
          routerConfig: appRouter,
        ),
      ),
    );
  }
}
