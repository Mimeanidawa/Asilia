import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';
import '../widgets/chart_card.dart';
import '../widgets/stat_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final stats = provider.stats;
    final fmt = NumberFormat.compact();

    final avgMessages = stats.totalUsers > 0
        ? provider.users.map((u) => u.messageCount).fold<int>(0, (a, b) => a + b) /
            provider.users.length
        : 0.0;

    final activePct = stats.totalUsers > 0 ? stats.activeToday / stats.totalUsers : 0.0;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        onRefresh: provider.refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AdminColors.bg,
              pinned: true,
              elevation: 0,
              toolbarHeight: 80,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Analytics',
                            style: GoogleFonts.inter(
                              color: AdminColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Performance overview · Last 12 months',
                            style: GoogleFonts.inter(
                              color: AdminColors.textDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _LiveBadge(isRefreshing: provider.isRefreshing),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _OverviewBanner(stats: stats, fmt: fmt),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.35,
                    children: [
                      StatCard(
                        label: 'User Growth',
                        value: '+${stats.userGrowthRate.toStringAsFixed(1)}%',
                        icon: Icons.trending_up_rounded,
                        gradient: AdminColors.emeraldGradient,
                        glowColor: AdminColors.emerald,
                        subtitle: '${fmt.format(stats.totalUsers)} total',
                        delay: const Duration(milliseconds: 60),
                      ),
                      StatCard(
                        label: 'Revenue Growth',
                        value: '+${stats.revenueGrowthRate.toStringAsFixed(1)}%',
                        icon: Icons.payments_rounded,
                        gradient: AdminColors.amberGradient,
                        glowColor: AdminColors.amber,
                        subtitle: TzsFormat.compact(stats.monthlyRevenue),
                        delay: const Duration(milliseconds: 120),
                      ),
                      StatCard(
                        label: 'Premium Rate',
                        value: '${stats.premiumConversionRate.toStringAsFixed(1)}%',
                        icon: Icons.workspace_premium_rounded,
                        gradient: AdminColors.purpleGradient,
                        glowColor: AdminColors.purple,
                        subtitle: '${fmt.format(stats.premiumUsers)} subscribers',
                        delay: const Duration(milliseconds: 180),
                      ),
                      StatCard(
                        label: 'Churn Rate',
                        value: '${stats.churnRate.toStringAsFixed(1)}%',
                        icon: Icons.trending_down_rounded,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF991B1B), Color(0xFFEF4444)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        glowColor: AdminColors.error,
                        trendPositive: false,
                        subtitle: '${fmt.format(stats.activeToday)} active today',
                        delay: const Duration(milliseconds: 240),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  const _SectionTitle(
                    icon: Icons.show_chart_rounded,
                    title: 'Growth Trends',
                    subtitle: 'User acquisition & premium adoption',
                  ),
                  const SizedBox(height: 14),
                  LineChartCard(
                    title: 'User Growth',
                    subtitle: 'Registered users per month',
                    data: provider.userGrowth,
                    color: AdminColors.emerald,
                    valuePrefix: '',
                    icon: Icons.people_alt_rounded,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 14),
                  LineChartCard(
                    title: 'Premium Subscribers',
                    subtitle: 'Paid plan growth over time',
                    data: provider.premiumGrowth,
                    color: AdminColors.purple,
                    valuePrefix: '',
                    icon: Icons.star_rounded,
                  ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 28),
                  const _SectionTitle(
                    icon: Icons.account_balance_wallet_rounded,
                    title: 'Revenue',
                    subtitle: 'Monthly earnings in TZS',
                  ),
                  const SizedBox(height: 14),
                  BarChartCard(
                    title: 'Monthly Revenue',
                    subtitle: 'Mapato kwa TZS kila mwezi',
                    data: provider.revenueData,
                    color: AdminColors.amber,
                    icon: Icons.bar_chart_rounded,
                  ).animate().fadeIn(delay: 260.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 28),
                  const _SectionTitle(
                    icon: Icons.pie_chart_rounded,
                    title: 'Audience Mix',
                    subtitle: 'Free vs premium distribution',
                  ),
                  const SizedBox(height: 14),
                  DonutChartCard(
                    title: 'User Plan Distribution',
                    premium: stats.premiumUsers,
                    free: stats.freeUsers,
                  ).animate().fadeIn(delay: 340.ms).slideY(begin: 0.06, end: 0),
                  const SizedBox(height: 28),
                  const _SectionTitle(
                    icon: Icons.bolt_rounded,
                    title: 'Engagement',
                    subtitle: 'How users interact with the platform',
                  ),
                  const SizedBox(height: 14),
                  _EngagementPanel(
                    avgMessages: avgMessages,
                    activeToday: stats.activeToday,
                    activePct: activePct,
                    conversionRate: stats.premiumConversionRate,
                    monthlyRevenue: stats.monthlyRevenue,
                    totalRevenue: stats.totalRevenue,
                  ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.06, end: 0),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isRefreshing});

  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: isRefreshing ? AdminColors.amber : AdminColors.emerald,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (isRefreshing ? AdminColors.amber : AdminColors.emerald)
                      .withValues(alpha: 0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isRefreshing ? 'Syncing' : 'Live',
            style: GoogleFonts.inter(
              color: AdminColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewBanner extends StatelessWidget {
  const _OverviewBanner({required this.stats, required this.fmt});

  final DashboardStats stats;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AdminColors.forest,
            AdminColors.forestLight,
            AdminColors.emerald.withValues(alpha: 0.25),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AdminColors.emerald.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Snapshot',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Real-time metrics from your user base',
                      style: GoogleFonts.inter(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: 'Total Users',
                  value: fmt.format(stats.totalUsers),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: _OverviewStat(
                  label: 'Total Revenue',
                  value: TzsFormat.compact(stats.totalRevenue),
                ),
              ),
              Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.15)),
              Expanded(
                child: _OverviewStat(
                  label: 'Premium',
                  value: '${stats.premiumConversionRate.toStringAsFixed(0)}%',
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.08, end: 0);
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AdminColors.emeraldGlow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.25)),
          ),
          child: Icon(icon, color: AdminColors.emerald, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  color: AdminColors.textDim,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EngagementPanel extends StatelessWidget {
  const _EngagementPanel({
    required this.avgMessages,
    required this.activeToday,
    required this.activePct,
    required this.conversionRate,
    required this.monthlyRevenue,
    required this.totalRevenue,
  });

  final double avgMessages;
  final int activeToday;
  final double activePct;
  final double conversionRate;
  final double monthlyRevenue;
  final double totalRevenue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminColors.cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _EngagementTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Avg. Messages',
                  value: avgMessages.toStringAsFixed(1),
                  color: AdminColors.emerald,
                  progress: (avgMessages / 10).clamp(0.0, 1.0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EngagementTile(
                  icon: Icons.person_pin_circle_outlined,
                  label: 'Active Today',
                  value: '$activeToday',
                  color: AdminColors.blue,
                  progress: activePct,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _EngagementTile(
                  icon: Icons.diamond_outlined,
                  label: 'Conversion',
                  value: '${conversionRate.toStringAsFixed(1)}%',
                  color: AdminColors.amber,
                  progress: conversionRate / 100,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _EngagementTile(
                  icon: Icons.savings_outlined,
                  label: 'This Month',
                  value: TzsFormat.compact(monthlyRevenue),
                  color: AdminColors.purple,
                  progress: totalRevenue > 0 ? monthlyRevenue / totalRevenue : 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EngagementTile extends StatelessWidget {
  const _EngagementTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const Spacer(),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AdminColors.textDim,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AdminColors.cardBorder,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
