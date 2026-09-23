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
        _statusMessage = 'Muda wa kusubiri umekwisha au kuna hitilafu.';
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
      if (order != null && order.paymentStatus == 'paid') {
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

    String headerTitle = 'AGIZA & NUNUA DAWA HII';
    String headerSubtitle = 'Utoaji nchi nzima Tanzania kwa uhakika';
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

  Widget _buildFormView() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Product Summary Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
            boxShadow: AppColors.elevationSm,
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: HerbImage(
                  url: widget.product.imageUrl,
                  width: 65,
                  height: 65,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3F2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'PUNGUZO LA HADI 50% 🔥',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFB42318),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.product.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColors.forest,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          TzsFormat.full(widget.product.price),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.emerald800,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          TzsFormat.full(widget.product.originalPrice),
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
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 1. Quantity Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Idadi ya Dawa (Chupa/Pakiti):',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.forest.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                    icon: const Icon(Icons.remove_rounded, size: 18),
                    color: AppColors.forest,
                  ),
                  Text(
                    '$_quantity',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _quantity++),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    color: AppColors.forest,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 2. Location in Tanzania
        const Text(
          'MAHALI ULIPO NCHINI TANZANIA',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.emerald800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        // Mkoa (Region Dropdown)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRegion,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.forest),
              items: DawaOrderService.tanzaniaRegions.map((r) {
                return DropdownMenuItem<String>(
                  value: r,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: AppColors.emerald700),
                      const SizedBox(width: 8),
                      Text(r, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.forest)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedRegion = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Wilaya & Kata
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _districtController,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.forest),
                decoration: InputDecoration(
                  hintText: 'Wilaya (mf. Ilala)',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.emerald700, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _wardController,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.forest),
                decoration: InputDecoration(
                  hintText: 'Kata / Mtaa',
                  hintStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.emerald700, width: 1.5),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Recipient Info
        const Text(
          'TAARIFA ZA MPOKEAJI & SIMU',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.emerald800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _nameController,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.forest),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.gray400),
            hintText: 'Jina lako kamili la mpokeaji',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.emerald700, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.forest),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: AppColors.gray400),
            hintText: 'Namba ya simu (mf. 07XXXXXXXX)',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.gray400),
            helperText: 'Ombi la malipo (USSD) litatumwa moja kwa moja kwenye namba hii.',
            helperStyle: const TextStyle(fontSize: 10.5, color: AppColors.emerald800, fontWeight: FontWeight.w600),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.emerald700, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 4. Payment Method
        const Text(
          'CHAGUA MTANDAO WA MALIPO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: AppColors.emerald800,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _paymentMethods.map((method) {
            final selected = _selectedPaymentMethod == method;
            return InkWell(
              onTap: () => setState(() => _selectedPaymentMethod = method),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.forest : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? AppColors.forest : AppColors.borderLight,
                  ),
                ),
                child: Text(
                  method,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : AppColors.forest,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Total Summary Box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.forest.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Dawa (${_quantity}x):', style: const TextStyle(fontSize: 12, color: AppColors.gray600, fontWeight: FontWeight.w600)),
                  Text(TzsFormat.full(_itemsTotal), style: const TextStyle(fontSize: 12, color: AppColors.forest, fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Bei ya Kawaida:', style: TextStyle(fontSize: 12, color: AppColors.gray500)),
                  Text(TzsFormat.full(_originalTotal), style: const TextStyle(fontSize: 12, color: AppColors.gray400, decoration: TextDecoration.lineThrough)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Punguzo Maalum (50%):', style: TextStyle(fontSize: 12, color: Color(0xFFB42318), fontWeight: FontWeight.w700)),
                  Text('- ${TzsFormat.full(_savings)}', style: const TextStyle(fontSize: 12, color: Color(0xFFB42318), fontWeight: FontWeight.w700)),
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
                  Text(TzsFormat.full(_transferFee), style: const TextStyle(fontSize: 12, color: AppColors.emerald800, fontWeight: FontWeight.w800)),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.borderLight)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Jumla Kuu ya Kulipa:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.forest)),
                  Text(TzsFormat.full(_totalAmount), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.emerald800)),
                ],
              ),
            ],
          ),
        ),

        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3F2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFECDCA)),
            ),
            child: Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 12, color: Color(0xFFB42318), fontWeight: FontWeight.w600),
            ),
          ),
        ],
        const SizedBox(height: 20),

        // Submit Button
        PressableScale(
          onTap: _submitting ? () {} : _handleOrder,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F4C3A), Color(0xFF1E755B)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F4C3A).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock_outline_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Lipa Sasa & Toa Risiti Rasmi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
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
