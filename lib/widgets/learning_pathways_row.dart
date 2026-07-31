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
        height: 128,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: gutter + 4),
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
          childAspectRatio: 1.35,
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
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: pathway.onTap,
        child: Ink(
          width: expanded ? null : 152,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: pathway.gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: pathway.gradient.first.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(pathway.icon, color: Colors.white, size: 20),
                    ),
                    const Spacer(),
                    if (pathway.count != null && pathway.count! > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${pathway.count}',
                          style: const TextStyle(
                            fontSize: 10,
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
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pathway.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (animationIndex * 70).ms, duration: 400.ms)
        .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.forest.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: AppColors.softShadow,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
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
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05, end: 0);
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: AppColors.forest.withValues(alpha: 0.08),
      );

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: AppColors.emerald700),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: AppColors.gray500,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
