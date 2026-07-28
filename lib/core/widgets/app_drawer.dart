import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// The app's side drawer, opened via the hamburger icon already present on
/// every bottom-nav tab's `AppBar`. Additive to the bottom nav — hosts
/// sections that aren't part of the food-tracking tab bar, currently just
/// Workouts. See docs/WORKOUTS_PLAN.md for why this is a drawer entry
/// rather than a 6th bottom-nav tab.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.background),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Nourish',
                  style: TextStyle(
                    color: AppColors.brandGreen,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.fitness_center),
              title: const Text('Workouts'),
              onTap: () {
                Navigator.of(context).pop();
                context.push('/workouts');
              },
            ),
          ],
        ),
      ),
    );
  }
}
