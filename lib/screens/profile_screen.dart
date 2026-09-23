import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../models/product_models.dart';
import '../models/remote_app_config.dart';
import '../providers/app_provider.dart';
import '../services/dawa_order_service.dart';
import '../services/mwalimu_service.dart';
import '../services/payment_service.dart';
import '../services/remote_app_config_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../utils/responsive.dart';
import '../utils/tzs_format.dart';
import '../widgets/herb_image.dart';
import '../widgets/makala_ads.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/pull_to_refresh.dart';
import '../widgets/receipt_modal.dart';
import '../widgets/remove_ads_promo.dart';
import '../widgets/sonicpesa_payment_sheet.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final userService = context.watch<UserService>();
    final mwalimu = context.watch<MwalimuService>();
    final remoteConfig = context.watch<RemoteAppConfigService>();
    final about = remoteConfig.config.about;
    final user = userService.user;
    final isLoggedIn = userService.isLoggedIn && user != null;
    final contact = (user?.email?.trim().isNotEmpty ?? false)
        ? user!.email!.trim()
        : ((user?.phone?.trim().isNotEmpty ?? false)
              ? user!.phone!.trim()
              : null);
    final premiumPrice = mwalimu.settings.premiumPrice;

    return SizedBox.expand(
      child: PullToRefresh(
        onRefresh: () async {
          await Future.wait([
            AppRefresh.user(context),
            AppRefresh.catalog(context),
            AppRefresh.premiumSettings(context),
          ]);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            Responsive.scrollBottomPadding(context, extra: 16),
          ),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppColors.emerald800,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Akaunti',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Wasifu na mipangilio yako',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: 300.ms,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: isLoggedIn
                  ? _ProfileCard(
                      fullName: user.fullName,
                      contact: contact,
                      isPremium: user.isPremiumActive,
                      premiumPrice: premiumPrice,
                      onLogout: userService.logout,
                      onUpgrade: () async {
                        final svc = context.read<MwalimuService>();
                        await svc.loadSettings();
                        if (!context.mounted) return;
                        final price = svc.settings.premiumPrice;
                        final result = await showAuraxPayment(
                          context,
                          type: PaymentType.premium,
                          title: 'Premium — Dawa Asili',
                          subtitle:
                              'Fungua makala zote + maswali bila kikomo kwa Mwalimu (siku 30)',
                          amount: price,
                        );
                        if (result == AuraxPaymentResult.success &&
                            context.mounted) {
                          await AppRefresh.afterPremiumPurchase(context);
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Premium imeamilishwa! Makala zote na mazungumzo yamefunguliwa.',
                              ),
                              backgroundColor: AppColors.forest,
                            ),
                          );
                        }
                      },
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03)
                  : _GuestProfileCard(
                      onJoin: () => app.navigate(AppScreen.auth),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.03),
            ),
            _buildUserReceiptsSection(context),
            const SizedBox(height: 16),
            const HomeFeedBannerAd(),
            const SizedBox(height: 8),
            _SettingsSection(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_none_rounded,
                  title: 'Taarifa',
                  subtitle: 'Tazama ujumbe na masasisho mapya',
                  onTap: () => app.navigate(AppScreen.notifications),
                ),
                _SettingsTile(
                  icon: Icons.school_outlined,
                  title: 'Darasa Huru & Mwalimu',
                  subtitle: 'Masomo na ushauri wa mimea ya asili',
                  onTap: () => app.navigate(AppScreen.darasaHuru),
                ),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Kuhusu Dawa Asili',
                  subtitle: 'Toleo ${about.appVersion} — Elimu ya afya ya asili',
                  onTap: () => _showAboutDawaAsiliModal(context, about),
                ),
                _SettingsTile(
                  icon: Icons.refresh_rounded,
                  title: 'Weka Upya Data ya Kifaa',
                  subtitle: 'Futa kumbukumbu ya muda ya simu',
                  iconColor: AppColors.gray500,
                  onTap: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Weka upya kumbukumbu?'),
                        content: const Text(
                          'Hatua hii itasafisha kumbukumbu ya muda iliyohifadhiwa kwenye kifaa hiki.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            child: const Text('Ghairi'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            child: const Text('Weka Upya'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      await app.resetProfileState();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Kumbukumbu imewekwa upya kikamilifu.'),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDawaAsiliModal(BuildContext context, AboutAppConfig about) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusXl)),
        contentPadding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.emerald800, AppColors.forest],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.emerald800.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(Icons.spa_rounded, color: Colors.white, size: 30),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              about.appName,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: AppColors.forest,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Toleo ${about.appVersion}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald800,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              about.appDescription,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.45,
              ),
            ),
            if (about.disclaimer.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gray100.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  about.disclaimer,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.gray600,
                  ),
                ),
              ),
            ],
            if (about.contactPhone.isNotEmpty || about.contactEmail.isNotEmpty) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: AppColors.gray200.withValues(alpha: 0.7)),
              const SizedBox(height: 10),
              if (about.contactPhone.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone_rounded, size: 13, color: AppColors.forest),
                      const SizedBox(width: 6),
                      Text(
                        about.contactPhone,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.forest),
                      ),
                    ],
                  ),
                ),
              if (about.contactEmail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email_outlined, size: 13, color: AppColors.forest),
                      const SizedBox(width: 6),
                      Text(
                        about.contactEmail,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.forest),
                      ),
                    ],
                  ),
                ),
            ],
            // Licenses are HIDDEN by default; only appear if admin explicitly sets showLicenses = true
            if (about.showLicenses) ...[
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  showLicensePage(
                    context: context,
                    applicationName: about.appName,
                    applicationVersion: about.appVersion,
                  );
                },
                child: const Text('Tazama Leseni', style: TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Funga',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forest),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserReceiptsSection(BuildContext context) {
    final orderService = context.watch<DawaOrderService>();
    final orders = orderService.orders;

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
        boxShadow: AppColors.elevationSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.emerald800,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risiti & Maagizo ya Dawa',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.forest,
                        ),
                      ),
                      Text(
                        'Fuatilia oda zako na risiti za malipo',
                        style: TextStyle(fontSize: 11, color: AppColors.gray500),
                      ),
                    ],
                  ),
                ],
              ),
              if (orders.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emerald50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emerald800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (orders.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: AppColors.gray400, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Huna agizo la dawa bado',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Soma makala yoyote kisha bofya "Nunua Dawa Hii" kwa punguzo la hadi 50% kupata risiti yako hapa.',
                          style: TextStyle(fontSize: 11, color: AppColors.gray500, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ...orders.map((order) => _buildOrderItem(context, order)),
        ],
      ),
    );
  }

  Widget _buildOrderItem(BuildContext context, DawaOrder order) {
    Color statusBg;
    Color statusTextColor;
    IconData statusIcon;

    switch (order.deliveryStatus) {
      case DawaDeliveryStatus.pending:
        statusBg = const Color(0xFFFEFBE8);
        statusTextColor = const Color(0xFFB54708);
        statusIcon = Icons.hourglass_top_rounded;
      case DawaDeliveryStatus.onTransit:
        statusBg = const Color(0xFFEFF8FF);
        statusTextColor = const Color(0xFF175CD3);
        statusIcon = Icons.local_shipping_rounded;
      case DawaDeliveryStatus.delivered:
        statusBg = AppColors.emerald50;
        statusTextColor = AppColors.emerald800;
        statusIcon = Icons.check_circle_rounded;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: PressableScale(
        onTap: () => ReceiptModal.show(context, order),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
            boxShadow: AppColors.elevationSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.receiptNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.emerald800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 12, color: statusTextColor),
                        const SizedBox(width: 4),
                        Text(
                          order.deliveryStatusLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: statusTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: HerbImage(
                      url: order.productImageUrl,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.forest,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${order.quantity} x chupa • ${order.region}, ${order.district}',
                          style: const TextStyle(fontSize: 11, color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        TzsFormat.full(order.totalAmount),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColors.forest,
                        ),
                      ),
                      const Text(
                        'Tazama Risiti >',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.emerald800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard({required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
        boxShadow: AppColors.elevationSm,
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            'Karibu Dawa Asili',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jiunge ili kusoma makala zote, kuuliza maswali kwa Mwalimu, na kufungua maarifa ya Premium.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray500,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Jiunge au Ingia',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.fullName,
    required this.contact,
    required this.isPremium,
    required this.premiumPrice,
    required this.onLogout,
    required this.onUpgrade,
  });

  final String fullName;
  final String? contact;
  final bool isPremium;
  final int premiumPrice;
  final VoidCallback onLogout;
  final Future<void> Function() onUpgrade;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppColors.radiusXl),
        color: AppColors.surfaceElevated,
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
        boxShadow: AppColors.elevationSm,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.emerald50,
                child: Text(
                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'M',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emerald800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forest,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (contact != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        contact!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray500,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onLogout,
                tooltip: 'Toka',
                icon: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.gray400,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.forest.withValues(alpha: 0.04)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.workspace_premium_rounded,
                  size: 18,
                  color: AppColors.forest,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Hali ya Akaunti',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.forest,
                  ),
                ),
                const Spacer(),
                _MembershipBadge(isPremium: isPremium),
              ],
            ),
          ),
          if (!isPremium) ...[
            const SizedBox(height: 14),
            const RemoveAdsInlineStrip(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onUpgrade,
                icon: const Icon(Icons.stars_rounded, size: 16),
                label: Text(
                  'Fungua Makala Zote — ${TzsFormat.full(premiumPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.forest,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppColors.radiusLg),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.06)),
        boxShadow: AppColors.elevationSm,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(
                height: 1,
                indent: 52,
                color: AppColors.forest.withValues(alpha: 0.05),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.emerald50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                size: 18,
                color: iconColor ?? AppColors.forest,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.forest,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.gray500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.gray400,
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipBadge extends StatelessWidget {
  const _MembershipBadge({required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPremium
        ? AppColors.amber.withValues(alpha: 0.15)
        : AppColors.gray100;
    final textColor = isPremium ? AppColors.amber : AppColors.gray600;
    final label = isPremium ? 'PREMIUM' : 'BILA MALIPO';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium
              ? AppColors.amber.withValues(alpha: 0.3)
              : AppColors.gray300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w900,
          color: textColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
