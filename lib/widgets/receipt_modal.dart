import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_models.dart';
import '../services/dawa_order_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/tzs_format.dart';
import 'herb_image.dart';
import 'pressable_scale.dart';

class ReceiptModal extends StatefulWidget {
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

  @override
  State<ReceiptModal> createState() => _ReceiptModalState();
}

class _ReceiptModalState extends State<ReceiptModal> {
  late DawaOrder _currentOrder;
  bool _isProcessingPayment = false;
  bool _isCheckingStatus = false;
  String? _statusNote;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  static String _formatDate(DateTime d) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ago', 'Sep', 'Okt', 'Nov', 'Des'];
    final month = months[d.month - 1];
    final hour = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '${d.day} $month ${d.year}, $hour:$min';
  }

  Future<void> _handlePayNow() async {
    setState(() {
      _isProcessingPayment = true;
      _statusNote = 'Tunatuma ombi jipya la malipo kwenye simu yako ${_currentOrder.customerPhone}...';
    });

    final orderService = context.read<DawaOrderService>();
    final userService = context.read<UserService>();

    try {
      final res = await orderService.retryPaymentForOrder(
        order: _currentOrder,
        userToken: userService.token,
      );

      if (!mounted) return;
      setState(() {
        _currentOrder = res.order;
        _statusNote = res.message;
      });

      // Poll for completion (up to 90 seconds)
      final paid = await orderService.waitForOrderPayment(
        _currentOrder.id,
        timeout: const Duration(seconds: 90),
        interval: const Duration(seconds: 3),
      );

      if (!mounted) return;
      setState(() {
        _currentOrder = paid;
        _isProcessingPayment = false;
        _statusNote = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessingPayment = false;
        _statusNote = e.toString().replaceAll('Exception: ', '').replaceAll('ApiException: ', '');
      });
    }
  }

  Future<void> _handleCheckStatus() async {
    setState(() {
      _isCheckingStatus = true;
    });

    final orderService = context.read<DawaOrderService>();
    try {
      final updated = await orderService.checkPaymentStatus(_currentOrder.id);
      if (!mounted) return;
      if (updated != null) {
        setState(() {
          _currentOrder = updated;
          if (updated.isPaid) {
            _statusNote = null;
          } else {
            _statusNote = 'Bado inasubiri kuweka PIN kwenye simu yako.';
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statusNote = 'Hitilafu ya kuangalia hali: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _formatDate(_currentOrder.createdAt);
    final isPaid = _currentOrder.isPaid;

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
                        color: isPaid ? AppColors.emerald50 : const Color(0xFFFEFBE8),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isPaid
                              ? AppColors.emerald700.withValues(alpha: 0.2)
                              : const Color(0xFFFEE4E2),
                        ),
                      ),
                      child: Icon(
                        isPaid ? Icons.receipt_long_rounded : Icons.pending_actions_rounded,
                        color: isPaid ? AppColors.emerald800 : const Color(0xFFB54708),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPaid ? 'RISITI YA MALIPO' : 'RISITI (INASUBIRI MALIPO)',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: isPaid ? AppColors.forest : const Color(0xFFB54708),
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          isPaid
                              ? 'Dawa Asili Tanzania Official Receipt'
                              : 'Dawa Asili Tanzania Pending Receipt',
                          style: const TextStyle(fontSize: 11, color: AppColors.gray500),
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
                // Status Tracking or Pending Payment Alert Card
                if (isPaid) _buildStatusTracker() else _buildPendingPaymentNotice(),
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
                    border: Border.all(
                      color: isPaid
                          ? AppColors.forest.withValues(alpha: 0.08)
                          : const Color(0xFFFECDCA).withValues(alpha: 0.6),
                    ),
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
                                _currentOrder.receiptNumber,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: isPaid ? AppColors.emerald800 : const Color(0xFFB54708),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isPaid ? AppColors.emerald50 : const Color(0xFFFEFBE8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isPaid
                                    ? AppColors.emerald700.withValues(alpha: 0.2)
                                    : const Color(0xFFFEE4E2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPaid ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                                  size: 14,
                                  color: isPaid ? AppColors.emerald800 : const Color(0xFFB54708),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPaid ? 'IMELIPWA' : 'INASUBIRI MALIPO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    color: isPaid ? AppColors.emerald800 : const Color(0xFFB54708),
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
                          Text(
                            isPaid ? _currentOrder.paymentMethod : '${_currentOrder.paymentMethod} (Inasubiri PIN)',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forest),
                          ),
                        ],
                      ),
                      if (isPaid && _currentOrder.paymentReference.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Kumbukumbu:', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                            Text(_currentOrder.paymentReference, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald800)),
                          ],
                        ),
                      ],
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
                          if (_currentOrder.productImageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: HerbImage(
                                url: _currentOrder.productImageUrl,
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
                                  _currentOrder.productTitle,
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
                                      'Idadi: ${_currentOrder.quantity}',
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
                                TzsFormat.full(_currentOrder.itemsTotal),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forest,
                                ),
                              ),
                              Text(
                                TzsFormat.full(_currentOrder.originalPrice * _currentOrder.quantity),
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
                      _buildInfoRow(Icons.person_outline_rounded, 'Mpokeaji:', _currentOrder.customerName),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.phone_outlined, 'Namba ya Simu:', _currentOrder.customerPhone),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.location_on_outlined, 'Mkoa & Wilaya:', '${_currentOrder.region}, ${_currentOrder.district}'),
                      const SizedBox(height: 6),
                      _buildInfoRow(Icons.home_outlined, 'Kata / Mtaa:', _currentOrder.ward),

                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Cost Breakdown
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Dawa (${_currentOrder.quantity}x):', style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w600)),
                          Text(TzsFormat.full(_currentOrder.itemsTotal), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.forest)),
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
                          Text(TzsFormat.full(_currentOrder.transferFee), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.emerald800)),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(height: 1, color: AppColors.borderLight),
                      ),

                      // Total Paid / Due
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPaid ? 'Jumla Iliyolipwa:' : 'Jumla Inayotakiwa Kulipwa:',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: isPaid ? AppColors.forest : const Color(0xFFB54708),
                            ),
                          ),
                          Text(
                            TzsFormat.full(_currentOrder.totalAmount),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isPaid ? AppColors.emerald800 : const Color(0xFFB54708),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                if (isPaid)
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
                  )
                else
                  Column(
                    children: [
                      PressableScale(
                        onTap: _isProcessingPayment ? null : _handlePayNow,
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
                          child: Center(
                            child: _isProcessingPayment
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Lipa Sasa (TZS ${TzsFormat.full(_currentOrder.totalAmount)})',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isCheckingStatus ? null : _handleCheckStatus,
                              icon: _isCheckingStatus
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.emerald800,
                                      ),
                                    )
                                  : const Icon(Icons.refresh_rounded, size: 16, color: AppColors.emerald800),
                              label: const Text(
                                'Kagua Malipo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emerald800,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(color: AppColors.emerald800, width: 1.2),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text(
                                'Lipa Baadaye',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.gray500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
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

  Widget _buildPendingPaymentNotice() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFBE8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFEE4E2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE8E8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFFB54708)),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'MALIPO BADO HAYAJAKAMILIKA',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB54708),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _statusNote ??
                'Risiti hii inasubiri malipo. PIN haikuwekwa au ombi la malipo lilisitishwa. Bofya kitufe cha "Lipa Sasa" hapa chini ili kukamilisha malipo na kuanza usafirishaji wa dawa yako kwenda ${_currentOrder.region}, ${_currentOrder.district}.',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF7A271A),
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker() {
    final status = _currentOrder.deliveryStatus;
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
                  _currentOrder.deliveryStatusLabel,
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
          if (_currentOrder.trackingInfo.isNotEmpty) ...[
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
                      _currentOrder.trackingInfo,
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
