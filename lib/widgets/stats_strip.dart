import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

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
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: AppColors.elevationSm,
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
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.03, end: 0);
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        color: AppColors.forest.withValues(alpha: 0.06),
      );

  Widget _stat(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 15, color: AppColors.emerald700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTypography.sectionTitle,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTypography.badge,
              fontWeight: FontWeight.w700,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }
}
