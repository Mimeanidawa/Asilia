import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/product_models.dart';
import '../providers/app_provider.dart';
import '../services/dawa_order_service.dart';
import '../utils/dawa_purchase_helper.dart';
import '../utils/disease_extractor.dart';
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
            ? orderService.findProductForCondition(condition)
            : orderService.findProductForPost(post));

    final topic = DiseaseExtractor.extractTopic(
      post?.title ?? (titleOverride ?? ''),
      post?.category,
    );

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
                  // Top Row: Exclusive Badge & Badge/Pill Tag
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
                              gradient: LinearGradient(
                                colors: product != null
                                    ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                    : [const Color(0xFF10B981), const Color(0xFF059669)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: (product != null ? const Color(0xFFEF4444) : const Color(0xFF10B981))
                                      .withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              product != null ? product.badgeText : 'AGIZA KWA MWALIMU 💬',
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

                  // Title: Contextual Title
                  Text(
                    titleOverride ??
                        (product != null ? 'Nunua Dawa Hii ya Asili' : 'Nunua Dawa ya $topic'),
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
                        (product != null
                            ? 'Tiba iliyothibitishwa — Nunua sasa kwa punguzo la hadi 50%!'
                            : 'Tiba asili iliyothibitishwa — Agiza sasa moja kwa moja kwa Mwalimu.'),
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
                            color: const Color(0xFF062319),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product != null
                                ? HerbImage(
                                    url: product.imageUrl,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : (post?.displayImageUrl.isNotEmpty == true
                                    ? HerbImage(
                                        url: post!.displayImageUrl,
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      )
                                    : const Center(
                                        child: Icon(
                                          Icons.local_pharmacy_rounded,
                                          color: Color(0xFF34D399),
                                          size: 38,
                                        ),
                                      )),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product != null ? product.title : 'Dawa Asili ya $topic',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                product != null && product.subtitle.isNotEmpty
                                    ? product.subtitle
                                    : 'Mchanganyiko maalum wa mitishamba na mizizi asilia',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Price Tag or Status Tag
                              if (product != null)
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
                                      if (product.originalPrice > product.price) ...[
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
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.18),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFF34D399).withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, size: 12, color: Color(0xFF6EE7B7)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Dawa Asili 100% • Agiza Hapa',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF6EE7B7),
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
                  const SizedBox(height: 14),
                  if (product != null && product.benefits.isNotEmpty)
                    ...product.benefits.take(3).map(
                          (benefit) => _buildBenefitRow(benefit),
                        )
                  else ...[
                    _buildBenefitRow('Hutibu na kuondoa chanzo cha $topic kwa njia ya asili'),
                    _buildBenefitRow('Dawa 100% ya asili isiyo na kemikali wala madhara mwilini'),
                    _buildBenefitRow('Ushauri na maelekezo ya dozi sahihi kutoka kwa Mwalimu'),
                  ],

                  const SizedBox(height: 16),

                  // Big 3D "Nunua Dawa Hii Sasa" CTA Button
                  PressableScale(
                    onTap: () {
                      if (product != null) {
                        OrderProductSheet.show(context, product);
                      } else {
                        final found = orderService.findProductForPost(post);
                        if (found != null) {
                          OrderProductSheet.show(context, found);
                        } else {
                          final msg = DiseaseExtractor.formatMwalimuInquiry(topic);
                          context.read<AppProvider>().openMwalimuWithDraft(msg);
                        }
                      }
                    },
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            product != null
                                ? Icons.shopping_cart_checkout_rounded
                                : Icons.chat_bubble_outline_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product != null
                                ? 'Nunua Dawa Hii Sasa (Punguzo 50%)'
                                : 'Nunua Dawa Hii (Uliza Mwalimu)',
                            style: const TextStyle(
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
                      _buildTrustBadge(
                        product != null ? Icons.receipt_long_rounded : Icons.support_agent_rounded,
                        product != null ? 'Risiti ya Papo hapo' : 'Ushauri wa Mwalimu',
                      ),
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

  Widget _buildBenefitRow(String text) {
    return Padding(
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
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
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

/// Floating sticky bar pinned to bottom of Makala reader for instant checkout or inquiry
class StickyMakalaBuyBar extends StatelessWidget {
  const StickyMakalaBuyBar({
    super.key,
    this.post,
    this.product,
    this.onTap,
    this.onBuy,
    this.buttonLabel,
    this.buttonIcon,
    this.isExpanded = false,
  });

  final ContentPost? post;
  final DawaProduct? product;
  final VoidCallback? onTap;
  final VoidCallback? onBuy;
  final String? buttonLabel;
  final IconData? buttonIcon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: () {
        if (onBuy != null) {
          onBuy!();
        } else if (post != null) {
          DawaPurchaseHelper.searchAndBuyDawa(context, post!);
        } else if (product != null) {
          OrderProductSheet.show(context, product!);
        }
      },
      child: Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF059669)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.38),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              buttonIcon ?? Icons.shopping_bag_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              buttonLabel ?? 'Nunua Dawa Hii',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
