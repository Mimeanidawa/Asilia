import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/product_order_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';
import '../widgets/admin_ui.dart';
import '../widgets/glass_card.dart';
import '../widgets/url_image.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetchAdminProducts();
    });
  }

  void _openProductForm([AdminProduct? existing]) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(existing: existing),
    );
  }

  Future<void> _confirmDelete(AdminProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Text('Futa Dawa Hii?', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text('Una uhakika unataka kufuta "${product.title}"? Hatua hii haiwezi kurudishwa nyuma.',
            style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Ghairi', style: GoogleFonts.plusJakartaSans(color: AdminColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.rose),
            child: Text('Futa Kabisa', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<AdminProvider>().deleteAdminProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Dawa imefutwa' : 'Imeshindwa kufuta dawa'),
            backgroundColor: success ? AdminColors.emerald : AdminColors.rose,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final products = provider.adminProducts;
    final loading = provider.productsLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.fetchAdminProducts,
          color: AdminColors.emerald,
          backgroundColor: AdminColors.surface,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dawa & Bidhaa',
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textPrimary,
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Simamia dawa za asili zinazouzwa kwa punguzo',
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textDim,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _openProductForm(),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text('Weka Dawa', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.emerald,
                          foregroundColor: const Color(0xFF052E16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (loading && products.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: AdminColors.emerald)),
                )
              else if (products.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.medication_liquid_rounded, size: 56, color: AdminColors.textMuted),
                        const SizedBox(height: 12),
                        Text('Hakuna dawa zilizowekwa bado', style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 14)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => _openProductForm(),
                          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.emerald, foregroundColor: const Color(0xFF052E16)),
                          child: const Text('Weka Dawa ya Kwanza'),
                        ),
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
                        final p = products[i];
                        return _ProductCard(
                          product: p,
                          onEdit: () => _openProductForm(p),
                          onDelete: () => _confirmDelete(p),
                        );
                      },
                      childCount: products.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminProduct product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 70,
                    height: 70,
                    color: AdminColors.surface,
                    child: UrlImage(
                      url: product.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AdminColors.rose.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${product.discountPercent}%',
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.rose,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (product.subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          product.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textDim,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(
                            TzsFormat.full(product.price),
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.emerald,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            TzsFormat.full(product.originalPrice),
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textMuted,
                              fontSize: 11,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Stoo: ${product.stockQuantity}',
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textDim,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AdminColors.divider, height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, size: 16, color: AdminColors.rose),
                  label: Text('Futa', style: GoogleFonts.plusJakartaSans(color: AdminColors.rose, fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_rounded, size: 15),
                  label: Text('Hariri Dawa', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.surfaceElevated,
                    foregroundColor: AdminColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({this.existing});
  final AdminProduct? existing;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _origPriceCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _benefitsCtrl;
  late final TextEditingController _howToUseCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _titleCtrl = TextEditingController(text: p?.title ?? '');
    _subtitleCtrl = TextEditingController(text: p?.subtitle ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _origPriceCtrl = TextEditingController(text: (p?.originalPrice ?? 50000).toString());
    _priceCtrl = TextEditingController(text: (p?.price ?? 25000).toString());
    _imageCtrl = TextEditingController(text: p?.imageUrl ?? 'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&q=80&w=600');
    _stockCtrl = TextEditingController(text: (p?.stockQuantity ?? 50).toString());
    _benefitsCtrl = TextEditingController(text: p?.benefits.join('\n') ?? 'Huponya haraka na kutuliza maumivu\n100% mimea asilia bila kemikali\nInafaa kwa rika zote');
    _howToUseCtrl = TextEditingController(text: p?.howToUse ?? 'Kijiko 1 asubuhi na jioni kabla ya chakula.');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _descCtrl.dispose();
    _origPriceCtrl.dispose();
    _priceCtrl.dispose();
    _imageCtrl.dispose();
    _stockCtrl.dispose();
    _benefitsCtrl.dispose();
    _howToUseCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tafadhali weka jina la dawa')),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<AdminProvider>();
    final origPrice = int.tryParse(_origPriceCtrl.text.trim()) ?? 50000;
    final price = int.tryParse(_priceCtrl.text.trim()) ?? 25000;
    final discountPercent = origPrice > 0 ? (((origPrice - price) / origPrice) * 100).round() : 50;

    final benefits = _benefitsCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final product = AdminProduct(
      id: widget.existing?.id ?? 'dawa_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      subtitle: _subtitleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      price: price,
      originalPrice: origPrice,
      discountPercent: discountPercent,
      imageUrl: _imageCtrl.text.trim(),
      badgeText: 'PUNGUZO LA $discountPercent% 🔥',
      stockQuantity: int.tryParse(_stockCtrl.text.trim()) ?? 50,
      category: 'general',
      benefits: benefits,
      howToUse: _howToUseCtrl.text.trim(),
      isPublished: true,
    );

    final ok = widget.existing == null
        ? await provider.createAdminProduct(product)
        : await provider.updateAdminProduct(product);

    if (mounted) {
      setState(() => _saving = false);
      if (ok) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existing == null ? 'Dawa mpya imewekwa!' : 'Dawa imesasishwa!'),
            backgroundColor: AdminColors.emerald,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imeshindwa kuokoa dawa'), backgroundColor: AdminColors.rose),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.existing == null;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      maxHeight: MediaQuery.of(context).size.height * 0.88,
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isNew ? 'Weka Dawa Mpya (50% Off)' : 'Hariri Dawa Hii',
                  style: GoogleFonts.plusJakartaSans(
                    color: AdminColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AdminColors.textDim),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField('Jina la Dawa *', _titleCtrl, 'Mf. Dawa Asili ya Vidonda vya Tumbo'),
            _buildField('Mada / Subtitle', _subtitleCtrl, 'Mf. Mchanganyiko wa Mshubiri & Mizizi'),
            Row(
              children: [
                Expanded(
                  child: _buildField('Bei ya Awali (TZS)', _origPriceCtrl, '50000', keyboard: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField('Bei ya Punguzo (TZS)', _priceCtrl, '25000', keyboard: TextInputType.number),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: _buildField('Idadi Stoo', _stockCtrl, '50', keyboard: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField('Picha (URL)', _imageCtrl, 'https://...'),
                ),
              ],
            ),
            _buildField('Faida za Dawa (Mstari mmoja kwa kila faida)', _benefitsCtrl, 'Faida 1\nFaida 2', maxLines: 3),
            _buildField('Jinsi ya Kutumia', _howToUseCtrl, 'Kijiko 1 asubuhi...', maxLines: 2),
            _buildField('Maelezo Kamili ya Dawa', _descCtrl, 'Tiba madhubuti...', maxLines: 3),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AdminColors.emerald,
                  foregroundColor: const Color(0xFF052E16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        isNew ? 'Chapisha Dawa Sasa' : 'Hifadhi Mabadiliko',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, String hint, {int maxLines = 1, TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 11.5, fontWeight: FontWeight.w600)),
          const SizedBox(height: 5),
          TextField(
            controller: ctrl,
            maxLines: maxLines,
            keyboardType: keyboard,
            style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.plusJakartaSans(color: AdminColors.textMuted, fontSize: 12),
              filled: true,
              fillColor: AdminColors.card,
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.cardBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AdminColors.cardBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AdminColors.emerald)),
            ),
          ),
        ],
      ),
    );
  }
}
