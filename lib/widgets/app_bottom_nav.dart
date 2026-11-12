import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';

/// Full-width bottom bar with a raised centre action (Makala hub).
///
/// Layout: [Nyumbani] [Dawa] [ (Makala FAB) ] [Uliza] [Akaunti]
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static const double barHeight = 64;
  static const double fabSize = 58;
  static const double fabLift = 22;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final mwalimu = context.watch<MwalimuService>();
    final active = app.activeScreen;
    final ulizaUnread = active == AppScreen.askExpert ? 0 : mwalimu.unreadCount;
    final isExploreActive = active == AppScreen.contentList ||
        active == AppScreen.conditions ||
        active == AppScreen.learn;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    void openMakala() {
      app.selectedContentCategory = null;
      app.navigate(
        AppScreen.contentList,
        contentSection: ContentSections.allMakala,
      );
    }

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: barHeight + fabLift + bottomInset,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: barHeight + bottomInset,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.forest.withValues(alpha: 0.10),
                      blurRadius: 24,
                      offset: const Offset(0, -6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.home_outlined,
                        selectedIcon: Icons.home_rounded,
                        label: 'Nyumbani',
                        selected: active == AppScreen.home,
                        onTap: () => app.navigate(AppScreen.home),
                      ),
                      _NavItem(
                        icon: Icons.medication_liquid_outlined,
                        selectedIcon: Icons.medication_liquid_rounded,
                        label: 'Dawa',
                        selected: active == AppScreen.dawaShop,
                        onTap: () => app.navigate(AppScreen.dawaShop),
                      ),
                      // Centre slot: label only, the FAB floats above it.
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: openMakala,
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Makala',
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  letterSpacing: -0.1,
                                  fontWeight: isExploreActive
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: isExploreActive
                                      ? AppColors.brand
                                      : AppColors.gray500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      _NavItem(
                        icon: Icons.chat_bubble_outline_rounded,
                        selectedIcon: Icons.chat_bubble_rounded,
                        label: 'Uliza',
                        selected: active == AppScreen.askExpert,
                        badgeCount: ulizaUnread,
                        onTap: () => app.navigate(AppScreen.askExpert),
                      ),
                      _NavItem(
                        icon: Icons.person_outline_rounded,
                        selectedIcon: Icons.person_rounded,
                        label: 'Akaunti',
                        selected: active == AppScreen.profile,
                        onTap: () => app.navigate(AppScreen.profile),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: _CenterFab(active: isExploreActive, onTap: openMakala),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterFab extends StatelessWidget {
  const _CenterFab({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: active ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Container(
          width: AppBottomNav.fabSize,
          height: AppBottomNav.fabSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.brandGradient,
            border: Border.all(color: AppColors.surfaceElevated, width: 4.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: 0.38),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.brand : AppColors.gray500;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: 46,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.brand.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    selected ? selectedIcon : icon,
                    size: 22,
                    color: color,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -3,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                letterSpacing: -0.1,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
