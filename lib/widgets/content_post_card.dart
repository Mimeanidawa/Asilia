import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/content_tag_style.dart';
import 'herb_image.dart';
import 'paid_makala_badge.dart';

class ContentPostCard extends StatelessWidget {
  const ContentPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showChevron = true,
    this.showSectionLabel = false,
    this.compact = false,
    this.margin = const EdgeInsets.only(bottom: 16),
    this.animationIndex = 0,
  });

  static const _imageWidth = 112.0;
  static const _imageHeight = 118.0;

  final ContentPost post;
  final VoidCallback onTap;
  final bool showChevron;
  final bool showSectionLabel;
  final bool compact;
  final EdgeInsets margin;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final category = post.category;
    final user = context.watch<UserService>();
    final paid = post.isPremium && user.hasPurchasedContent(post.id);

    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: AppColors.softShadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _imageHeight,
            child: Row(
              children: [
                Stack(
                  children: [
                    HerbImage(
                      url: post.imageUrl,
                      width: _imageWidth,
                      height: _imageHeight,
                      borderRadius: 0,
                    ),
                    if (paid)
                      const Positioned(
                        top: 8,
                        left: 8,
                        child: PaidMakalaBadge(compact: true),
                      )
                    else if (post.isPremium)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 7,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 6, compact ? 8 : 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (showSectionLabel || (category != null && category.isNotEmpty) || paid)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (showSectionLabel ||
                                    (category != null && category.isNotEmpty))
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: ContentTagStyle.colorFor(category ?? '')
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _metaLabel(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: showSectionLabel
                                            ? AppColors.forest.withValues(alpha: 0.65)
                                            : ContentTagStyle.colorFor(category ?? ''),
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ),
                                if (paid) const PaidMakalaBadge(compact: true),
                              ],
                            ),
                          ),
                        Text(
                          post.title,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 13 : 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                            height: 1.15,
                          ),
                        ),
                        if (!compact && post.excerpt.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            post.excerpt,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.gray500,
                              height: 1.25,
                            ),
                          ),
                        ],
                        if (!compact) ...[
                          const SizedBox(height: 4),
                          Text(
                            post.readTimeLabel,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gray400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (showChevron) ...[
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.forest.withValues(alpha: 0.35),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: (animationIndex * 60).ms, duration: 350.ms)
        .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic);
  }

  String _metaLabel() {
    final section = ContentSections.sectionLabel(post.section);
    final category = post.category;
    if (showSectionLabel && category != null && category.isNotEmpty) {
      return '$section · ${ContentTagStyle.displayLabel(category)}';
    }
    if (showSectionLabel) return section;
    if (category != null && category.isNotEmpty) {
      return ContentTagStyle.displayLabel(category);
    }
    return section;
  }
}
