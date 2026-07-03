import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final active = app.activeScreen;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Row(
        children: [
          _NavItem(
            icon: Icons.home_rounded,
            label: 'Nyumbani',
            selected: active == AppScreen.home,
            onTap: () => app.navigate(AppScreen.home),
          ),
          _NavItem(
            icon: Icons.menu_book_rounded,
            label: 'Jifunze',
            selected: active == AppScreen.learn,
            onTap: () => app.navigate(AppScreen.learn),
          ),
          Expanded(
            child: Center(
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Material(
                  color: active == AppScreen.conditions
                      ? AppColors.amber
                      : AppColors.emerald50,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => app.navigate(
                      AppScreen.contentList,
                      contentSection: ContentSections.chaguaMada,
                      contentCategory: 'mimea',
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.eco,
                        color: active == AppScreen.conditions
                            ? Colors.white
                            : AppColors.forest,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _NavItem(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'Uliza',
            selected: active == AppScreen.askExpert,
            onTap: () => app.navigate(AppScreen.askExpert),
          ),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Mtumiaji',
            selected: active == AppScreen.profile,
            onTap: () => app.navigate(AppScreen.profile),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? AppColors.cream : Colors.white.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w500,
                color: selected ? AppColors.cream : Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
