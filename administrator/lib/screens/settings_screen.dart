import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _premiumPriceCtrl = TextEditingController();
  bool _loadingSettings = true;
  bool _savingPremium = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPremiumSettings());
  }

  @override
  void dispose() {
    _premiumPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPremiumSettings() async {
    setState(() {
      _loadingSettings = true;
      _loadError = null;
    });
    try {
      final data = await context
          .read<AdminProvider>()
          .contentService
          .fetchMwalimuSettings();
      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      _premiumPriceCtrl.text = '${settings['premiumPrice'] ?? 15000}';
    } catch (_) {
      _loadError = 'Imeshindwa kupakia bei ya Premium';
      if (_premiumPriceCtrl.text.isEmpty) {
        _premiumPriceCtrl.text = '15000';
      }
    }
    if (mounted) setState(() => _loadingSettings = false);
  }

  Future<void> _savePremiumPrice() async {
    final price = int.tryParse(_premiumPriceCtrl.text.trim());
    if (price == null || price < 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weka bei sahihi (angalau TZS 500)'),
        ),
      );
      return;
    }

    setState(() => _savingPremium = true);
    try {
      await context.read<AdminProvider>().contentService.updateMwalimuSettings({
        'premiumPrice': price,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bei ya Fungua Makala Zote imehifadhiwa')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kuhifadhi bei')),
      );
    } finally {
      if (mounted) setState(() => _savingPremium = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        onRefresh: () async {
          await provider.refreshData();
          await _loadPremiumSettings();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AdminColors.bg,
              pinned: true,
              elevation: 0,
              toolbarHeight: 72,
              titleSpacing: 0,
              title: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Settings',
                  style: GoogleFonts.inter(
                    color: AdminColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AdminColors.forest, AdminColors.forestLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AdminColors.emerald.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Super Admin',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  provider.adminEmail ??
                                      'mimeanidawa@gmail.com',
                                  style: GoogleFonts.inter(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Admin',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Animate(
                    delay: const Duration(milliseconds: 80),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: _PremiumPricingCard(
                      controller: _premiumPriceCtrl,
                      loading: _loadingSettings,
                      saving: _savingPremium,
                      error: _loadError,
                      onSave: _savePremiumPrice,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Animate(
                    delay: const Duration(milliseconds: 100),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: _SettingsSection(
                      title: 'Application',
                      items: [
                        _SettingsTile(
                          icon: Icons.info_outline_rounded,
                          label: 'App Version',
                          trailing: '1.0.0',
                          color: AdminColors.blue,
                        ),
                        _SettingsTile(
                          icon: Icons.eco_rounded,
                          label: 'App Name',
                          trailing: 'Dawa Asili',
                          color: AdminColors.emerald,
                        ),
                        _SettingsTile(
                          icon: Icons.people_rounded,
                          label: 'Total Users',
                          trailing: '12,847',
                          color: AdminColors.purple,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Animate(
                    delay: const Duration(milliseconds: 400),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: GestureDetector(
                      onTap: () => _confirmLogout(context, provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: AdminColors.redGlow,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AdminColors.error.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.logout_rounded,
                              color: AdminColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 14),
                            Text(
                              'Sign Out',
                              style: GoogleFonts.inter(
                                color: AdminColors.error,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Spacer(),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: AdminColors.error,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sign Out?',
          style: GoogleFonts.inter(
            color: AdminColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'You will be returned to the login screen.',
          style: GoogleFonts.inter(
            color: AdminColors.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.inter(color: AdminColors.textDim),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AdminColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              provider.logout();
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumPricingCard extends StatelessWidget {
  const _PremiumPricingCard({
    required this.controller,
    required this.loading,
    required this.saving,
    required this.onSave,
    this.error,
  });

  final TextEditingController controller;
  final bool loading;
  final bool saving;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'MALIPO / PREMIUM',
            style: GoogleFonts.inter(
              color: AdminColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AdminColors.amber.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: AdminColors.amber,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bei ya Fungua Makala Zote',
                          style: GoogleFonts.inter(
                            color: AdminColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Inaonekana kwenye akaunti ya mtumiaji (Premium siku 30)',
                          style: GoogleFonts.inter(
                            color: AdminColors.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AdminColors.emerald,
                      ),
                    ),
                  ),
                )
              else ...[
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: GoogleFonts.inter(
                    color: AdminColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Bei (TZS)',
                    labelStyle: GoogleFonts.inter(color: AdminColors.textDim),
                    hintText: '15000',
                    hintStyle: GoogleFonts.inter(color: AdminColors.textDim),
                    filled: true,
                    fillColor: AdminColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    prefixText: 'TZS ',
                    prefixStyle: GoogleFonts.inter(
                      color: AdminColors.emerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: GoogleFonts.inter(
                      color: AdminColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: saving ? null : onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.emerald,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          AdminColors.emerald.withOpacity(0.4),
                    ),
                    child: saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Hifadhi Bei',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.items});
  final String title;
  final List<_SettingsTile> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.inter(
              color: AdminColors.textDim,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.cardBorder),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 52,
                      color: AdminColors.cardBorder,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.color,
    this.trailing,
    this.showArrow = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final String? trailing;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (trailing != null)
              Text(
                trailing!,
                style: GoogleFonts.inter(
                  color: AdminColors.textDim,
                  fontSize: 13,
                ),
              ),
            if (showArrow)
              const Icon(
                Icons.chevron_right_rounded,
                color: AdminColors.textDim,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
