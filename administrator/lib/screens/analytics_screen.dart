import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../widgets/chart_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final stats = provider.stats;

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Analytics',
                    style: GoogleFonts.inter(
                      color: AdminColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  Text(
                    'Last 12 months',
                    style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // KPI Row
                Animate(
                  effects: const [FadeEffect(duration: Duration(milliseconds: 400))],
                  child: Row(
                    children: [
                      _KpiChip(
                        label: 'Growth Rate',
                        value: '+${stats.userGrowthRate}%',
                        color: AdminColors.emerald,
                      ),
                      const SizedBox(width: 10),
                      _KpiChip(
                        label: 'Revenue Growth',
                        value: '+${stats.revenueGrowthRate}%',
                        color: AdminColors.amber,
                      ),
                      const SizedBox(width: 10),
                      _KpiChip(
                        label: 'Churn Rate',
                        value: '${stats.churnRate}%',
                        color: AdminColors.error,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // User Growth Chart
                Animate(
                  delay: const Duration(milliseconds: 100),
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 500)),
                    SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: Duration(milliseconds: 500)),
                  ],
                  child: LineChartCard(
                    title: 'User Growth',
                    subtitle: 'Total registered users per month',
                    data: provider.userGrowth,
                    color: AdminColors.emerald,
                    valuePrefix: '',
                  ),
                ),
                const SizedBox(height: 16),
                // Revenue Chart
                Animate(
                  delay: const Duration(milliseconds: 200),
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 500)),
                    SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: Duration(milliseconds: 500)),
                  ],
                  child: BarChartCard(
                    title: 'Monthly Revenue',
                    subtitle: 'USD revenue per month',
                    data: provider.revenueData,
                    color: AdminColors.amber,
                  ),
                ),
                const SizedBox(height: 16),
                // Premium growth
                Animate(
                  delay: const Duration(milliseconds: 300),
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 500)),
                    SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: Duration(milliseconds: 500)),
                  ],
                  child: LineChartCard(
                    title: 'Premium Subscribers',
                    subtitle: 'Premium user count over time',
                    data: provider.premiumGrowth,
                    color: AdminColors.purple,
                    valuePrefix: '',
                  ),
                ),
                const SizedBox(height: 16),
                // Donut chart
                Animate(
                  delay: const Duration(milliseconds: 400),
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 500)),
                    SlideEffect(begin: Offset(0, 0.1), end: Offset.zero, duration: Duration(milliseconds: 500)),
                  ],
                  child: DonutChartCard(
                    title: 'User Plan Distribution',
                    premium: stats.premiumUsers,
                    free: stats.freeUsers,
                  ),
                ),
                const SizedBox(height: 16),
                // Engagement stats
                Animate(
                  delay: const Duration(milliseconds: 500),
                  effects: const [FadeEffect(duration: Duration(milliseconds: 500))],
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AdminColors.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AdminColors.cardBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Engagement Metrics',
                          style: GoogleFonts.inter(
                            color: AdminColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _EngagementRow(
                          label: 'Avg. Sessions / User',
                          value: '14.2',
                          progress: 0.71,
                          color: AdminColors.emerald,
                        ),
                        const SizedBox(height: 12),
                        _EngagementRow(
                          label: '30-Day Retention',
                          value: '68%',
                          progress: 0.68,
                          color: AdminColors.blue,
                        ),
                        const SizedBox(height: 12),
                        _EngagementRow(
                          label: 'Avg. Session Duration',
                          value: '8m 32s',
                          progress: 0.55,
                          color: AdminColors.amber,
                        ),
                        const SizedBox(height: 12),
                        _EngagementRow(
                          label: 'Premium Retention',
                          value: '84%',
                          progress: 0.84,
                          color: AdminColors.purple,
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 10),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _EngagementRow extends StatelessWidget {
  const _EngagementRow({
    required this.label,
    required this.value,
    required this.progress,
    required this.color,
  });
  final String label;
  final String value;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13)),
            Text(
              value,
              style: GoogleFonts.inter(
                color: AdminColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AdminColors.cardBorder,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 5,
          ),
        ),
      ],
    );
  }
}
