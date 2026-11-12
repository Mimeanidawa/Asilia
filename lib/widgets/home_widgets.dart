import 'package:flutter/material.dart';

import '../models/content_models.dart';
import '../models/product_models.dart';
import '../theme/app_colors.dart';
import '../utils/safe_text.dart';
import '../utils/tzs_format.dart';
import 'herb_image.dart';
import 'pressable_scale.dart';

/// Number of columns for card grids, based on available width.
int homeGridColumns(double width) {
  if (width >= 840) return 4;
  if (width >= 560) return 3;
  return 2;
}

// ─────────────────────────────────────────────────────────────────────────────
// Featured Asili — two-column grid of herb / article cards
// ─────────────────────────────────────────────────────────────────────────────

class FeaturedAsiliGrid extends StatelessWidget {
  const FeaturedAsiliGrid({
    super.key,
    required this.posts,
    required this.onOpen,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final List<ContentPost> posts;
  final void Function(ContentPost post) onOpen;
  final EdgeInsets padding;

  static const double _gap = 12;
  static const double _textHeight = 72;

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = homeGridColumns(constraints.maxWidth);
          final cardW = (constraints.maxWidth - _gap * (cols - 1)) / cols;
          final imageH = cardW * 0.84;
          final cardH = imageH + _textHeight;
          final shown = posts.take(cols * 2).toList();

          return Wrap(
            spacing: _gap,
            runSpacing: _gap,
            children: [
              for (final post in shown)
                SizedBox(
                  width: cardW,
                  height: cardH,
                  child: _FeaturedCard(
                    post: post,
                    imageHeight: imageH,
                    textHeight: _textHeight,
                    onTap: () => onOpen(post),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  const _FeaturedCard({
    required this.post,
    required this.imageHeight,
    required this.textHeight,
    required this.onTap,
  });

  final ContentPost post;
  final double imageHeight;
  final double textHeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = safeDisplayText(post.title);
    final label = post.categoryLabel.isNotEmpty
        ? post.categoryLabel
        : ContentSections.sectionLabel(post.section);

    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
          boxShadow: AppColors.elevationSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: imageHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HerbImage(
                    url: post.displayImageUrl,
                    borderRadius: 0,
                    fullWidth: true,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    fallbackLabel: title,
                    category: post.category ?? post.section,
                  ),
                  if (post.isPremium)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
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
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                        height: 1.2,
                        letterSpacing: -0.15,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.brand.withValues(alpha: 0.12),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_rounded,
                            size: 12,
                            color: AppColors.brand,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category strip — compact horizontal icons
// ─────────────────────────────────────────────────────────────────────────────

class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.section,
    required this.color,
  });

  final String id;
  final String label;
  final IconData icon;
  final String section;
  final Color color;
}

const homeCategories = <HomeCategory>[
  HomeCategory(
    id: 'mimea',
    label: 'Mimea ya Dawa',
    icon: Icons.spa_rounded,
    section: ContentSections.dodoso,
    color: Color(0xFF1F7A4D),
  ),
  HomeCategory(
    id: 'miti',
    label: 'Miti & Magome',
    icon: Icons.park_rounded,
    section: ContentSections.dodoso,
    color: Color(0xFF2F6B4F),
  ),
  HomeCategory(
    id: 'mizizi',
    label: 'Mizizi ya Tiba',
    icon: Icons.grass_rounded,
    section: ContentSections.dodoso,
    color: Color(0xFF7A5A2E),
  ),
  HomeCategory(
    id: 'matunda',
    label: 'Matunda',
    icon: Icons.apple_rounded,
    section: ContentSections.vyakulaMatunda,
    color: Color(0xFFC4622D),
  ),
  HomeCategory(
    id: 'vyakula',
    label: 'Vyakula & Viungo',
    icon: Icons.restaurant_rounded,
    section: ContentSections.vyakulaMatunda,
    color: Color(0xFF2E7A9B),
  ),
  HomeCategory(
    id: 'lishe',
    label: 'Lishe & Uzima',
    icon: Icons.eco_rounded,
    section: ContentSections.vyakulaMatunda,
    color: Color(0xFF3C8F6A),
  ),
  HomeCategory(
    id: 'wanawake',
    label: 'Afya ya Wanawake',
    icon: Icons.favorite_rounded,
    section: ContentSections.chaguaMada,
    color: Color(0xFFB54563),
  ),
  HomeCategory(
    id: 'watoto',
    label: 'Afya ya Watoto',
    icon: Icons.child_care_rounded,
    section: ContentSections.chaguaMada,
    color: Color(0xFF3E7591),
  ),
  HomeCategory(
    id: 'wanaume',
    label: 'Afya ya Wanaume',
    icon: Icons.fitness_center_rounded,
    section: ContentSections.chaguaMada,
    color: Color(0xFF2E4E68),
  ),
];

class HomeCategoryStrip extends StatelessWidget {
  const HomeCategoryStrip({super.key, required this.onSelect});

  final void Function(HomeCategory category) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 98,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: homeCategories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final cat = homeCategories[i];
          return PressableScale(
            onTap: () => onSelect(cat),
            child: SizedBox(
              width: 74,
              child: Column(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: cat.color.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(cat.icon, size: 26, color: cat.color),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    cat.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10.5,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dawa shelf — compact product cards
// ─────────────────────────────────────────────────────────────────────────────

class DawaProductShelf extends StatelessWidget {
  const DawaProductShelf({
    super.key,
    required this.products,
    required this.onBuy,
  });

  final List<DawaProduct> products;
  final void Function(DawaProduct product) onBuy;

  static const double cardWidth = 166;
  static const double imageHeight = 140;
  static const double height = 250;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        clipBehavior: Clip.none,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
        itemCount: products.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _ProductCard(
          product: products[i],
          onBuy: () => onBuy(products[i]),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.product, required this.onBuy});

  final DawaProduct product;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final hasDiscount = p.originalPrice > p.price;
    final pct = p.discountPercent > 0
        ? p.discountPercent
        : (hasDiscount
            ? (((p.originalPrice - p.price) / p.originalPrice) * 100).round()
            : 0);

    return PressableScale(
      onTap: onBuy,
      child: Container(
        width: DawaProductShelf.cardWidth,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
          boxShadow: AppColors.elevationSm,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: DawaProductShelf.imageHeight,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HerbImage(
                    url: p.imageUrl,
                    borderRadius: 0,
                    fullWidth: true,
                    height: DawaProductShelf.imageHeight,
                    fit: BoxFit.cover,
                  ),
                  if (hasDiscount && pct > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.red600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '-$pct%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      p.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.forest,
                        height: 1.2,
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (hasDiscount)
                                Text(
                                  TzsFormat.full(p.originalPrice),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.forest
                                        .withValues(alpha: 0.4),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  TzsFormat.full(p.price),
                                  style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.brand,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            size: 18,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
