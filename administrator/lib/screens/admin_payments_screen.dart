import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';
import '../widgets/admin_ui.dart';

class AdminPaymentsScreen extends StatefulWidget {
  const AdminPaymentsScreen({super.key});

  @override
  State<AdminPaymentsScreen> createState() => _AdminPaymentsScreenState();
}

class _AdminPaymentsScreenState extends State<AdminPaymentsScreen> {
  String _filter = 'all'; // all | paid | pending | failed

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Always load full payment history when opening Malipo.
      context.read<AdminProvider>().fetchAdminPayments();
    });
  }

  List<AdminPayment> _filtered(List<AdminPayment> all) {
    switch (_filter) {
      case 'paid':
        return all.where((p) => p.isPaid).toList();
      case 'pending':
        return all.where((p) => p.isPending).toList();
      case 'failed':
        return all.where((p) => p.isFailed).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final payments = _filtered(provider.payments);
    final paidToday = provider.stats.paymentsToday;
    final todayRevenue = provider.stats.todayRevenue;

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
              title: 'Malipo',
              subtitle: provider.payments.isEmpty
                  ? 'Historia ya malipo yote'
                  : '${payments.length} · ${provider.payments.length} yote'
                      '${provider.lastLiveSyncAt != null ? ' · ${_ago(provider.lastLiveSyncAt!)}' : ''}',
              actions: [
                AdminStatusBadge(
                  label: provider.liveSyncing ? 'Sync…' : 'Live',
                  pulse: !provider.liveSyncing,
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryChip(
                          label: 'Leo',
                          value: TzsFormat.compact(todayRevenue),
                          color: AdminColors.amber,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryChip(
                          label: 'Malipo leo',
                          value: '$paidToday',
                          color: AdminColors.emerald,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _SummaryChip(
                          label: 'Jumla',
                          value: '${provider.stats.paymentCount}',
                          color: AdminColors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'Zote',
                          active: _filter == 'all',
                          onTap: () => setState(() => _filter = 'all'),
                        ),
                        _FilterChip(
                          label: 'Imelipwa',
                          active: _filter == 'paid',
                          onTap: () => setState(() => _filter = 'paid'),
                        ),
                        _FilterChip(
                          label: 'Inasubiri',
                          active: _filter == 'pending',
                          onTap: () => setState(() => _filter = 'pending'),
                        ),
                        _FilterChip(
                          label: 'Imeshindwa',
                          active: _filter == 'failed',
                          onTap: () => setState(() => _filter = 'failed'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (payments.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.payments_outlined,
                      title: 'Hakuna malipo',
                      subtitle: 'Malipo ya watumiaji yataonekana hapa papo hapo',
                    )
                  else
                    ...payments.map((p) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: PaymentHistoryTile(payment: p),
                        )),
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
    if (diff.inSeconds < 60) return 'sasa hivi';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m iliyopita';
    return DateFormat('HH:mm').format(dt);
  }
}

class PaymentHistoryTile extends StatelessWidget {
  const PaymentHistoryTile({super.key, required this.payment});

  final AdminPayment payment;

  @override
  Widget build(BuildContext context) {
    final color = _color(payment);
    final time = _timeAgo(payment.paidAt);

    return AdminSurface(
      accentColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon(payment), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.customerName,
                  style: GoogleFonts.plusJakartaSans(
                    color: AdminColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    payment.kindLabel,
                    if (payment.title.isNotEmpty) payment.title,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: AdminColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                if (payment.reference.isNotEmpty)
                  Text(
                    payment.reference,
                    style: GoogleFonts.plusJakartaSans(
                      color: AdminColors.textDim,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TzsFormat.compact(payment.amount.toDouble()),
                style: GoogleFonts.plusJakartaSans(
                  color: payment.isPaid ? AdminColors.amber : AdminColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  payment.statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                time,
                style: GoogleFonts.plusJakartaSans(
                  color: AdminColors.textDim,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _icon(AdminPayment p) {
    switch (p.kind) {
      case 'premium':
        return Icons.workspace_premium_rounded;
      case 'product':
        return Icons.medication_rounded;
      case 'content':
        return Icons.article_rounded;
      default:
        return Icons.payments_rounded;
    }
  }

  Color _color(AdminPayment p) {
    if (p.isFailed) return AdminColors.error;
    if (p.isPending) return AdminColors.blue;
    switch (p.kind) {
      case 'premium':
        return AdminColors.purple;
      case 'product':
        return AdminColors.emerald;
      default:
        return AdminColors.amber;
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'sasa';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AdminColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AdminColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: active ? AdminColors.emeraldGlow : AdminColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: active
                    ? AdminColors.emerald.withValues(alpha: 0.45)
                    : AdminColors.cardBorder,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: active ? AdminColors.emerald : AdminColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
