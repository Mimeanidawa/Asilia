import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/payment_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/tzs_format.dart';

enum AuraxPaymentResult { success, cancelled, failed }

/// Opens an Aurax Pay payment sheet.
Future<AuraxPaymentResult?> showAuraxPayment(
  BuildContext context, {
  required PaymentType type,
  required String title,
  required String subtitle,
  required int amount,
  String? contentId,
}) {
  return showModalBottomSheet<AuraxPaymentResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: false,
    builder: (ctx) => _AuraxPaymentSheet(
      type: type,
      title: title,
      subtitle: subtitle,
      amount: amount,
      contentId: contentId,
    ),
  );
}

class _AuraxPaymentSheet extends StatefulWidget {
  const _AuraxPaymentSheet({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    this.contentId,
  });

  final PaymentType type;
  final String title;
  final String subtitle;
  final int amount;
  final String? contentId;

  @override
  State<_AuraxPaymentSheet> createState() => _AuraxPaymentSheetState();
}

class _AuraxPaymentSheetState extends State<_AuraxPaymentSheet> {
  final _phoneCtrl = TextEditingController();
  final _paymentService = PaymentService();

  _PayStep _step = _PayStep.details;
  String? _error;
  String? _statusMessage;
  PaymentChannel _channel = PaymentChannel.mpesa;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserService>().user;
    final phone = user?.phone;
    if (phone != null && phone.isNotEmpty) {
      _phoneCtrl.text = _displayPhone(phone);
    }
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  String _displayPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('255')) return '0${digits.substring(3)}';
    return raw;
  }

  String _normalizePhone(String input) {
    var digits = input.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = '255${digits.substring(1)}';
    if (digits.length == 9) digits = '255$digits';
    return digits;
  }

  Future<void> _pay() async {
    final userService = context.read<UserService>();
    if (!userService.isLoggedIn) {
      setState(() => _error = 'Ingia kwanza ili kulipa');
      return;
    }

    final phone = _normalizePhone(_phoneCtrl.text.trim());
    if (phone.length < 12) {
      setState(() => _error = 'Weka namba sahihi ya simu (07XXXXXXXX)');
      return;
    }

    setState(() {
      _error = null;
      _step = _PayStep.processing;
      _statusMessage = 'Tunatuma ombi la malipo...';
    });

    try {
      final init = await _paymentService.initiate(
        type: widget.type,
        phone: phone,
        channel: _channel,
        token: userService.token!,
        contentId: widget.contentId,
      );

      if (init.alreadyPurchased || init.alreadyActive) {
        await userService.refreshProfile();
        if (!mounted) return;
        Navigator.pop(context, AuraxPaymentResult.success);
        return;
      }

      setState(() => _statusMessage = init.message);

      final result = await _paymentService.waitForCompletion(
        paymentId: init.payment.id,
        token: userService.token!,
      );

      if (result.purchasedContentIds.isNotEmpty) {
        userService.purchasedContentIds = result.purchasedContentIds;
      }
      await userService.refreshProfile();

      if (!mounted) return;
      setState(() {
        _step = _PayStep.success;
        _statusMessage = 'Malipo yamekamilika!';
      });
      await Future.delayed(const Duration(milliseconds: 1200));
      if (mounted) Navigator.pop(context, AuraxPaymentResult.success);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _step = _PayStep.details;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.gray200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _header(),
                  const SizedBox(height: 20),
                  if (_step == _PayStep.success)
                    _successView()
                  else if (_step == _PayStep.processing)
                    _processingView()
                  else ...[
                    _amountCard(),
                    const SizedBox(height: 16),
                    _stepsGuide(),
                    const SizedBox(height: 16),
                    _channelPicker(),
                    const SizedBox(height: 16),
                    _phoneField(),
                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: AppColors.red600,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    _payButton(),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () =>
                          Navigator.pop(context, AuraxPaymentResult.cancelled),
                      child: const Text(
                        'Ghairi',
                        style: TextStyle(
                          color: AppColors.gray400,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.forest, AppColors.emerald800],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fungua Maudhui yote',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                ),
              ),
              Text(
                'M-Pesa • Mixx by Yas • Airtel Money • HaloPesa',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.gray400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _amountCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.amber.withValues(alpha: 0.12),
            AppColors.emerald50,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray500,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                TzsFormat.full(widget.amount),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.forest,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.type == PaymentType.premium
                      ? '/ siku 30'
                      : '/ makala hii',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.gray400,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stepsGuide() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emerald50.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _stepRow('1', 'Weka namba ya simu ya malipo'),
          const SizedBox(height: 8),
          _stepRow('2', 'Bonyeza "Lipa Sasa" — utapokea ombi kwenye simu'),
          const SizedBox(height: 8),
          _stepRow('3', 'Thibitisha malipo kwenye simu yako'),
          const SizedBox(height: 8),
          _stepRow('4', 'Maudhui yatafunguliwa mara malipo yatakapokamilika'),
        ],
      ),
    );
  }

  Widget _stepRow(String num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.forest,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            num,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.gray600,
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _phoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Namba ya simu ya malipo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.forest,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
          ],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.forest,
          ),
          decoration: InputDecoration(
            hintText: '07XX XXX XXX',
            hintStyle: TextStyle(
              color: AppColors.gray400.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
            prefixIcon: const Icon(
              Icons.phone_android_rounded,
              color: AppColors.emerald800,
              size: 20,
            ),
            filled: true,
            fillColor: AppColors.emerald50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: AppColors.forest.withValues(alpha: 0.08),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.emerald800,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _channelPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mtandao wa malipo',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.forest,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PaymentChannel.values.map((channel) {
            return ChoiceChip(
              label: Text(channel.label),
              selected: _channel == channel,
              onSelected: (_) => setState(() => _channel = channel),
              selectedColor: AppColors.emerald50,
              labelStyle: TextStyle(
                color: AppColors.forest,
                fontWeight: _channel == channel
                    ? FontWeight.w800
                    : FontWeight.w600,
              ),
              side: BorderSide(
                color: _channel == channel
                    ? AppColors.emerald800
                    : AppColors.gray200,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _payButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _pay,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_rounded, size: 18),
            SizedBox(width: 8),
            Text(
              'Lipa Sasa kwa Aurax Pay',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _processingView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          const SizedBox(
            width: 56,
            height: 56,
            child: CircularProgressIndicator(
              color: AppColors.forest,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Subiri uthibitisho wa malipo',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _statusMessage ?? 'Angalia simu yako na thibitisha malipo',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray500,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Usifunge programu hii',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.amber,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _successView() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.emerald800,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Malipo Yamekamilika!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.type == PaymentType.premium
                ? 'Premium yako imeamilishwa'
                : 'Makala imefunguliwa moja kwa moja',
            style: TextStyle(fontSize: 13, color: AppColors.gray500),
          ),
        ],
      ),
    );
  }
}

enum _PayStep { details, processing, success }
