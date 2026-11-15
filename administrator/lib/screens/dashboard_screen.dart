import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';
import '../widgets/admin_ui.dart';
import 'admin_payments_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final stats = provider.stats;
    final fmt = NumberFormat.compact();
    final payments = provider.recentPayments.take(8).toList();
    final syncLabel = provider.lastLiveSyncAt == null
        ? 'Inapakia…'
        : provider.liveSyncing
            ? 'Inasasisha…'
            : 'Live · ${_ago(provider.lastLiveSyncAt!)}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        backgroundColor: AdminColors.card,
        onRefresh: () => provider.refreshLive(force: true),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AdminPageHeader(
              title: 'Asilia',
              subtitle: DateFormat('EEEE, d MMM').format(DateTime.now()),
              actions: [
                AdminStatusBadge(
                  label: syncLabel,
                  pulse: !provider.liveSyncing && provider.lastLiveSyncAt != null,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (provider.mwalimuUnreadCount > 0) ...[
                    AdminBanner(
                      title: 'Maswali mapya: ${provider.mwalimuUnreadCount}',
                      subtitle: provider.mwalimuInbox.isNotEmpty
                          ? '${provider.mwalimuInbox.first['userName']}: New message'
                          : 'Gusa kufungua Maswali',
                      icon: Icons.mark_chat_unread_rounded,
                      color: AdminColors.emerald,
                      onTap: () => provider.setScreen(AdminScreen.mwalimu),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Revenue hero
                  _RevenueHero(
                    today: stats.todayRevenue,
                    total: stats.totalRevenue,
                    paymentsToday: stats.paymentsToday,
                    growth: stats.todayRevenueGrowthRate,
                    onTap: () => provider.setScreen(AdminScreen.payments),
                  ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0),

                  const SizedBox(height: 12),

                  // Compact metrics
                  Row(
                    children: [
                      Expanded(
                        child: _MetricTile(
                          label: 'Watumiaji',
                          value: fmt.format(stats.totalUsers),
                          icon: Icons.people_rounded,
                          color: AdminColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Premium',
                          value: fmt.format(stats.premiumUsers),
                          icon: Icons.workspace_premium_rounded,
                          color: AdminColors.purple,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricTile(
                          label: 'Hai leo',
                          value: fmt.format(stats.activeToday),
                          icon: Icons.bolt_rounded,
                          color: AdminColors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  AdminSectionTitle(
                    title: 'Malipo ya hivi karibuni',
                    trailing: TextButton(
                      onPressed: () => provider.setScreen(AdminScreen.payments),
                      child: Text(
                        'Yote',
                        style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.emerald,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                  if (payments.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.payments_outlined,
                      title: 'Hakuna malipo bado',
                      subtitle: 'Malipo ya Premium, makala na dawa yataonekana papo hapo',
                    )
                  else
                    ...payments.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: PaymentHistoryTile(payment: e.value)
                            .animate(delay: (40 * e.key).ms)
                            .fadeIn(duration: 280.ms)
                            .slideX(begin: 0.03, end: 0),
                      );
                    }),

                  const SizedBox(height: 18),

                  const AdminSectionTitle(title: 'Haraka'),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          title: 'Dawa',
                          subtitle: 'Bidhaa',
                          icon: Icons.medication_liquid_rounded,
                          color: AdminColors.emerald,
                          onTap: () => provider.setScreen(AdminScreen.products),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          title: 'Oda',
                          subtitle: 'Usafirishaji',
                          icon: Icons.local_shipping_rounded,
                          color: AdminColors.rose,
                          onTap: () => provider.setScreen(AdminScreen.orders),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _QuickAction(
                          title: 'Malipo',
                          subtitle: 'Historia',
                          icon: Icons.receipt_long_rounded,
                          color: AdminColors.amber,
                          onTap: () => provider.setScreen(AdminScreen.payments),
                        ),
                      ),
                    ],
                  ),

                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) return 'sasa';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return DateFormat('HH:mm').format(dt);
  }
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({
    required this.today,
    required this.total,
    required this.paymentsToday,
    required this.growth,
    required this.onTap,
  });

  final double today;
  final double total;
  final int paymentsToday;
  final double growth;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final growthPositive = growth >= 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [Color(0xFF0B1F17), Color(0xFF121212)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.28)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Mapato ya leo',
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (growthPositive ? AdminColors.emerald : AdminColors.error)
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${growthPositive ? '+' : ''}${growth.toStringAsFixed(0)}%',
                        style: GoogleFonts.plusJakartaSans(
                          color: growthPositive ? AdminColors.emerald : AdminColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  TzsFormat.compact(today),
                  style: GoogleFonts.plusJakartaSans(
                    color: AdminColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '$paymentsToday malipo leo',
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.emerald,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '·',
                      style: TextStyle(color: AdminColors.textDim),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Jumla ${TzsFormat.compact(total)}',
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: AdminColors.emerald.withValues(alpha: 0.8),
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AdminColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AdminColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AdminSurface(
      onTap: onTap,
      accentColor: color,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
