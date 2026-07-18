import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../services/mwalimu_service.dart';
import '../services/payment_service.dart';
import '../utils/tzs_format.dart';
import '../widgets/sonicpesa_payment_sheet.dart';
import '../widgets/pull_to_refresh.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final userService = context.watch<UserService>();
    final mwalimu = context.watch<MwalimuService>();
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
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: AppColors.emerald800,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'MTUMIAJI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: 350.ms,
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.05),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: isLoggedIn
                  ? _ProfileCard(
                      key: const ValueKey('profile-logged'),
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
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04)
                  : _GuestProfileCard(
                      key: const ValueKey('profile-guest'),
                      onJoin: () => app.navigate(AppScreen.auth),
                    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.04),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Material(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await app.resetProfileState();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile state reset successfully.'),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.red600, size: 18),
                        SizedBox(width: 12),
                        Text(
                          'Reset Local Profile State',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.red600,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right, color: Color(0xFFFECACA)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard({super.key, required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.emerald50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.eco, color: AppColors.forest, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Karibu Dawa Asili!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Jiunge ili kusoma makala, kuuliza Mwalimu, na kufungua maudhui ya Premium',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Jiunge au Ingia',
                style: TextStyle(fontWeight: FontWeight.w900),
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
    super.key,
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
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF4FBF8), Colors.white],
        ),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.forest.withValues(alpha: 0.07),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: onLogout,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(
                        Icons.logout_rounded,
                        color: AppColors.gray500,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (contact != null) ...[
              const SizedBox(height: 10),
              _MetaPill(
                icon: contact!.contains('@')
                    ? Icons.email_outlined
                    : Icons.phone_outlined,
                label: contact!,
              ),
            ],
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.gray200),
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
                    'Hali ya akaunti',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.gray500,
                    ),
                  ),
                  const Spacer(),
                  _MembershipBadge(isPremium: isPremium),
                ],
              ),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onUpgrade,
                  icon: const Icon(Icons.stars_rounded, size: 16),
                  label: Text(
                    'Fungua Makala zote — ${TzsFormat.full(premiumPrice)}',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inajumuisha makala zote za Premium + mazungumzo bila kikomo na Mwalimu kwa siku 30.',
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gray500,
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.gray500),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.gray600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipBadge extends StatelessWidget {
  const _MembershipBadge({super.key, required this.isPremium});

  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    final bgColor = isPremium
        ? AppColors.amber.withValues(alpha: 0.15)
        : AppColors.gray200;
    final textColor = isPremium ? AppColors.amber : AppColors.gray600;
    final label = isPremium ? 'PREMIUM' : 'LIMITED';
    return AnimatedContainer(
      duration: 250.ms,
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPremium
              ? AppColors.amber.withValues(alpha: 0.3)
              : AppColors.gray400.withValues(alpha: 0.25),
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
