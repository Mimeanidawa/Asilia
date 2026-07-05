import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/admin_models.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';

class LineChartCard extends StatelessWidget {
  const LineChartCard({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    required this.valuePrefix,
    this.subtitle,
    this.icon,
  });

  final String title;
  final List<MonthlyMetric> data;
  final Color color;
  final String valuePrefix;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _ChartEmptyCard(title: title, subtitle: subtitle, color: color, icon: icon);
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.value))
        .toList();

    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final minY = data.map((d) => d.value).reduce((a, b) => a < b ? a : b);
    final latest = data.last;

    return _ChartShell(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(
            title: title,
            subtitle: subtitle,
            color: color,
            icon: icon,
            trailing: valuePrefix == 'TZS'
                ? TzsFormat.chart(latest.value)
                : latest.value.toInt().toString(),
            trailingLabel: latest.month,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 168,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AdminColors.cardBorder.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[idx].month,
                            style: GoogleFonts.inter(
                              color: AdminColors.textDim,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: minY * 0.9,
                maxY: maxY * 1.08,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, bar, index) {
                        if (index != spots.length - 1) {
                          return FlDotCirclePainter(
                            radius: 0,
                            color: Colors.transparent,
                            strokeWidth: 0,
                          );
                        }
                        return FlDotCirclePainter(
                          radius: 5,
                          color: color,
                          strokeWidth: 2,
                          strokeColor: AdminColors.card,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.28),
                          color.withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AdminColors.surface,
                    tooltipBorder: BorderSide(color: color.withValues(alpha: 0.4)),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final val = spot.y;
                        final formatted = valuePrefix == 'TZS'
                            ? TzsFormat.chart(val)
                            : val.toInt().toString();
                        return LineTooltipItem(
                          formatted,
                          GoogleFonts.inter(
                            color: color,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BarChartCard extends StatelessWidget {
  const BarChartCard({
    super.key,
    required this.title,
    required this.data,
    required this.color,
    this.subtitle,
    this.icon,
  });

  final String title;
  final List<MonthlyMetric> data;
  final Color color;
  final String? subtitle;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _ChartEmptyCard(title: title, subtitle: subtitle, color: color, icon: icon);
    }

    final maxY = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    final latest = data.last;

    return _ChartShell(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(
            title: title,
            subtitle: subtitle,
            color: color,
            icon: icon,
            trailing: TzsFormat.compact(latest.value),
            trailingLabel: latest.month,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 168,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AdminColors.cardBorder.withValues(alpha: 0.6),
                    strokeWidth: 1,
                    dashArray: [5, 5],
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: 2,
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[idx].month,
                            style: GoogleFonts.inter(
                              color: AdminColors.textDim,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                maxY: maxY * 1.12,
                barGroups: data.asMap().entries.map((e) {
                  final isLatest = e.key == data.length - 1;
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value.value,
                        gradient: LinearGradient(
                          colors: isLatest
                              ? [color, color.withValues(alpha: 0.7)]
                              : [color.withValues(alpha: 0.55), color.withValues(alpha: 0.35)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                        width: 16,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY * 1.12,
                          color: color.withValues(alpha: 0.06),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AdminColors.surface,
                    tooltipBorder: BorderSide(color: color.withValues(alpha: 0.4)),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        TzsFormat.chart(rod.toY),
                        GoogleFonts.inter(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DonutChartCard extends StatelessWidget {
  const DonutChartCard({
    super.key,
    required this.title,
    required this.premium,
    required this.free,
  });

  final String title;
  final int premium;
  final int free;

  @override
  Widget build(BuildContext context) {
    final total = premium + free;
    if (total == 0) {
      return _ChartEmptyCard(
        title: title,
        subtitle: 'No user data yet',
        color: AdminColors.emerald,
        icon: Icons.donut_large_rounded,
      );
    }

    final premiumPct = (premium / total * 100).toStringAsFixed(1);
    final freePct = (free / total * 100).toStringAsFixed(1);

    return _ChartShell(
      color: AdminColors.emerald,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(
            title: title,
            subtitle: '$total total users',
            color: AdminColors.emerald,
            icon: Icons.donut_large_rounded,
            trailing: '$premiumPct%',
            trailingLabel: 'Premium share',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 44,
                        sections: [
                          PieChartSectionData(
                            value: premium.toDouble(),
                            color: AdminColors.emerald,
                            radius: 28,
                            title: '',
                          ),
                          PieChartSectionData(
                            value: free.toDouble(),
                            color: AdminColors.blue.withValues(alpha: 0.85),
                            radius: 22,
                            title: '',
                          ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$total',
                          style: GoogleFonts.inter(
                            color: AdminColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'users',
                          style: GoogleFonts.inter(
                            color: AdminColors.textDim,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _LegendItem(
                      color: AdminColors.emerald,
                      label: 'Premium',
                      value: '$premium',
                      percent: '$premiumPct%',
                    ),
                    const SizedBox(height: 12),
                    _LegendItem(
                      color: AdminColors.blue,
                      label: 'Free',
                      value: '$free',
                      percent: '$freePct%',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChartShell extends StatelessWidget {
  const _ChartShell({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AdminColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.8), color.withValues(alpha: 0.1)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _ChartHeader extends StatelessWidget {
  const _ChartHeader({
    required this.title,
    required this.color,
    this.subtitle,
    this.icon,
    this.trailing,
    this.trailingLabel,
  });

  final String title;
  final Color color;
  final String? subtitle;
  final IconData? icon;
  final String? trailing;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null)
          Container(
            margin: const EdgeInsets.only(right: 12, top: 2),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: GoogleFonts.inter(
                    color: AdminColors.textDim,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
        ),
        if (trailing != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                trailing!,
                style: GoogleFonts.inter(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              if (trailingLabel != null)
                Text(
                  trailingLabel!,
                  style: GoogleFonts.inter(
                    color: AdminColors.textDim,
                    fontSize: 10,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ChartEmptyCard extends StatelessWidget {
  const _ChartEmptyCard({
    required this.title,
    this.subtitle,
    required this.color,
    this.icon,
  });

  final String title;
  final String? subtitle;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return _ChartShell(
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ChartHeader(
            title: title,
            subtitle: subtitle,
            color: color,
            icon: icon ?? Icons.show_chart_rounded,
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.analytics_outlined, color: color.withValues(alpha: 0.5), size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No data yet',
                    style: GoogleFonts.inter(
                      color: AdminColors.textDim,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  final Color color;
  final String label;
  final String value;
  final String percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: AdminColors.textDim,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: AdminColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              percent,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
