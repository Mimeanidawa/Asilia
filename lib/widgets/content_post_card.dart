import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../theme/app_colors.dart';
import '../utils/content_tag_style.dart';
import 'herb_image.dart';

class ContentPostCard extends StatelessWidget {
  const ContentPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showChevron = true,
    this.showSectionLabel = false,
    this.compact = false,
    this.margin = const EdgeInsets.only(bottom: 16),
  });

  static const _imageWidth = 168.0;
  static const _imageHeight = 128.0;

  final ContentPost post;
  final VoidCallback onTap;
  final bool showChevron;
  final bool showSectionLabel;
  final bool compact;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final category = post.category;

    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: _imageHeight,
            child: Row(
              children: [
                HerbImage(
                  url: post.imageUrl,
                  width: _imageWidth,
                  height: _imageHeight,
                  borderRadius: 0,
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(14, compact ? 10 : 14, 8, compact ? 10 : 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (post.isPremium)
                          Container(
                            margin: EdgeInsets.only(bottom: compact ? 4 : 6),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'PREMIUM TZS ${post.price}',
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: AppColors.amber,
                              ),
                            ),
                          ),
                        if (showSectionLabel || (category != null && category.isNotEmpty))
                          Padding(
                            padding: EdgeInsets.only(bottom: compact ? 4 : 6),
                            child: Text(
                              _metaLabel(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: showSectionLabel
                                    ? AppColors.forest.withValues(alpha: 0.55)
                                    : ContentTagStyle.colorFor(category ?? ''),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        Text(
                          post.title,
                          maxLines: compact ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 14 : 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                            height: 1.2,
                          ),
                        ),
                        if (!compact && post.excerpt.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            post.excerpt,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.gray500,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (showChevron) ...[
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.gray400,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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
