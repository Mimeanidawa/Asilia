import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'pressable_scale.dart';

class TabRailItem {
  const TabRailItem({
    required this.id,
    required this.label,
    required this.icon,
    this.color,
    this.badgeCount,
  });

  final String id;
  final String label;
  final IconData icon;
  final Color? color;
  final int? badgeCount;
}

/// A modern, responsive horizontal tab bar / filter rail.
/// Gives tactile sliding feedback, clear active indicators, and consistent typography.
class ModernTabRail extends StatelessWidget {
  const ModernTabRail({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onSelect,
    this.height = 54,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final List<TabRailItem> items;
  final String selectedId;
  final ValueChanged<String> onSelect;
  final double height;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight),
        ),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = items[i];
          final isSelected = selectedId == item.id;
          final accent = item.color ?? AppColors.forest;

          return PressableScale(
            onTap: () => onSelect(item.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? accent : AppColors.canvas,
                borderRadius: BorderRadius.circular(AppColors.radiusPill),
                border: Border.all(
                  color: isSelected ? accent : AppColors.borderLight,
                  width: 1,
                ),
                boxShadow: isSelected ? AppColors.elevationSm : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 16,
                    color: isSelected ? Colors.white : accent,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: AppTypography.subtitle,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.forest,
                      letterSpacing: 0.1,
                    ),
                  ),
                  if (item.badgeCount != null && item.badgeCount! > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.25)
                            : AppColors.forest.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppColors.radiusPill),
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        style: TextStyle(
                          fontSize: AppTypography.badge,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : AppColors.forest,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
