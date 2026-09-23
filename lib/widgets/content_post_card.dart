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
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
          boxShadow: AppColors.elevationMd,
        ),
        clipBehavior: Clip.antiAlias,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppColors.radiusXl),
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
                        Color(0x33000000),
                        Color(0x11000000),
                        Color(0xDD071C14),
                      ],
                      stops: [0, 0.45, 1],
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
                left: 20,
                right: 20,
                bottom: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.2,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (excerpt.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        excerpt,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
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
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 15,
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
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.03, curve: Curves.easeOutCubic);
  }
}

/// Clean, sleek modern feed-style article card.
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

    final card = Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          child: vertical
              ? _verticalBody(paid, catColor)
              : _horizontalBody(paid, catColor),
        ),
      ),
    );

    return Padding(
      padding: margin,
      child: PressableScale(
        onTap: onTap,
        child: card,
      )
          .animate()
          .fadeIn(delay: (animationIndex * 24).ms, duration: 280.ms)
          .slideY(begin: 0.02, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _horizontalBody(bool paid, Color catColor) {
    final title = safeDisplayText(post.title);
    final excerpt = safeDisplayText(post.excerpt);
    final imageUrl = post.displayImageUrl.trim();
    final hasImage = imageUrl.isNotEmpty;
    final imageSize = compact ? 86.0 : 96.0;

    return Padding(
      padding: EdgeInsets.all(compact ? 12 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
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
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _chipLabel(post, showSectionLabel).toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: catColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (!hasImage && paid)
                      const PaidMakalaBadge(compact: true)
                    else if (!hasImage && post.isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: AppColors.amber,
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
              ],
            ),
          ),
          if (showChevron)
            const Padding(
              padding: EdgeInsets.only(left: 6, top: 28),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppColors.gray400,
                size: 20,
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
                    left: 10,
                    child: PaidMakalaBadge(),
                  )
                else if (post.isPremium)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.amber,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PREMIUM',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _chipLabel(post, showSectionLabel).toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: catColor,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                  height: 1.25,
                  letterSpacing: -0.2,
                ),
              ),
              if (excerpt.isNotEmpty) ...[
                const SizedBox(height: 6),
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
            ],
          ),
        ),
      ],
    );
  }
}

String _chipLabel(ContentPost post, bool showSectionLabel) {
  if (showSectionLabel && post.section.isNotEmpty) {
    return ContentSections.sectionLabel(post.section);
  }
  if (post.categoryLabel.isNotEmpty) {
    return post.categoryLabel;
  }
  return ContentSections.sectionLabel(post.section);
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: filled ? accent : Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
