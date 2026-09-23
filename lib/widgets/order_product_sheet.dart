import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/product_models.dart';
import '../services/dawa_order_service.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/tzs_format.dart';
import 'herb_image.dart';
import 'pressable_scale.dart';
import 'receipt_modal.dart';

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
      if (user.phone != null && user.phone!.isNotEmpty) _phoneController.text = user.phone!;
    }
  }

  @override
  void dispose() {
    _districtController.dispose();
    _wardController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  int get _totalAmount => widget.product.price * _quantity;
  int get _originalTotal => widget.product.originalPrice * _quantity;
  int get _savings => _originalTotal - _totalAmount;

  Future<void> _handleOrder() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final district = _districtController.text.trim();
    final ward = _wardController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Tafadhali andika jina lako kamili au mpokeaji.');
      return;
    }

    if (phone.isEmpty || phone.length < 9) {
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
    });

    final orderService = context.read<DawaOrderService>();
    final user = context.read<UserService>().user;

    try {
      final order = await orderService.createOrder(
        product: widget.product,
        quantity: _quantity,
        customerName: name,
        customerPhone: phone,
        region: _selectedRegion,
        district: district,
        ward: ward,
        paymentMethod: _selectedPaymentMethod,
        userId: user?.id,
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // Close order sheet

      // Immediately show official receipt!
      ReceiptModal.show(context, order);
    } catch (e) {
      setState(() {
        _errorMessage = 'Hitilafu: $e';
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

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
                      child: const Icon(Icons.shopping_bag_rounded, color: AppColors.emerald800, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AGIZA & NUNUA DAWA HII',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColors.forest,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'Utoaji nchi nzima Tanzania kwa uhakika',
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
                      isExpanded: true,
                      value: _selectedRegion,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.forest),
                      items: DawaOrderService.tanzaniaRegions.map((region) {
                        return DropdownMenuItem<String>(
                          value: region,
                          child: Text(
                            'Mkoa wa $region',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.forest,
                            ),
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
                          hintText: 'Wilaya (mf. Kinondoni)',
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
                          hintText: 'Kata / Mtaa (mf. Mwenge)',
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
                const SizedBox(height: 20),

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
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1, color: AppColors.borderLight)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Jumla ya Kulipa:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.forest)),
                          Text(TzsFormat.full(_totalAmount), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: AppColors.emerald800)),
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
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
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
            ),
          ),
        ],
      ),
    );
  }
}
