import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_order_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';
import '../widgets/url_image.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String _filter = 'all'; // 'all', 'pending', 'on_transit', 'delivered'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAdminOrders();
    });
  }

  List<AdminOrder> _filterOrders(List<AdminOrder> all) {
    if (_filter == 'all') return all;
    return all.where((o) => o.deliveryStatus == _filter).toList();
  }

  void _promptTransitStatus(AdminOrder order) {
    final trackingCtrl = TextEditingController(text: order.trackingInfo.isNotEmpty ? order.trackingInfo : 'Basi la...');
    final notesCtrl = TextEditingController(text: order.adminNotes);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Text('Weka Mzigo Safarini', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mteja: ${order.customerName} (${order.customerPhone})',
                style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 12)),
            Text('Mahali: ${order.region}, ${order.district}, ${order.ward}',
                style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 12)),
            const SizedBox(height: 14),
            Text('Taarifa za Usafirishaji / Jina la Basi:',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            TextField(
              controller: trackingCtrl,
              style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Mf. Basi la Abood — Stendi ya Moshi (Risiti 4821)',
                hintStyle: GoogleFonts.plusJakartaSans(color: AdminColors.textMuted, fontSize: 12),
                filled: true,
                fillColor: AdminColors.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Ghairi', style: GoogleFonts.plusJakartaSans(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await context.read<AdminProvider>().updateOrderStatus(
                order.id,
                'on_transit',
                trackingInfo: trackingCtrl.text.trim(),
                adminNotes: notesCtrl.text.trim(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Oda imewekwa Safarini!' : 'Imeshindwa kusasisha'),
                    backgroundColor: ok ? AdminColors.blue : AdminColors.rose,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.blue),
            child: Text('Thibitisha Iko Safarini', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _markDelivered(AdminOrder order) async {
    final ok = await context.read<AdminProvider>().updateOrderStatus(order.id, 'delivered');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Oda imethibitishwa kupokelewa!' : 'Imeshindwa kusasisha'),
          backgroundColor: ok ? AdminColors.emerald : AdminColors.rose,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final allOrders = provider.adminOrders;
    final orders = _filterOrders(allOrders);
    final loading = provider.ordersLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchAdminOrders,
          color: AdminColors.emerald,
          backgroundColor: AdminColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Maagizo & Risiti',
                        style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Fuatilia oda za dawa zilizolipwa na thibitisha usafirishaji',
                        style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.textDim,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Filter chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('Zote (${allOrders.length})', 'all'),
                            const SizedBox(width: 8),
                            _filterChip('Inasubiri (${allOrders.where((o) => o.deliveryStatus == 'pending').length})', 'pending'),
                            const SizedBox(width: 8),
                            _filterChip('Safarini (${allOrders.where((o) => o.deliveryStatus == 'on_transit').length})', 'on_transit'),
                            const SizedBox(width: 8),
                            _filterChip('Zilizopokelewa (${allOrders.where((o) => o.deliveryStatus == 'delivered').length})', 'delivered'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (loading && orders.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AdminColors.emerald)),
                )
              else if (orders.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 56, color: AdminColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Hakuna maagizo katika kundi hili', style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final order = orders[i];
                        return _OrderAdminCard(
                          order: order,
                          onTransitTap: () => _promptTransitStatus(order),
                          onDeliveredTap: () => _markDelivered(order),
                        );
                      },
                      childCount: orders.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AdminColors.emerald : AdminColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active ? AdminColors.emerald : AdminColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
            color: active ? const Color(0xFF052E16) : AdminColors.textDim,
          ),
        ),
      ),
    );
  }
}

class _OrderAdminCard extends StatelessWidget {
  const _OrderAdminCard({
    required this.order,
    required this.onTransitTap,
    required this.onDeliveredTap,
  });

  final AdminOrder order;
  final VoidCallback onTransitTap;
  final VoidCallback onDeliveredTap;

  @override
  Widget build(BuildContext context) {
    final isPending = order.deliveryStatus == 'pending';
    final isOnTransit = order.deliveryStatus == 'on_transit';
    final isDelivered = order.deliveryStatus == 'delivered';

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isDelivered) {
      statusColor = AdminColors.emerald;
      statusLabel = 'IMEPOKELEWA';
      statusIcon = Icons.check_circle_rounded;
    } else if (isOnTransit) {
      statusColor = AdminColors.blue;
      statusLabel = 'IKO SAFARINI';
      statusIcon = Icons.local_shipping_rounded;
    } else {
      statusColor = AdminColors.amber;
      statusLabel = 'INASUBIRI';
      statusIcon = Icons.hourglass_top_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Receipt & Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: AdminColors.emerald, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      order.receiptNumber,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: GoogleFonts.plusJakartaSans(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AdminColors.divider, height: 18),

            // Product summary
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 50,
                    height: 50,
                    color: AdminColors.surface,
                    child: UrlImage(
                      url: order.productImageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.productTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Idadi: ${order.quantity} x ${TzsFormat.full(order.unitPrice)} + Usafirishaji: ${TzsFormat.full(order.transferFee)} = ${TzsFormat.full(order.totalAmount)}',
                        style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.emerald,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Customer and Location info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AdminColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person_outline, size: 14, color: AdminColors.textDim),
                      const SizedBox(width: 6),
                      Text(
                        '${order.customerName} — Simu: ${order.customerPhone}',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AdminColors.rose),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Mkoa: ${order.region}, Wilaya: ${order.district}, Kata: ${order.ward}',
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textDim,
                            fontSize: 11.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (order.trackingInfo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.directions_bus_outlined, size: 14, color: AdminColors.blue),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Usafirishaji: ${order.trackingInfo}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.blue,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Action Buttons
            Row(
              children: [
                if (!isDelivered) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onTransitTap,
                      icon: const Icon(Icons.local_shipping_rounded, size: 14),
                      label: Text(
                        isOnTransit ? 'Sasisha Basi/Mzigo' : 'Weka Safarini',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDeliveredTap,
                      icon: const Icon(Icons.check_circle_outline, size: 14),
                      label: Text(
                        'Umefika',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.emerald,
                        foregroundColor: const Color(0xFF052E16),
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ] else ...[
                  const Expanded(
                    child: Center(
                      child: Text(
                        '✓ Mzigo Umekwishafikishwa kwa Mteja',
                        style: TextStyle(color: AdminColors.emerald, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
