import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_models.dart';
import '../services/dawa_order_service.dart';
import '../services/payment_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/tzs_format.dart';
import 'herb_image.dart';
import 'pressable_scale.dart';
import 'receipt_modal.dart';

enum _OrderSheetStep { details, processing, success }

class OrderProductSheet extends StatefulWidget {
  const OrderProductSheet({super.key, required this.product});

  final DawaProduct product;

  static void show(BuildContext context, DawaProduct product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => OrderProductSheet(product: product),
    );
  }

  @override
  State<OrderProductSheet> createState() => _OrderProductSheetState();
}

class _OrderProductSheetState extends State<OrderProductSheet> {
  int _quantity = 1;
  String _selectedRegion = 'Dar es Salaam';
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedPaymentMethod = 'M-Pesa';
  String? _errorMessage;
  bool _submitting = false;

  _OrderSheetStep _step = _OrderSheetStep.details;
  int _wizardStep = 0;
  String _statusMessage = 'Tunatuma ombi la malipo...';
  DawaOrder? _currentOrder;

  final List<String> _paymentMethods = [
    'M-Pesa',
    'Airtel Money',
    'Tigo Pesa',
    'HaloPesa',
  ];

  @override
  void initState() {
    super.initState();
    final user = context.read<UserService>().user;
    if (user != null) {
      if (user.fullName.isNotEmpty) _nameController.text = user.fullName;
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneController.text = user.phone!;
        _syncChannelFromPhone(user.phone!);
      }
    }
    _phoneController.addListener(_onPhoneChanged);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onPhoneChanged);
    _districtController.dispose();
    _wardController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _onPhoneChanged() => _syncChannelFromPhone(_phoneController.text);

  void _syncChannelFromPhone(String raw) {
    final channel = PaymentChannel.fromPhone(raw);
    if (channel != null) {
      String methodName;
      switch (channel) {
        case PaymentChannel.mpesa:
          methodName = 'M-Pesa';
        case PaymentChannel.airtelMoney:
          methodName = 'Airtel Money';
        case PaymentChannel.tigoPesa:
          methodName = 'Tigo Pesa';
        case PaymentChannel.haloPesa:
          methodName = 'HaloPesa';
      }
      if (_selectedPaymentMethod != methodName) {
        setState(() => _selectedPaymentMethod = methodName);
      }
    }
  }

  static const int _transferFee = 12000;
  int get _itemsTotal => widget.product.price * _quantity;
  int get _originalTotal => widget.product.originalPrice * _quantity;
  int get _savings => _originalTotal - _itemsTotal;
  int get _totalAmount => _itemsTotal + _transferFee;

  Future<void> _handleOrder() async {
    final name = _nameController.text.trim();
    final rawPhone = _phoneController.text.trim();
    final district = _districtController.text.trim();
    final ward = _wardController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Tafadhali andika jina lako kamili au mpokeaji.');
      return;
    }

    final localPhone = toLocalPaymentPhone(rawPhone);
    if (localPhone == null) {
      setState(() => _errorMessage = 'Tafadhali weka namba sahihi ya simu ya Tanzania (mf. 07XXXXXXXX au 06XXXXXXXX).');
      return;
    }

    if (district.isEmpty) {
      setState(() => _errorMessage = 'Tafadhali andika wilaya yako (mf. Kinondoni, Ilala, Nyamagana, n.k.).');
      return;
    }

    if (ward.isEmpty) {
      setState(() => _errorMessage = 'Tafadhali andika kata au mtaa wako unapoishi.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _submitting = true;
      _step = _OrderSheetStep.processing;
      _statusMessage = 'Tunatuma ombi la malipo kwenye simu yako ($localPhone)...';
    });

    final orderService = context.read<DawaOrderService>();
    final userService = context.read<UserService>();
    final user = userService.user;

    try {
      final initResult = await orderService.initiatePayment(
        product: widget.product,
        quantity: _quantity,
        transferFee: _transferFee,
        customerName: name,
        customerPhone: localPhone,
        region: _selectedRegion,
        district: district,
        ward: ward,
        paymentMethod: _selectedPaymentMethod,
        userId: user?.id,
        userToken: userService.token,
      );

      _currentOrder = initResult.order;
      if (!mounted) return;
      setState(() {
        _statusMessage = initResult.message;
      });

      // Poll for completion (up to 90 seconds)
      final paidOrder = await orderService.waitForOrderPayment(
        initResult.order.id,
        timeout: const Duration(seconds: 90),
        interval: const Duration(seconds: 3),
      );

      if (!mounted) return;
      setState(() {
        _step = _OrderSheetStep.success;
        _currentOrder = paidOrder;
        _statusMessage = 'Malipo Yamethibitishwa Kikamilifu!';
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      Navigator.of(context).pop(); // Close order sheet
      ReceiptModal.show(context, paidOrder);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessage = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('ApiException: ', '');
        _statusMessage = 'PIN haikuwekwa au ombi lilisitishwa. Risiti imehifadhiwa kama INASUBIRI MALIPO.';
      });
    }
  }

  Future<void> _checkStatusNow() async {
    if (_currentOrder == null) return;
    setState(() {
      _statusMessage = 'Inakagua hali ya malipo...';
      _errorMessage = null;
    });

    final orderService = context.read<DawaOrderService>();
    try {
      final order = await orderService.checkPaymentStatus(_currentOrder!.id);
      if (order != null && order.isPaid) {
        setState(() {
          _step = _OrderSheetStep.success;
          _currentOrder = order;
          _statusMessage = 'Malipo yamekamilika!';
        });
        await Future.delayed(const Duration(milliseconds: 1200));
        if (!mounted) return;
        Navigator.of(context).pop();
        ReceiptModal.show(context, order);
      } else {
        setState(() {
          _statusMessage = 'Bado inasubiri uthibitisho wa PIN kwenye simu yako. Hakikisha umeweka PIN.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hitilafu: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    const stepTitles = [
      'HATUA 1 YA 4 • KIASI',
      'HATUA 2 YA 4 • ANWANI',
      'HATUA 3 YA 4 • MALIPO',
      'HATUA 4 YA 4 • THIBITISHA',
    ];
    const stepSubs = [
      'Chagua idadi, kisha endelea',
      'Weka mahali dawa itakapofika',
      'Jina, simu, na njia ya kulipa',
      'Kagua oda yako kisha lipa',
    ];

    var headerTitle = stepTitles[_wizardStep];
    var headerSubtitle = stepSubs[_wizardStep];
    if (_step == _OrderSheetStep.processing) {
      headerTitle = 'UTHIBITISHO WA MALIPO';
      headerSubtitle = 'Ombi la malipo limetumwa kwenye simu yako';
    } else if (_step == _OrderSheetStep.success) {
      headerTitle = 'MALIPO YAMEKAMILIKA';
      headerSubtitle = 'Risiti yako rasmi inafunguka';
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
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
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.2)),
                      ),
                      child: Icon(
                        _step == _OrderSheetStep.processing
                            ? Icons.phone_android_rounded
                            : (_step == _OrderSheetStep.success
                                ? Icons.check_circle_rounded
                                : Icons.shopping_bag_rounded),
                        color: AppColors.emerald800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headerTitle,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          headerSubtitle,
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
            child: _step == _OrderSheetStep.success
                ? _buildSuccessView()
                : (_step == _OrderSheetStep.processing
                    ? _buildProcessingView()
                    : _buildFormView()),
          ),
        ],
      ),
    );
  }

  static const _wizardLabels = ['Kiasi', 'Anwani', 'Malipo', 'Thibitisha'];

  bool _validateWizardStep() {
    if (_wizardStep == 1) {
      if (_districtController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Andika wilaya yako (mf. Kinondoni, Ilala, Nyamagana).');
        return false;
      }
      if (_wardController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Andika kata au mtaa wako unapoishi.');
        return false;
      }
    }
    if (_wizardStep == 2) {
      if (_nameController.text.trim().isEmpty) {
        setState(() => _errorMessage = 'Andika jina lako kamili au jina la mpokeaji.');
        return false;
      }
      if (toLocalPaymentPhone(_phoneController.text.trim()) == null) {
        setState(() => _errorMessage = 'Weka namba sahihi ya simu (mf. 07XXXXXXXX au 06XXXXXXXX).');
        return false;
      }
    }
    setState(() => _errorMessage = null);
    return true;
  }

  void _goForward() {
    if (!_validateWizardStep()) return;
    if (_wizardStep < 3) {
      setState(() => _wizardStep++);
      return;
    }
    _handleOrder();
  }

  void _goBack() {
    if (_wizardStep == 0) return;
    setState(() {
      _wizardStep--;
      _errorMessage = null;
    });
  }

  InputDecoration _fieldDecoration(String hint, {Widget? prefix, String? helper}) {
    return InputDecoration(
      prefixIcon: prefix,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400, fontWeight: FontWeight.w500),
      helperText: helper,
      helperStyle: const TextStyle(fontSize: 11, color: AppColors.emerald800, fontWeight: FontWeight.w600),
      helperMaxLines: 2,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.emerald700, width: 1.6),
      ),
    );
  }

  Widget _buildFormView() {
    return Column(
      children: [
        _buildWizardRail(),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: ListView(
              key: ValueKey(_wizardStep),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              children: [
                if (_wizardStep == 0) _buildQuantityStep(),
                if (_wizardStep == 1) _buildAddressStep(),
                if (_wizardStep == 2) _buildPaymentStep(),
                if (_wizardStep == 3) _buildReviewStep(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECDCA)),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFFB42318), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        _buildWizardFooter(),
      ],
    );
  }

  Widget _buildWizardRail() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < _wizardLabels.length; i++) ...[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  color: i <= _wizardStep ? AppColors.forest : const Color(0xFFD9CBB8),
                ),
              ),
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: i <= _wizardStep ? AppColors.forest : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i <= _wizardStep ? AppColors.forest : const Color(0xFFD9CBB8),
                      width: 1.4,
                    ),
                  ),
                  child: Center(
                    child: i < _wizardStep
                        ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: i == _wizardStep ? Colors.white : AppColors.gray500,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _wizardLabels[i],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: i == _wizardStep ? AppColors.forest : AppColors.gray500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuantityStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                HerbImage(
                  url: widget.product.imageUrl,
                  height: 220,
                  fit: BoxFit.cover,
                  borderRadius: 0,
                ),
                Positioned(
                  left: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.product.badgeText.isNotEmpty ? widget.product.badgeText : 'Punguzo la 50%',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          widget.product.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.forest, height: 1.2),
        ),
        if (widget.product.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            widget.product.subtitle,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.forest.withValues(alpha: 0.7)),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9CBB8)),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Idadi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.forest)),
                    SizedBox(height: 2),
                    Text('Chupa au pakiti', style: TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              _QtyButton(
                icon: Icons.remove_rounded,
                onTap: _quantity > 1 ? () => setState(() => _quantity--) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$_quantity',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.forest),
                ),
              ),
              _QtyButton(
                icon: Icons.add_rounded,
                onTap: () => setState(() => _quantity++),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              TzsFormat.full(widget.product.price),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.emerald800),
            ),
            if (widget.product.originalPrice > widget.product.price) ...[
              const SizedBox(width: 8),
              Text(
                TzsFormat.full(widget.product.originalPrice),
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.gray400,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
            const Spacer(),
            const Text('kwa kila moja', style: TextStyle(fontSize: 12, color: AppColors.gray500, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dawa itafika wapi?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.forest),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tunatuma nchi nzima. Anza na mkoa, kisha wilaya na kata.',
          style: TextStyle(fontSize: 13, color: AppColors.gray600, fontWeight: FontWeight.w600, height: 1.35),
        ),
        const SizedBox(height: 16),
        const Text('Mkoa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD9CBB8)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRegion,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.forest),
              items: DawaOrderService.tanzaniaRegions.map((r) {
                return DropdownMenuItem<String>(
                  value: r,
                  child: Text(r, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forest)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRegion = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Wilaya', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest)),
        const SizedBox(height: 6),
        TextField(
          controller: _districtController,
          textInputAction: TextInputAction.next,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forest),
          decoration: _fieldDecoration('mf. Ilala, Kinondoni, Nyamagana'),
        ),
        const SizedBox(height: 14),
        const Text('Kata au mtaa', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest)),
        const SizedBox(height: 6),
        TextField(
          controller: _wardController,
          textInputAction: TextInputAction.done,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forest),
          decoration: _fieldDecoration('mf. Kariakoo, Mikocheni, Igoma'),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nani anapokea, na lipa vipi?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.forest),
        ),
        const SizedBox(height: 4),
        const Text(
          'Ombi la PIN litatumwa kwenye namba hii.',
          style: TextStyle(fontSize: 13, color: AppColors.gray600, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        const Text('Jina la mpokeaji', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest)),
        const SizedBox(height: 6),
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forest),
          decoration: _fieldDecoration(
            'Jina kamili',
            prefix: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.gray400),
          ),
        ),
        const SizedBox(height: 14),
        const Text('Namba ya simu', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest)),
        const SizedBox(height: 6),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.forest),
          decoration: _fieldDecoration(
            '07XXXXXXXX',
            prefix: const Icon(Icons.phone_outlined, size: 18, color: AppColors.gray400),
            helper: 'Mtandao unachaguliwa kutokana na namba yako.',
          ),
        ),
        const SizedBox(height: 16),
        const Text('Mtandao wa malipo', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.forest)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethods.map((method) {
            final selected = _selectedPaymentMethod == method;
            return PressableScale(
              onTap: () => setState(() => _selectedPaymentMethod = method),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? AppColors.forest : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: selected ? AppColors.forest : const Color(0xFFD9CBB8)),
                ),
                child: Text(
                  method,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.forest,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kagua kabla ya kulipa',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.forest),
        ),
        const SizedBox(height: 12),
        _reviewTile(
          'Dawa',
          '${widget.product.title}  ×  $_quantity',
          onEdit: () => setState(() => _wizardStep = 0),
        ),
        const SizedBox(height: 8),
        _reviewTile(
          'Anwani',
          '$_selectedRegion, ${_districtController.text.trim()}, ${_wardController.text.trim()}',
          onEdit: () => setState(() => _wizardStep = 1),
        ),
        const SizedBox(height: 8),
        _reviewTile(
          'Malipo',
          '${_nameController.text.trim()}\n${_phoneController.text.trim()}  •  $_selectedPaymentMethod',
          onEdit: () => setState(() => _wizardStep = 2),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD9CBB8)),
          ),
          child: Column(
            children: [
              _moneyRow('Dawa ($_quantity)', TzsFormat.full(_itemsTotal)),
              if (_savings > 0) ...[
                const SizedBox(height: 6),
                _moneyRow('Punguzo', '- ${TzsFormat.full(_savings)}', valueColor: const Color(0xFFB42318)),
              ],
              const SizedBox(height: 6),
              _moneyRow('Usafirishaji', TzsFormat.full(_transferFee)),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumla', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.forest)),
                  Text(
                    TzsFormat.full(_totalAmount),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.emerald800),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _reviewTile(String label, String value, {required VoidCallback onEdit}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD9CBB8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.gray500, letterSpacing: 0.4)),
                const SizedBox(height: 3),
                Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.forest, height: 1.3)),
              ],
            ),
          ),
          TextButton(
            onPressed: onEdit,
            child: const Text('Badili'),
          ),
        ],
      ),
    );
  }

  Widget _moneyRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(fontSize: 13, color: valueColor ?? AppColors.forest, fontWeight: FontWeight.w800)),
      ],
    );
  }

  Widget _buildWizardFooter() {
    final isLast = _wizardStep == 3;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F1E6),
        border: Border(top: BorderSide(color: Color(0xFFD9CBB8))),
      ),
      child: Row(
        children: [
          if (_wizardStep > 0) ...[
            PressableScale(
              onTap: _submitting ? () {} : _goBack,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFD9CBB8)),
                ),
                child: const Text('Rudi', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.forest)),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: PressableScale(
              onTap: _submitting ? () {} : _goForward,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F4C3A), Color(0xFF1E755B)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.4),
                        )
                      : Text(
                          isLast ? 'Lipa ${TzsFormat.full(_totalAmount)}' : 'Endelea',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingView() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.emerald50,
                  border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.2), width: 2),
                ),
              ),
              const SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.emerald800,
                ),
              ),
              const Icon(
                Icons.phone_android_rounded,
                size: 38,
                color: AppColors.emerald800,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'THIBITISHA MALIPO KWENYE SIMU YAKO',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payment_rounded, size: 16, color: AppColors.emerald800),
                const SizedBox(width: 6),
                Text(
                  '$_selectedPaymentMethod  •  TZS ${TzsFormat.full(_totalAmount)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppColors.emerald800,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
            boxShadow: AppColors.elevationSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: AppColors.emerald800, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ombi la malipo limetumwa moja kwa moja kwenye namba yako ya simu: ${_phoneController.text}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.forest,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(height: 1, color: AppColors.borderLight),
              ),
              const Text(
                'FUATA HATUA HIZI RAHISI KWENYE SIMU YAKO:',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: AppColors.gray500,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildStepRow('1', 'Tazama skrini ya simu yako', 'Ujumbe wa dirisha dogo la $_selectedPaymentMethod utatokea sasa hivi.'),
              const SizedBox(height: 10),
              _buildStepRow('2', 'Weka Namba yako ya Siri (PIN)', 'Weka PIN yako kuthibitisha malipo ya TZS ${TzsFormat.full(_totalAmount)}.'),
              const SizedBox(height: 10),
              _buildStepRow('3', 'Subiri Risiti Rasmi', 'Mara baada ya kuweka PIN, risiti yako itafunguka papo hapo hapa kwenye app.'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFEFBE8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFEE4E2)),
          ),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFB54708),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFB54708),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECDCA)),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFFB42318),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        // Action buttons
        PressableScale(
          onTap: _checkStatusNow,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'Nimeshaweka PIN (Angalia Malipo)',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: _handleOrder,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.emerald800),
                label: const Text(
                  'Tuma Tena Ombi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.emerald800,
                  ),
                ),
              ),
            ),
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _step = _OrderSheetStep.details;
                    _wizardStep = 2;
                    _submitting = false;
                    _errorMessage = null;
                  });
                },
                child: const Text(
                  'Badili Taarifa / Namba',
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
        if (_currentOrder != null) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton.icon(
              onPressed: () {
                final pending = _currentOrder!;
                Navigator.of(context).pop();
                ReceiptModal.show(context, pending);
              },
              icon: const Icon(Icons.receipt_long_rounded, size: 16, color: AppColors.emerald800),
              label: const Text(
                'Tazama Risiti (Inasubiri Malipo)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.emerald800,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStepRow(String number, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.emerald50,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.3)),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: AppColors.emerald800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.forest,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.gray500,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.emerald700.withValues(alpha: 0.3), width: 3),
            ),
            child: const Icon(Icons.check_circle_rounded, size: 52, color: AppColors.emerald800),
          ),
          const SizedBox(height: 20),
          const Text(
            'MALIPO YAMETHIBITISHWA!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: AppColors.forest,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Risiti namba ${_currentOrder?.receiptNumber ?? ''} imetengenezwa kikamilifu.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.gray600, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(color: AppColors.emerald800, strokeWidth: 2),
              ),
              SizedBox(width: 10),
              Text(
                'Inafungua risiti yako rasmi...',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.emerald800),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Material(
      color: enabled ? AppColors.forest : const Color(0xFFE7DDD0),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: enabled ? Colors.white : AppColors.gray400, size: 20),
        ),
      ),
    );
  }
}
