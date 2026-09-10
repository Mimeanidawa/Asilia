import 'dart:ui';

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

/// Large immersive featured article (Jifunze / Makala hero).
class ContentFeaturedCard extends StatelessWidget {
  const ContentFeaturedCard({
    super.key,
    required this.post,
    required this.onTap,
    this.showSectionLabel = false,
    this.height = 300,
  });

  final ContentPost post;
  final VoidCallback onTap;
  final bool showSectionLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final paid = context.watch<UserService>().hasPurchasedContent(post.id);
    final catColor = ContentTagStyle.colorFor(post.category ?? post.section);
    final title = safeDisplayText(post.title);
    final excerpt = safeDisplayText(post.excerpt);
    final hasImage = post.displayImageUrl.trim().isNotEmpty;
    final chip = _chipLabel(post, showSectionLabel);

    return PressableScale(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.14),
              blurRadius: 28,
              offset: const Offset(0, 14),
              spreadRadius: -8,
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                Positioned.fill(
                  child: HerbImage(
                    url: post.displayImageUrl,
                    borderRadius: 0,
                    fullWidth: true,
                    fit: BoxFit.cover,
                    fallbackLabel: title,
                    category: post.category ?? post.section,
                  ),
                )
              else
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: CategoryVisual.gradientFor(
                          post.category ?? post.section,
                        ),
                      ),
                    ),
                  ),
                ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x55000000),
                        Color(0x14000000),
                        Color(0xCC0A1F1A),
                      ],
                      stops: [0, 0.4, 1],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    _GlassLabel(label: chip, accent: catColor),
                    const Spacer(),
                    if (paid)
                      const PaidMakalaBadge(onDark: true)
                    else if (post.isPremium)
                      const _GlassLabel(
                        label: 'Premium',
                        accent: AppColors.amber,
                        filled: true,
                      ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.18,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.86),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Soma makala',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.forest,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.03, curve: Curves.easeOutCubic);
  }
}

/// Clean feed-style article row / grid card.
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

    final card = Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(vertical ? 18 : 0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: vertical
            ? _verticalBody(paid, catColor)
            : _horizontalBody(paid, catColor),
      ),
    );

    return Padding(
      padding: margin,
      child: card
          .animate()
          .fadeIn(delay: (animationIndex * 28).ms, duration: 300.ms)
          .slideY(begin: 0.03, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _horizontalBody(bool paid, Color catColor) {
    final title = safeDisplayText(post.title);
    final excerpt = safeDisplayText(post.excerpt);
    final imageUrl = post.displayImageUrl.trim();
    final hasImage = imageUrl.isNotEmpty;
    final imageSize = compact ? 92.0 : 108.0;

    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 14 : 16, 14, 16, 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.forest.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
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
                        top: 6,
                        left: 6,
                        child: PaidMakalaBadge(compact: true),
                      )
                    else if (post.isPremium)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: _meta(
              paid,
              catColor,
              title: title,
              excerpt: excerpt,
              showThumbBadge: !hasImage,
            ),
          ),
        ],
      ),
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
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HerbImage(
                  url: imageUrl,
                  fullWidth: true,
                  borderRadius: 0,
                  fit: BoxFit.cover,
                  fallbackLabel: title,
                  category: post.category ?? post.section,
                ),
                if (paid)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: PaidMakalaBadge(onDark: true),
                  )
                else if (post.isPremium)
                  const Positioned(
                    top: 10,
                    right: 10,
                    child: _GlassLabel(
                      label: 'Premium',
                      accent: AppColors.amber,
                      filled: true,
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: _meta(
            paid,
            catColor,
            title: title,
            excerpt: excerpt,
            showThumbBadge: false,
          ),
        ),
      ],
    );
  }

  Widget _meta(
    bool paid,
    Color catColor, {
    required String title,
    required String excerpt,
    bool showThumbBadge = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  safeDisplayText(_chipLabel(post, showSectionLabel)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: catColor,
                  ),
                ),
              ),
            ),
            if (showThumbBadge && paid) ...[
              const SizedBox(width: 6),
              const PaidMakalaBadge(compact: true),
            ] else if (showThumbBadge && post.isPremium)
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
            fontSize: compact ? 14.5 : 15.5,
            fontWeight: FontWeight.w800,
            color: AppColors.forest,
            height: 1.25,
            letterSpacing: -0.25,
          ),
        ),
        if (!compact && excerpt.isNotEmpty) ...[
          const SizedBox(height: 5),
          Text(
            excerpt,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.forest.withValues(alpha: 0.55),
              height: 1.35,
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
                fontWeight: FontWeight.w700,
                color: AppColors.emerald700,
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 2),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.emerald700.withValues(alpha: 0.85),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _GlassLabel extends StatelessWidget {
  const _GlassLabel({
    required this.label,
    required this.accent,
    this.filled = false,
  });

  final String label;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: accent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          safeDisplayText(label),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Text(
            safeDisplayText(label),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
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
