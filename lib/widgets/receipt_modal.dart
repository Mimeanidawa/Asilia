import 'package:flutter/material.dart';

import '../models/product_models.dart';
import '../theme/app_colors.dart';
import '../utils/tzs_format.dart';
import 'herb_image.dart';
import 'pressable_scale.dart';

class ReceiptModal extends StatelessWidget {
  const ReceiptModal({super.key, required this.order});

  final DawaOrder order;

  static void show(BuildContext context, DawaOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ReceiptModal(order: order),
    );
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    final month = months[d.month - 1];
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} $month ${d.year}, $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(order.createdAt);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.forest.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.emerald50,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.2)),
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: AppColors.emerald800, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'RISITI YA MALIPO',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Dawa Asili Tanzania Official Receipt',
                          style: TextStyle(fontSize: 11, color: AppColors.gray500),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.forest),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Delivery Status Tracking Card
                _buildStatusTracker(),
                const SizedBox(height: 18),

                // Main Receipt Paper Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Namba ya Risiti:',
                                style: TextStyle(fontSize: 11, color: AppColors.gray500),
                              ),
                              Text(
                                order.receiptNumber,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.emerald800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.emerald50,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.2)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 14, color: AppColors.emerald800),
                                SizedBox(width: 4),
                                Text(
                                  'IMELIPWA',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.emerald800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tarehe na Saa:', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                          Text(formattedDate, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forest)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Njia ya Malipo:', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                          Text(order.paymentMethod, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forest)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Product Details
                      const Text(
                        'MAELEZO YA BIDHAA / DAWA',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.gray400, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (order.productImageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: HerbImage(
                                url: order.productImageUrl,
                                width: 52,
                                height: 52,
                                fit: BoxFit.cover,
                              ),
                            )
                          else
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.emerald50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.medication_rounded, color: AppColors.emerald800),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.productTitle,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.forest,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Idadi: ${order.quantity}',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.gray600),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEF3F2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        '50% OFF',
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFB42318),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                TzsFormat.full(order.itemsTotal),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forest,
                                ),
                              ),
                              Text(
                                TzsFormat.full(order.originalPrice * order.quantity),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gray400,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Delivery Address
                      const Text(
                        'MAHALI PA KUFIKISHIWA MZIGO (TANZANIA)',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppColors.gray400, letterSpacing: 0.8),
                      ),
                      const SizedBox(height: 10),
                      _buildInfoRow(Icons.person_outline_rounded, 'Mpokeaji:', order.customerName),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.phone_outlined, 'Namba ya Simu:', order.customerPhone),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.location_on_outlined, 'Mkoa & Wilaya:', '${order.region}, ${order.district}'),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.home_outlined, 'Kata / Mtaa:', order.ward),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Cost Breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Dawa (${order.quantity}x):', style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w600)),
                          Text(TzsFormat.full(order.itemsTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forest)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Gharama ya Usafirishaji (Transfer Fee):', style: TextStyle(fontSize: 12, color: AppColors.emerald800, fontWeight: FontWeight.w700)),
                              Text('Usafirishaji nchi nzima Tanzania', style: TextStyle(fontSize: 10, color: AppColors.gray500)),
                            ],
                          ),
                          Text(TzsFormat.full(order.transferFee), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.emerald800)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Total Paid
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Jumla Iliyolipwa:',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColors.forest,
                            ),
                          ),
                          Text(
                            TzsFormat.full(order.totalAmount),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.emerald800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                PressableScale(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: AppColors.forest,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.forest.withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'Nimeelewa (Funga Risiti)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.emerald800),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray500),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.forest,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusTracker() {
    final status = order.deliveryStatus;
    final isPending = status == DawaDeliveryStatus.pending;
    final isOnTransit = status == DawaDeliveryStatus.onTransit;
    final isDelivered = status == DawaDeliveryStatus.delivered;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'HALI YA MZIGO WAKO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDelivered
                      ? AppColors.emerald50
                      : (isOnTransit ? const Color(0xFFEFF8FF) : const Color(0xFFFEFBE8)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.deliveryStatusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isDelivered
                        ? AppColors.emerald800
                        : (isOnTransit ? const Color(0xFF175CD3) : const Color(0xFFB54708)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 3-Step Timeline
          Row(
            children: [
              _buildTimelineStep('Inasubiri', true, isPending),
              _buildTimelineConnector(isOnTransit || isDelivered),
              _buildTimelineStep('Iko Safarini', isOnTransit || isDelivered, isOnTransit),
              _buildTimelineConnector(isDelivered),
              _buildTimelineStep('Imepokelewa', isDelivered, isDelivered),
            ],
          ),
          if (order.trackingInfo.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.emerald800),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.trackingInfo,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.forest, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimelineStep(String label, bool active, bool current) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? AppColors.forest : AppColors.gray200,
              border: current
                  ? Border.all(color: AppColors.amber, width: 2.5)
                  : null,
            ),
            child: Center(
              child: active
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : const SizedBox.shrink(),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: current ? FontWeight.w800 : FontWeight.w600,
              color: active ? AppColors.forest : AppColors.gray400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineConnector(bool active) {
    return Container(
      width: 24,
      height: 2,
      color: active ? AppColors.forest : AppColors.gray200,
      margin: const EdgeInsets.only(bottom: 16),
    );
  }
}
