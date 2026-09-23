import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';

/// Ultra-modern floating navigation dock for primary destinations.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  static const double barHeight = 62;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final mwalimu = context.watch<MwalimuService>();
    final active = app.activeScreen;
    final ulizaUnread = active == AppScreen.askExpert ? 0 : mwalimu.unreadCount;
    final isExploreActive =
        active == AppScreen.contentList || active == AppScreen.conditions;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.forest.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: AppColors.navShadow,
        ),
        padding: EdgeInsets.fromLTRB(6, 6, 6, 6 + (bottomInset > 0 ? 2 : 0)),
        child: SizedBox(
          height: barHeight,
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
                icon: Icons.menu_book_outlined,
                selectedIcon: Icons.menu_book_rounded,
                label: 'Jifunze',
                selected: active == AppScreen.learn,
                onTap: () => app.navigate(AppScreen.learn),
              ),
              _NavItem(
                icon: Icons.spa_outlined,
                selectedIcon: Icons.spa_rounded,
                label: 'Makala',
                selected: isExploreActive,
                onTap: () {
                  app.selectedContentCategory = null;
                  app.navigate(
                    AppScreen.contentList,
                    contentSection: ContentSections.allMakala,
                  );
                },
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
    final activeColor = AppColors.forest;
    final inactiveColor = AppColors.gray500;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected ? AppColors.emerald50 : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedScale(
                    scale: selected ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      selected ? selectedIcon : icon,
                      size: 22,
                      color: selected ? activeColor : inactiveColor,
                    ),
                  ),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        decoration: BoxDecoration(
                          color: AppColors.amber,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  color: selected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
