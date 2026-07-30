import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

/// Bottom-nav shell: Home / Recipes / [FAB] / Extras / Profile. The center
/// FAB isn't a tab — it opens a quick-add menu (scan a barcode or take a
/// food photo). Recipes has its own tab rather than living only inside that
/// menu, since it's a full browse-and-manage surface, not a one-shot log
/// action — the mockup originally had a literal "Breakfast" tab here, which
/// was redundant with Home (which already shows every meal) and got
/// replaced.
import 'package:arndt_fitness/features/diary/presentation/widgets/quick_add_modal.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// The nav bar has 5 visual slots (Home, Breakfast, [FAB gap], Extras,
  /// Profile) but only 4 real branches — this maps between the two so
  /// tapping "Extras"/"Profile" doesn't land on the wrong branch.
  static const _itemIndexToBranchIndex = [0, 1, -1, 2, 3];
  static const _branchIndexToItemIndex = [0, 1, 3, 4];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        onPressed: () => showQuickAddModal(context),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: AppColors.surface,
        padding: EdgeInsets.zero,
        child: BottomNavigationBar(
          currentIndex: _branchIndexToItemIndex[navigationShell.currentIndex],
          onTap: (itemIndex) {
            final branchIndex = _itemIndexToBranchIndex[itemIndex];
            if (branchIndex >= 0) navigationShell.goBranch(branchIndex);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.accentOrange,
          unselectedItemColor: AppColors.textSecondary,
          elevation: 0,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.menu_book_outlined),
              label: 'Recipes',
            ),
            BottomNavigationBarItem(
              icon: SizedBox.shrink(),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_outlined),
              label: 'Extras',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
