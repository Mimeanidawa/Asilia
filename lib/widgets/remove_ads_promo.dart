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
    final ads = context.watch<AdsService>();
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
    final ads = context.watch<AdsService>();
    final user = context.watch<UserService>();
    if (!ads.shouldShowAds(user)) return const SizedBox.shrink();

    return Material(
      elevation: 8,
      shadowColor: AppColors.forest.withValues(alpha: 0.25),
      borderRadius: BorderRadius.circular(28),
      color: AppColors.forest,
      child: InkWell(
        onTap: () {
          onDismiss();
          openRemoveAdsPayment(context);
        },
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.no_adult_content_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Text(
                'Ondoa matangazo yote sasa',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: onDismiss,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tracks makala reads and occasionally shows the floating promo modal.
class RemoveAdsPromo {
  RemoveAdsPromo._();

  static const _lastModalKey = 'da_remove_ads_modal_ts';
  static const _makalaReadsKey = 'da_remove_ads_makala_reads';

  static Future<void> recordMakalaRead() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_makalaReadsKey) ?? 0;
    await prefs.setInt(_makalaReadsKey, count + 1);
  }

  static Future<void> maybeShowFloatingModal(BuildContext context) async {
    final ads = context.read<AdsService>();
    final user = context.read<UserService>();
    if (!ads.shouldShowAds(user)) return;

    final settings = context.read<MwalimuService>().settings;
    if (!settings.adsPromoModalEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    final reads = prefs.getInt(_makalaReadsKey) ?? 0;
    if (reads < 2) return;

    final lastShown = prefs.getInt(_lastModalKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    const fourHoursMs = 4 * 60 * 60 * 1000;
    if (now - lastShown < fourHoursMs) return;

    await prefs.setInt(_lastModalKey, now);
    if (!context.mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _RemoveAdsModalSheet(
        price: settings.premiumPrice,
        onPay: () async {
          Navigator.of(ctx).pop();
          if (context.mounted) {
            await openRemoveAdsPayment(context);
          }
        },
      ),
    );
  }
}

class _RemoveAdsModalSheet extends StatelessWidget {
  const _RemoveAdsModalSheet({
    required this.price,
    required this.onPay,
  });

  final int price;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        decoration: BoxDecoration(
          color: AppColors.cream,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.forest.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_adult_content_rounded,
                size: 32,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ondoa matangazo yote sasa',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Premium (${TzsFormat.full(price)}) — hakuna matangazo, makala zote, na mazungumzo bila kikomo na Mwalimu kwa siku 30.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: onPay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Lipa ${TzsFormat.full(price)} — Ondoa Matangazo',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Baadaye',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.gray500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
