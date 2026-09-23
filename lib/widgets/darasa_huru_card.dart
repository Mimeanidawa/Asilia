import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';
import '../utils/category_visual.dart';
import '../utils/safe_text.dart';
import 'darasa_huru_carousel.dart';
import 'herb_image.dart';

/// Clean modern card for a Darasa Huru lesson.
class DarasaHuruCard extends StatelessWidget {
  const DarasaHuruCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  final DailyLesson lesson;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final authorName =
        safeDisplayText(context.watch<MwalimuService>().displayName);
    final title = safeDisplayText(lesson.title);
    final excerpt = safeDisplayText(lesson.excerpt);
    final hasImage = lesson.imageUrl.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppColors.radiusLg),
            border: Border.all(
              color: AppColors.forest.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: AppColors.elevationSm,
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 90,
                  height: 90,
                  child: hasImage
                      ? HerbImage(
                          url: lesson.imageUrl,
                          width: 90,
                          height: 90,
                          borderRadius: 0,
                          fit: BoxFit.cover,
                          fallbackLabel: title,
                          category: 'darasa_huru',
                        )
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors:
                                  CategoryVisual.gradientFor('darasa_huru'),
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white70,
                            size: 28,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: lesson.isToday
                                ? AppColors.amber.withValues(alpha: 0.15)
                                : AppColors.emerald50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            darasaBadgeLabel(lesson).toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: lesson.isToday
                                  ? AppColors.amber
                                  : AppColors.emerald800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lesson.formattedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray400,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 13,
                          color: AppColors.emerald800,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.gray400,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
