import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';
import '../utils/category_visual.dart';
import '../utils/safe_text.dart';
import 'darasa_huru_carousel.dart';
import 'herb_image.dart';

/// Clean list row for a Darasa Huru lesson (Twitter/X feed style).
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

    return Material(
      color: AppColors.surfaceElevated,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.forest.withValues(alpha: 0.07),
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 88,
                  height: 88,
                  child: hasImage
                      ? HerbImage(
                          url: lesson.imageUrl,
                          width: 88,
                          height: 88,
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
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: lesson.isToday
                                ? AppColors.amber.withValues(alpha: 0.14)
                                : AppColors.emerald50,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            darasaBadgeLabel(lesson),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: lesson.isToday
                                  ? AppColors.amber
                                  : AppColors.emerald800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            lesson.formattedDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.forest.withValues(alpha: 0.4),
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                        height: 1.25,
                        letterSpacing: -0.25,
                      ),
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.forest.withValues(alpha: 0.55),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: AppColors.forest.withValues(alpha: 0.4),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.forest.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.forest.withValues(alpha: 0.3),
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
