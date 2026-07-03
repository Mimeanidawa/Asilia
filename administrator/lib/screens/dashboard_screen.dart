import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final stats = provider.stats;
    final fmt = NumberFormat.compact();
    final currency = NumberFormat.compact(locale: 'en_US');

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AdminColors.bg,
            pinned: true,
            elevation: 0,
            toolbarHeight: 72,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: GoogleFonts.inter(
                          color: AdminColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, MMM d').format(DateTime.now()),
                        style: GoogleFonts.inter(
                          color: AdminColors.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AdminColors.emeraldGlow,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AdminColors.emerald.withOpacity(0.3)),
                    ),
                    child: const Icon(Icons.eco_rounded, color: AdminColors.emerald, size: 20),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Primary Stat Cards Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.4,
                  children: [
                    StatCard(
                      label: 'Total Users',
                      value: fmt.format(stats.totalUsers),
                      icon: Icons.people_rounded,
                      gradient: AdminColors.emeraldGradient,
                      glowColor: AdminColors.emerald,
                      trend: '+${stats.userGrowthRate}%',
                      trendPositive: true,
                      delay: const Duration(milliseconds: 0),
                    ),
                    StatCard(
                      label: 'Monthly Revenue',
                      value: '\$${currency.format(stats.monthlyRevenue)}',
                      icon: Icons.attach_money_rounded,
                      gradient: AdminColors.amberGradient,
                      glowColor: AdminColors.amber,
                      trend: '+${stats.revenueGrowthRate}%',
                      trendPositive: true,
                      delay: const Duration(milliseconds: 80),
                    ),
                    StatCard(
                      label: 'Premium Users',
                      value: fmt.format(stats.premiumUsers),
                      icon: Icons.star_rounded,
                      gradient: AdminColors.purpleGradient,
                      glowColor: AdminColors.purple,
                      subtitle: '${stats.premiumConversionRate}% conversion',
                      delay: const Duration(milliseconds: 160),
                    ),
                    StatCard(
                      label: 'Active Today',
                      value: fmt.format(stats.activeToday),
                      icon: Icons.bolt_rounded,
                      gradient: AdminColors.blueGradient,
                      glowColor: AdminColors.blue,
                      subtitle: 'Live users',
                      delay: const Duration(milliseconds: 240),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Secondary mini stats
                Row(
                  children: [
                    Expanded(
                      child: MiniStatCard(
                        label: 'Free Users',
                        value: fmt.format(stats.freeUsers),
                        icon: Icons.person_outline_rounded,
                        color: AdminColors.blue,
                        delay: const Duration(milliseconds: 320),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MiniStatCard(
                        label: 'Total Revenue',
                        value: '\$${currency.format(stats.totalRevenue)}',
                        icon: Icons.account_balance_wallet_rounded,
                        color: AdminColors.amber,
                        delay: const Duration(milliseconds: 380),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: MiniStatCard(
                        label: 'Churn Rate',
                        value: '${stats.churnRate}%',
                        icon: Icons.trending_down_rounded,
                        color: AdminColors.error,
                        delay: const Duration(milliseconds: 440),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: MiniStatCard(
                        label: 'Conversion',
                        value: '${stats.premiumConversionRate}%',
                        icon: Icons.upgrade_rounded,
                        color: AdminColors.purple,
                        delay: const Duration(milliseconds: 500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Recent Activity
                Animate(
                  delay: const Duration(milliseconds: 400),
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 500)),
                    SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: Duration(milliseconds: 500)),
                  ],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activity',
                            style: GoogleFonts.inter(
                              color: AdminColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AdminColors.success,
                              shape: BoxShape.circle,
                            ),
                          ).animate(onPlay: (c) => c.repeat()).shimmer(
                                duration: const Duration(seconds: 2),
                                color: AdminColors.success,
                              ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ...provider.recentActivities.asMap().entries.map((e) {
                        return _ActivityTile(
                          activity: e.value,
                          delay: Duration(milliseconds: 500 + e.key * 60),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, this.delay = Duration.zero});
  final RecentActivity activity;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final icon = _icon(activity.type);
    final color = _color(activity.type);
    final timeAgo = _timeAgo(activity.timestamp);

    return Animate(
      delay: delay,
      effects: const [
        FadeEffect(duration: Duration(milliseconds: 400)),
        SlideEffect(begin: Offset(0.05, 0), end: Offset.zero, duration: Duration(milliseconds: 400)),
      ],
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AdminColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.description,
                    style: GoogleFonts.inter(
                      color: AdminColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (activity.userName != null)
                    Text(
                      activity.userName!,
                      style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                    ),
                ],
              ),
            ),
            Text(
              timeAgo,
              style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  IconData _icon(String type) {
    switch (type) {
      case 'premium':
        return Icons.star_rounded;
      case 'user':
        return Icons.person_add_rounded;
      case 'notification':
        return Icons.notifications_rounded;
      case 'ban':
        return Icons.block_rounded;
      case 'content':
        return Icons.article_rounded;
      default:
        return Icons.circle_rounded;
    }
  }

  Color _color(String type) {
    switch (type) {
      case 'premium':
        return AdminColors.amber;
      case 'user':
        return AdminColors.emerald;
      case 'notification':
        return AdminColors.blue;
      case 'ban':
        return AdminColors.error;
      case 'content':
        return AdminColors.purple;
      default:
        return AdminColors.textDim;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
