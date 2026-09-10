import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../utils/responsive.dart';

class LearningPathway {
  const LearningPathway({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.onTap,
    this.count,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;
  final int? count;
}

class LearningPathwaysRow extends StatelessWidget {
  const LearningPathwaysRow({super.key, required this.pathways});

  final List<LearningPathway> pathways;

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.pathwayColumns(context);
    final gutter = Responsive.horizontalGutter(context);

    if (columns == 1) {
      return SizedBox(
        height: 138,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: gutter),
          itemCount: pathways.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, i) => _PathwayCard(
            pathway: pathways[i],
            animationIndex: i,
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
        ),
        itemCount: pathways.length,
        itemBuilder: (context, i) => _PathwayCard(
          pathway: pathways[i],
          expanded: true,
          animationIndex: i,
        ),
      ),
    );
  }
}

class _PathwayCard extends StatelessWidget {
  const _PathwayCard({
    required this.pathway,
    this.expanded = false,
    this.animationIndex = 0,
  });

  final LearningPathway pathway;
  final bool expanded;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(AppColors.radiusLg),
      clipBehavior: Clip.antiAlias,
      color: Colors.transparent,
      child: InkWell(
        onTap: pathway.onTap,
        child: Ink(
          width: expanded ? null : 158,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pathway.gradient,
            ),
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            boxShadow: [
              BoxShadow(
                color: pathway.gradient.first.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(pathway.icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    if (pathway.count != null && pathway.count! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pathway.count}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const Spacer(),
                Text(
                  pathway.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pathway.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.86),
                    height: 1.25,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (animationIndex * 60).ms, duration: 420.ms)
        .slideX(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
  }
}

class StatsStrip extends StatelessWidget {
  const StatsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    final content = context.watch<ContentService>();
    final lessons = context.watch<AppProvider>().lessonService.publishedLessons.length;
    final dodoso = content.dodosoPosts.length;
    final mada = content.chaguaMadaPosts.length;
    final makala = content.allMakalaPosts.length;

    if (dodoso == 0 && mada == 0 && makala == 0) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.forest.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            _stat('$dodoso', 'Dodoso', Icons.grass_rounded),
            _divider(),
            _stat('$mada', 'Mada', Icons.category_rounded),
            _divider(),
            _stat('$makala', 'Makala', Icons.article_rounded),
            _divider(),
            _stat('$lessons', 'Masomo', Icons.school_rounded),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.04, end: 0);
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: AppColors.forest.withValues(alpha: 0.06),
      );

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: AppColors.emerald700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
