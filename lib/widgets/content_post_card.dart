import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/category_visual.dart';
import '../utils/content_tag_style.dart';
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

  static const _photoHeight = 196.0;

  @override
  Widget build(BuildContext context) {
    final paid = context.watch<UserService>().hasPurchasedContent(post.id);
    final catColor = ContentTagStyle.colorFor(post.category ?? post.section);

    return PressableScale(
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
                    url: post.displayImageUrl,
                    height: _photoHeight,
                    borderRadius: 0,
                    fullWidth: true,
                    fallbackLabel: post.title,
                    category: post.category ?? post.section,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x33000000), Color(0x00000000)],
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
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    maxLines: 3,
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
                  if (post.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      post.excerpt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: AppColors.gray500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
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
    ).animate().fadeIn(duration: 420.ms).slideY(begin: 0.04, curve: Curves.easeOutCubic);
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
    this.margin = const EdgeInsets.only(bottom: 16),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.forest.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
              spreadRadius: -6,
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
          .fadeIn(delay: (animationIndex * 45).ms, duration: 360.ms)
          .slideY(begin: 0.045, end: 0, curve: Curves.easeOutCubic),
    );
  }

  Widget _horizontalBody(bool paid, Color catColor) {
    final imageSize = compact ? 88.0 : 108.0;
    return Padding(
      padding: EdgeInsets.all(compact ? 10 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              HerbImage(
                url: post.displayImageUrl,
                width: imageSize,
                height: imageSize,
                borderRadius: 16,
                fallbackLabel: post.title,
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Text(
                      'PRO',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: compact ? 10 : 14),
          Expanded(child: _meta(paid, catColor)),
        ],
      ),
    );
  }

  Widget _verticalBody(bool paid, Color catColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HerbImage(
          url: post.displayImageUrl,
          height: 148,
          fullWidth: true,
          borderRadius: 0,
          fallbackLabel: post.title,
          category: post.category ?? post.section,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: _meta(paid, catColor),
        ),
      ],
    );
  }

  Widget _meta(bool paid, Color catColor) {
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _chipLabel(post, showSectionLabel),
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
                child: Icon(Icons.lock_rounded, size: 14, color: AppColors.amber.withValues(alpha: 0.9)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          post.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: compact ? 13.5 : 15,
            fontWeight: FontWeight.w800,
            color: AppColors.forest,
            height: 1.22,
            letterSpacing: -0.2,
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
        const SizedBox(height: 10),
        Row(
          children: [
            Text(
              'Soma',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.emerald700,
              ),
            ),
            if (showChevron) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.arrow_forward_rounded,
                size: 15,
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
        color: filled ? color : Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.6,
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
