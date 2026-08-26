import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/category_visual.dart';
import '../utils/content_tag_style.dart';
import '../utils/safe_text.dart';
import 'herb_image.dart';
import 'paid_makala_badge.dart';

class ContentFeaturedCard extends StatelessWidget {
  const ContentFeaturedCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showSectionLabel = false,
  });

  final ContentPost post;
  final VoidCallback onTap;
  final bool showSectionLabel;

  static const _photoHeight = 228.0;

  @override
  Widget build(BuildContext context) {
    final paid = context.watch<UserService>().hasPurchasedContent(post.id);
    final catColor = ContentTagStyle.colorFor(post.category ?? post.section);
    final title = safeDisplayText(post.title);
    final excerpt = safeDisplayText(post.excerpt);

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppColors.elevationLg,
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
                    url: post.displayImageUrl,
                    height: _photoHeight,
                    borderRadius: 0,
                    fullWidth: true,
                    fallbackLabel: title,
                    category: post.category ?? post.section,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0x00000000),
                          Color(0x73000000),
                        ],
                        stops: [0, 0.4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _OverlayChip(
                      label: _chipLabel(post, showSectionLabel),
                      color: catColor,
                    ),
                  ),
                  if (paid)
                    const Positioned(
                      top: 14,
                      right: 14,
                      child: PaidMakalaBadge(onDark: true),
                    )
                  else if (post.isPremium)
                    const Positioned(
                      top: 14,
                      right: 14,
                      child: _OverlayChip(
                        label: 'PREMIUM',
                        color: AppColors.amber,
                        filled: true,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: AppColors.forest,
                      height: 1.22,
                      letterSpacing: -0.45,
                    ),
                  ),
                  if (excerpt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: AppColors.gray500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _SomaPill(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.04, curve: Curves.easeOutCubic);
  }
}

class ContentPostCard extends StatelessWidget {
  const ContentPostCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showChevron = true,
    this.showSectionLabel = false,
    this.compact = false,
    this.vertical = false,
    this.margin = const EdgeInsets.only(bottom: 12),
    this.animationIndex = 0,
  });

  final ContentPost post;
  final VoidCallback onTap;
  final bool showChevron;
  final bool showSectionLabel;
  final bool compact;
  final bool vertical;
  final EdgeInsets margin;
  final int animationIndex;

  @override
  Widget build(BuildContext context) {
    final paid = context.watch<UserService>().hasPurchasedContent(post.id);
    final catColor = ContentTagStyle.colorFor(post.category ?? post.section);

    final card = PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.07),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: vertical ? _verticalBody(paid, catColor) : _horizontalBody(paid, catColor),
      ),
    );

    return Padding(
      padding: margin,
      child: card
          .animate()
          .fadeIn(delay: (animationIndex * 30).ms, duration: 320.ms)
          .slideY(begin: 0.04, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _horizontalBody(bool paid, Color catColor) {
    final title = safeDisplayText(post.title);
    final excerpt = safeDisplayText(post.excerpt);
    final imageUrl = post.displayImageUrl.trim();
    final hasImage = imageUrl.isNotEmpty;

    if (!hasImage) {
      return Padding(
        padding: EdgeInsets.fromLTRB(compact ? 12 : 14, 12, 14, 12),
        child: _meta(paid, catColor, title: title, excerpt: excerpt),
      );
    }

    final imageSize = compact ? 104.0 : 120.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: imageSize,
          height: imageSize,
          child: Stack(
            fit: StackFit.expand,
            children: [
              HerbImage(
                url: imageUrl,
                width: imageSize,
                height: imageSize,
                borderRadius: 0,
                fit: BoxFit.cover,
                fallbackLabel: title,
                category: post.category ?? post.section,
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
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(compact ? 12 : 14, 10, 14, 10),
            child: _meta(paid, catColor, title: title, excerpt: excerpt),
          ),
        ),
      ],
    );
  }

  Widget _verticalBody(bool paid, Color catColor) {
    final title = safeDisplayText(post.title);
    final excerpt = safeDisplayText(post.excerpt);
    final imageUrl = post.displayImageUrl.trim();
    final hasImage = imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasImage)
          HerbImage(
            url: imageUrl,
            height: 168,
            fullWidth: true,
            borderRadius: 0,
            fit: BoxFit.cover,
            fallbackLabel: title,
            category: post.category ?? post.section,
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: _meta(paid, catColor, title: title, excerpt: excerpt),
        ),
      ],
    );
  }

  Widget _meta(
    bool paid,
    Color catColor, {
    required String title,
    required String excerpt,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  safeDisplayText(_chipLabel(post, showSectionLabel)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: catColor,
                  ),
                ),
              ),
            ),
            if (paid) ...[
              const SizedBox(width: 6),
              const PaidMakalaBadge(compact: true),
            ] else if (post.isPremium)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.lock_rounded,
                  size: 14,
                  color: AppColors.amber.withValues(alpha: 0.9),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w800,
            color: AppColors.forest,
            height: 1.28,
            letterSpacing: -0.2,
          ),
        ),
        if (!compact && excerpt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            excerpt,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.gray500,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Soma',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.emerald700,
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 3),
              Icon(
                Icons.arrow_forward_rounded,
                size: 14,
                color: AppColors.emerald700.withValues(alpha: 0.9),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SomaPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.forest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Soma',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 6),
          Icon(Icons.arrow_forward_rounded, size: 15, color: Colors.white),
        ],
      ),
    );
  }
}

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? color : Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        safeDisplayText(label).toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: filled ? Colors.white : color,
        ),
      ),
    );
  }
}

String _chipLabel(ContentPost post, bool showSection) {
  final section = ContentSections.sectionLabel(post.section);
  final category = post.categoryLabel;
  if (showSection && category.isNotEmpty) return '$section · $category';
  if (showSection) return section;
  if (category.isNotEmpty) return category;
  return section;
}
