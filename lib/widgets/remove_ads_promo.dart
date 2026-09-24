import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/ads_service.dart';
import '../services/mwalimu_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/remove_ads_flow.dart';
import '../utils/tzs_format.dart';

/// Inline CTA: "Je Umechoka na Matangazo…"
class RemoveAdsInlineStrip extends StatelessWidget {
  const RemoveAdsInlineStrip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ads = context.read<AdsService>();
    final user = context.watch<UserService>();
    if (!ads.shouldShowAds(user)) return const SizedBox.shrink();

    final price = context.watch<MwalimuService>().settings.premiumPrice;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openRemoveAdsPayment(context),
        borderRadius: BorderRadius.circular(compact ? 14 : 18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.forest.withValues(alpha: 0.95),
                AppColors.emerald800.withValues(alpha: 0.92),
              ],
            ),
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 14 : 16,
              vertical: compact ? 12 : 14,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.block_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compact
                            ? 'Je Umechoka na Matangazo?'
                            : 'Je Umechoka na Matangazo?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        compact
                            ? 'Zima matangazo yote hapa — ${TzsFormat.full(price)}'
                            : 'Zima matangazo yote hapa. Premium pia inafungua makala zote.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating chip shown over makala reader (optional overlay).
class RemoveAdsFloatingChip extends StatelessWidget {
  const RemoveAdsFloatingChip({super.key, required this.onDismiss});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// Tracks makala reads and occasionally shows the floating promo modal.
class RemoveAdsPromo {
  RemoveAdsPromo._();

  static const _makalaReadsKey = 'da_remove_ads_makala_reads';

  static Future<void> recordMakalaRead() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_makalaReadsKey) ?? 0;
    await prefs.setInt(_makalaReadsKey, count + 1);
  }

  static Future<void> maybeShowFloatingModal(BuildContext context) async {
    return;
  }
}

