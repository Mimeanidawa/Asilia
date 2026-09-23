import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/category_visual.dart';
import 'modern_tab_rail.dart';
import 'pressable_scale.dart';
import 'section_header.dart';

class _CategoryItemData {
  const _CategoryItemData({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.group,
    required this.section,
    required this.gradient,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String group;
  final String section;
  final List<Color> gradient;
}

/// Unified, clean Category Center grouping all app categories into intuitive clusters.
class GroupedCategoryHub extends StatefulWidget {
  const GroupedCategoryHub({super.key});

  @override
  State<GroupedCategoryHub> createState() => _GroupedCategoryHubState();
}

class _GroupedCategoryHubState extends State<GroupedCategoryHub> {
  String _activeGroup = 'zote';

  static const _groups = [
    TabRailItem(id: 'zote', label: 'Zote', icon: Icons.grid_view_rounded),
    TabRailItem(id: 'dawa', label: 'Mimea & Dawa', icon: Icons.spa_rounded),
    TabRailItem(id: 'lishe', label: 'Vyakula & Lishe', icon: Icons.restaurant_rounded),
    TabRailItem(id: 'jamii', label: 'Afya ya Jamii', icon: Icons.people_alt_rounded),
  ];

  static const _allCategories = [
    // Group: Mimea & Dawa za Asili
    _CategoryItemData(
      id: 'mimea',
      label: 'Mimea ya Dawa',
      subtitle: 'Mimea asili yenye tiba thabiti',
      icon: Icons.spa_rounded,
      group: 'dawa',
      section: ContentSections.dodoso,
      gradient: [Color(0xFF0F4C3A), Color(0xFF1E755B)],
    ),
    _CategoryItemData(
      id: 'miti',
      label: 'Miti & Magome',
      subtitle: 'Miti ya asili na faida zake',
      icon: Icons.park_rounded,
      group: 'dawa',
      section: ContentSections.dodoso,
      gradient: [Color(0xFF1E3A2F), Color(0xFF144D3A)],
    ),
    _CategoryItemData(
      id: 'mizizi',
      label: 'Mizizi ya Tiba',
      subtitle: 'Mizizi yenye nguvu ya asili',
      icon: Icons.grass_rounded,
      group: 'dawa',
      section: ContentSections.dodoso,
      gradient: [Color(0xFF19533F), Color(0xFF267D5F)],
    ),

    // Group: Vyakula & Lishe Bora
    _CategoryItemData(
      id: 'matunda',
      label: 'Matunda ya Asili',
      subtitle: 'Kinga na vitamini asilia',
      icon: Icons.apple_rounded,
      group: 'lishe',
      section: ContentSections.vyakulaMatunda,
      gradient: [Color(0xFF8F5530), Color(0xFFB86B38)],
    ),
    _CategoryItemData(
      id: 'vyakula',
      label: 'Vyakula & Viungo',
      subtitle: 'Mlo na viungo vya uponyaji',
      icon: Icons.restaurant_rounded,
      group: 'lishe',
      section: ContentSections.vyakulaMatunda,
      gradient: [Color(0xFF28546A), Color(0xFF3B7B9B)],
    ),
    _CategoryItemData(
      id: 'lishe',
      label: 'Lishe & Uzima',
      subtitle: 'Mwongozo wa lishe bora',
      icon: Icons.eco_rounded,
      group: 'lishe',
      section: ContentSections.vyakulaMatunda,
      gradient: [Color(0xFF1F5C4A), Color(0xFF2F856B)],
    ),

    // Group: Afya ya Jamii
    _CategoryItemData(
      id: 'wanawake',
      label: 'Afya ya Wanawake',
      subtitle: 'Uzazi na ustawi wa mama',
      icon: Icons.favorite_rounded,
      group: 'jamii',
      section: ContentSections.chaguaMada,
      gradient: [Color(0xFF8A3048), Color(0xFFB54563)],
    ),
    _CategoryItemData(
      id: 'watoto',
      label: 'Afya ya Watoto',
      subtitle: 'Kinga na malezi ya mtoto',
      icon: Icons.child_care_rounded,
      group: 'jamii',
      section: ContentSections.chaguaMada,
      gradient: [Color(0xFF2A5368), Color(0xFF3E7591)],
    ),
    _CategoryItemData(
      id: 'wanaume',
      label: 'Afya ya Wanaume',
      subtitle: 'Nguvu na afya ya mwanaume',
      icon: Icons.fitness_center_rounded,
      group: 'jamii',
      section: ContentSections.chaguaMada,
      gradient: [Color(0xFF1E3547), Color(0xFF2E4E68)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final content = context.watch<ContentService>();

    final filtered = _activeGroup == 'zote'
        ? _allCategories
        : _allCategories.where((c) => c.group == _activeGroup).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Gundua kwa Makundi',
          subtitle: 'Gusa kundi unalotaka kujifunza leo',
          actionLabel: 'Makala Zote',
          onAction: () {
            app.selectedContentCategory = null;
            app.navigate(AppScreen.contentList, contentSection: ContentSections.allMakala);
          },
        ),
        ModernTabRail(
          items: _groups,
          selectedId: _activeGroup,
          onSelect: (id) => setState(() => _activeGroup = id),
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 540;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 3 : 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: isWide ? 1.6 : 1.35,
                ),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final cat = filtered[i];
                  final count = content.countForCategory(cat.id);
                  return _CategoryCard(
                    category: cat,
                    count: count,
                    onTap: () {
                      app.navigate(
                        AppScreen.contentList,
                        contentSection: cat.section,
                        contentCategory: cat.id,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.count,
    required this.onTap,
  });

  final _CategoryItemData category;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppColors.elevationSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: category.gradient,
                    ),
                    borderRadius: BorderRadius.circular(AppColors.radiusMd),
                    boxShadow: [
                      BoxShadow(
                        color: category.gradient.first.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                if (count > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(AppColors.radiusPill),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                        fontSize: AppTypography.badge,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                      ),
                    ),
                  ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTypography.cardTitle,
                    fontWeight: FontWeight.w800,
                    color: AppColors.forest,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  category.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: AppTypography.caption,
                    color: AppColors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
