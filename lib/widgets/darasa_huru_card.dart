import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../services/mwalimu_service.dart';
import '../theme/app_colors.dart';
import '../utils/category_visual.dart';
import 'darasa_huru_carousel.dart';
import 'herb_image.dart';

class DarasaHuruCard extends StatelessWidget {
  const DarasaHuruCard({
    super.key,
    required this.lesson,
    required this.onTap,
  });

  final DailyLesson lesson;
  final VoidCallback onTap;

  static const _photoHeight = 196.0;

  @override
  Widget build(BuildContext context) {
    final authorName = context.watch<MwalimuService>().displayName;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: PressableScale(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, 14),
                spreadRadius: -8,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: _photoHeight,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    HerbImage(
                      url: lesson.imageUrl,
                      height: _photoHeight,
                      borderRadius: 0,
                      fullWidth: true,
                      fallbackLabel: lesson.title,
                      category: 'darasa_huru',
                    ),
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: lesson.isToday ? AppColors.amber : AppColors.forest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          darasaBadgeLabel(lesson),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (lesson.topicTag != null) ...[
                      Text(
                        lesson.topicTag!.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.amber,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      lesson.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kIsWeb ? null : 'Playfair Display',
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                        height: 1.2,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (lesson.excerpt.trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        lesson.excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.gray500),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.emerald50,
                          child: const Icon(Icons.person_rounded, size: 16, color: AppColors.emerald800),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authorName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.forest,
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Soma',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                            ],
                          ),
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
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }
}
