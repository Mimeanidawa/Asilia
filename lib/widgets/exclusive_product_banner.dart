import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/product_models.dart';
import '../services/dawa_order_service.dart';
import '../utils/tzs_format.dart';
import 'herb_image.dart';
import 'order_product_sheet.dart';
import 'pressable_scale.dart';

class ExclusiveProductBanner extends StatelessWidget {
  const ExclusiveProductBanner({
    super.key,
    this.post,
    this.customProduct,
    this.condition,
    this.titleOverride,
    this.subtitleOverride,
    this.margin,
    this.isCompact = false,
    this.onClose,
  });

  final ContentPost? post;
  final DawaProduct? customProduct;
  final dynamic condition;
  final String? titleOverride;
  final String? subtitleOverride;
  final EdgeInsetsGeometry? margin;
  final bool isCompact;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final orderService = context.watch<DawaOrderService>();
    final product = customProduct ??
        (condition != null
            ? orderService.getProductForCondition(condition)
            : orderService.getProductForPost(post));

    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF062319),
            Color(0xFF0F4C3A),
            Color(0xFF133E30),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C3A).withValues(alpha: 0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Ambient 3D lighting glow
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.18),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Exclusive Badge & 50% Off Tag
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 14),
                            SizedBox(width: 5),
                            Text(
                              'EXCLUSIVE PRODUCT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onClose != null) ...[
                            InkWell(
                              onTap: onClose,
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.keyboard_arrow_up_rounded, size: 14, color: Colors.white),
                                    SizedBox(width: 2),
                                    Text(
                                      'Ficha',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              product.badgeText,
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Title: "Nunua Dawa Hii"
                  Text(
                    titleOverride ?? 'Nunua Dawa Hii ya Asili',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.3,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitleOverride ??
                        'Tiba iliyothibitishwa — Nunua sasa kwa punguzo la hadi 50%!',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Colors.white.withValues(alpha: 0.85),
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3D Product Container Box
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 3D Medicine Thumbnail
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: HerbImage(
                              url: product.imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              if (product.subtitle.isNotEmpty) ...[
                                const SizedBox(height: 3),
                                Text(
                                  product.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              // Price Tag
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      TzsFormat.full(product.price),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF6EE7B7), // Emerald neon light
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      TzsFormat.full(product.originalPrice),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.5),
                                        decoration: TextDecoration.lineThrough,
                                        decorationColor: const Color(0xFFEF4444),
                                      ),
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

                  // Key Benefits List
                  if (product.benefits.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ...product.benefits.take(3).map(
                          (benefit) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF10B981),
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 11,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    benefit,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],

                  const SizedBox(height: 16),

                  // Big 3D "Nunua Dawa Hii Sasa" CTA Button
                  PressableScale(
                    onTap: () => OrderProductSheet.show(context, product),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF10B981),
                            Color(0xFF059669),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.45),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_checkout_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Nunua Dawa Hii Sasa (Punguzo 50%)',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Trust Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildTrustBadge(Icons.verified_rounded, '100% Asilia'),
                      _buildTrustBadge(Icons.local_shipping_rounded, 'Mikoani Tanzania'),
                      _buildTrustBadge(Icons.receipt_long_rounded, 'Risiti ya Papo hapo'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustBadge(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: const Color(0xFF6EE7B7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Floating sticky bar pinned to bottom of Makala reader for instant checkout
class StickyMakalaBuyBar extends StatelessWidget {
  const StickyMakalaBuyBar({
    super.key,
    required this.product,
    this.onTap,
    this.onChatWithAdmin,
    this.buttonLabel,
    this.buttonIcon,
    this.isExpanded = false,
  });

  final DawaProduct product;
  final VoidCallback? onTap;
  final VoidCallback? onChatWithAdmin;
  final String? buttonLabel;
  final IconData? buttonIcon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF062319).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Thumbnail
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: HerbImage(url: product.imageUrl, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '-50%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        TzsFormat.full(product.price),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF6EE7B7),
                        ),
                      ),
                      if (product.originalPrice > product.price) ...[
                        const SizedBox(width: 6),
                        Text(
                          TzsFormat.full(product.originalPrice),
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.white.withValues(alpha: 0.5),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          PressableScale(
            onTap: onTap ?? () => OrderProductSheet.show(context, product),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    buttonIcon ??
                        (isExpanded
                            ? Icons.shopping_bag_outlined
                            : Icons.keyboard_arrow_up_rounded),
                    color: Colors.white,
                    size: 15,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    buttonLabel ?? (isExpanded ? 'Agiza Sasa' : 'Nunua Dawa'),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
