import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';
import '../widgets/admin_ui.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final stats = provider.stats;
    final fmt = NumberFormat.compact();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        backgroundColor: AdminColors.card,
        onRefresh: provider.refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AdminPageHeader(
              title: 'Dashboard',
              subtitle: DateFormat('EEEE, MMMM d').format(DateTime.now()),
              actions: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AdminColors.emeraldGlow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.25)),
                  ),
                  child: const Icon(Icons.eco_rounded, color: AdminColors.emerald, size: 20),
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
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                    children: [
                      StatCard(
                        label: 'Total Users',
                        value: fmt.format(stats.totalUsers),
                        icon: Icons.people_rounded,
                        accentColor: AdminColors.emerald,
                        trend: '+${stats.userGrowthRate}%',
                        trendPositive: true,
                        delay: Duration.zero,
                      ),
                      StatCard(
                        label: 'Monthly Revenue',
                        value: TzsFormat.compact(stats.monthlyRevenue),
                        icon: Icons.payments_rounded,
                        accentColor: AdminColors.amber,
                        trend: '+${stats.revenueGrowthRate}%',
                        trendPositive: true,
                        delay: const Duration(milliseconds: 60),
                      ),
                      StatCard(
                        label: 'Premium Users',
                        value: fmt.format(stats.premiumUsers),
                        icon: Icons.workspace_premium_rounded,
                        accentColor: AdminColors.purple,
                        subtitle: '${stats.premiumConversionRate}% conversion',
                        delay: const Duration(milliseconds: 120),
                      ),
                      StatCard(
                        label: 'Active Today',
                        value: fmt.format(stats.activeToday),
                        icon: Icons.bolt_rounded,
                        accentColor: AdminColors.blue,
                        subtitle: 'Live users',
                        delay: const Duration(milliseconds: 180),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: MiniStatCard(
                          label: 'Free Users',
                          value: fmt.format(stats.freeUsers),
                          icon: Icons.person_outline_rounded,
                          color: AdminColors.blue,
                          delay: const Duration(milliseconds: 240),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Total Revenue',
                          value: TzsFormat.compact(stats.totalRevenue),
                          icon: Icons.account_balance_wallet_rounded,
                          color: AdminColors.amber,
                          delay: const Duration(milliseconds: 280),
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
                          delay: const Duration(milliseconds: 320),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MiniStatCard(
                          label: 'Conversion',
                          value: '${stats.premiumConversionRate}%',
                          icon: Icons.upgrade_rounded,
                          color: AdminColors.purple,
                          delay: const Duration(milliseconds: 360),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AdminSectionTitle(
                    title: 'Recent Activity',
                    trailing: AdminStatusBadge(label: 'Live', pulse: true),
                  ),
                  if (provider.recentActivities.isEmpty)
                    AdminEmptyState(
                      icon: Icons.history_rounded,
                      title: 'No recent activity',
                      subtitle: 'User actions will appear here',
                    )
                  else
                    ...provider.recentActivities.asMap().entries.map((e) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ActivityTile(
                          activity: e.value,
                          delay: Duration(milliseconds: 400 + e.key * 50),
                        ),
                      );
                    }),
                ]),
              ),
            ),
          ],
        ),
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
        FadeEffect(duration: Duration(milliseconds: 350)),
        SlideEffect(begin: Offset(0.04, 0), end: Offset.zero, duration: Duration(milliseconds: 350)),
      ],
      child: AdminSurface(
        onTap: activity.type == 'mwalimu'
            ? () => context.read<AdminProvider>().setScreen(AdminScreen.mwalimu)
            : null,
        accentColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
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
                    style: GoogleFonts.plusJakartaSans(
                      color: AdminColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (activity.userName != null)
                    Text(
                      activity.preview != null && activity.preview!.isNotEmpty
                          ? '${activity.userName} · ${activity.preview}'
                          : activity.userName!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              timeAgo,
              style: GoogleFonts.plusJakartaSans(
                color: AdminColors.textDim,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
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
      case 'mwalimu':
        return Icons.chat_bubble_rounded;
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
      case 'mwalimu':
        return AdminColors.emerald;
      default:
        return AdminColors.textMuted;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}
