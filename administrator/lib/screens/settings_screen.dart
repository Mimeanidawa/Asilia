import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_ui.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _premiumPriceCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _imageCtrl = TextEditingController();
  final _welcomeCtrl = TextEditingController();
  final _limitCtrl = TextEditingController();
  final _screenTitleCtrl = TextEditingController();
  final _screenBodyCtrl = TextEditingController();
  final _minVersionCtrl = TextEditingController();
  final _minBuildCtrl = TextEditingController();
  final _updateTitleCtrl = TextEditingController();
  final _updateMessageCtrl = TextEditingController();
  final _storeUrlCtrl = TextEditingController();
  bool _loadingSettings = true;
  bool _savingPremium = false;
  bool _savingMwalimu = false;
  bool _savingScreenMessage = false;
  bool _savingUpdate = false;
  bool _screenMessageEnabled = false;
  bool _screenMessageDismissible = true;
  String _screenMessageStyle = 'info';
  bool _forceUpdateEnabled = false;
  bool _adsPromoModalEnabled = true;
  String? _loadError;
  String _screenMessageId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPremiumSettings());
  }

  @override
  void dispose() {
    _premiumPriceCtrl.dispose();
    _nameCtrl.dispose();
    _imageCtrl.dispose();
    _welcomeCtrl.dispose();
    _limitCtrl.dispose();
    _screenTitleCtrl.dispose();
    _screenBodyCtrl.dispose();
    _minVersionCtrl.dispose();
    _minBuildCtrl.dispose();
    _updateTitleCtrl.dispose();
    _updateMessageCtrl.dispose();
    _storeUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPremiumSettings() async {
    setState(() {
      _loadingSettings = true;
      _loadError = null;
    });
    try {
      final svc = context.read<AdminProvider>().contentService;
      final data = await svc.fetchMwalimuSettings();
      final settings = data['settings'] as Map<String, dynamic>? ?? {};
      _premiumPriceCtrl.text = '${settings['premiumPrice'] ?? 15000}';
      _nameCtrl.text =
          '${settings['mwalimuName'] ?? settings['mtabibuName'] ?? ''}';
      _imageCtrl.text =
          '${settings['mwalimuImage'] ?? settings['mtabibuImage'] ?? ''}';
      _welcomeCtrl.text =
          '${settings['mwalimuWelcome'] ?? settings['mtabibuWelcome'] ?? ''}';
      _limitCtrl.text = '${settings['freeMessageLimit'] ?? 5}';
      _adsPromoModalEnabled = settings['adsPromoModalEnabled'] != false;

      final appData = await svc.fetchAppConfig();
      final config = appData['config'] as Map<String, dynamic>? ?? {};
      final screen = config['screenMessage'] as Map<String, dynamic>? ?? {};
      final update = config['update'] as Map<String, dynamic>? ?? {};
      _screenMessageEnabled = screen['enabled'] == true;
      _screenMessageId = '${screen['id'] ?? ''}';
      _screenTitleCtrl.text = '${screen['title'] ?? ''}';
      _screenBodyCtrl.text = '${screen['body'] ?? ''}';
      _screenMessageStyle = '${screen['style'] ?? 'info'}';
      _screenMessageDismissible = screen['dismissible'] != false;
      _forceUpdateEnabled = update['forceUpdate'] == true;
      _minVersionCtrl.text = '${update['minVersion'] ?? ''}';
      _minBuildCtrl.text = '${update['minBuild'] ?? 0}';
      _updateTitleCtrl.text = '${update['title'] ?? 'Sasisha programu'}';
      _updateMessageCtrl.text = '${update['message'] ?? ''}';
      _storeUrlCtrl.text =
          '${update['storeUrl'] ?? 'https://play.google.com/store/apps/details?id=com.asilia'}';
    } catch (_) {
      _loadError = 'Imeshindwa kupakia mipangilio';
      if (_premiumPriceCtrl.text.isEmpty) {
        _premiumPriceCtrl.text = '15000';
      }
      if (_limitCtrl.text.isEmpty) _limitCtrl.text = '5';
      if (_storeUrlCtrl.text.isEmpty) {
        _storeUrlCtrl.text =
            'https://play.google.com/store/apps/details?id=com.asilia';
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
        'adsPromoModalEnabled': _adsPromoModalEnabled,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bei ya Premium / kuondoa matangazo imehifadhiwa')),
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

  Future<void> _saveMwalimuDetails() async {
    setState(() => _savingMwalimu = true);
    try {
      await context.read<AdminProvider>().contentService.updateMwalimuSettings({
        'mwalimuName': _nameCtrl.text.trim(),
        'mwalimuImage': _imageCtrl.text.trim(),
        'mwalimuWelcome': _welcomeCtrl.text.trim(),
        'freeMessageLimit': int.tryParse(_limitCtrl.text.trim()) ?? 5,
        'premiumPrice': int.tryParse(_premiumPriceCtrl.text.trim()) ?? 15000,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mipangilio ya Mwalimu imehifadhiwa')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kuhifadhi mipangilio')),
      );
    } finally {
      if (mounted) setState(() => _savingMwalimu = false);
    }
  }

  Future<void> _saveScreenMessage({bool bumpId = true}) async {
    if (_screenMessageEnabled && _screenBodyCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Andika ujumbe wa kuonyesha kwenye app')),
      );
      return;
    }
    setState(() => _savingScreenMessage = true);
    try {
      final res = await context.read<AdminProvider>().contentService.updateAppConfig({
        'bumpMessageId': bumpId,
        'screenMessage': {
          'enabled': _screenMessageEnabled,
          'id': _screenMessageId,
          'title': _screenTitleCtrl.text.trim(),
          'body': _screenBodyCtrl.text.trim(),
          'style': _screenMessageStyle,
          'dismissible': _screenMessageDismissible,
        },
        'update': {
          'forceUpdate': _forceUpdateEnabled,
          'minVersion': _minVersionCtrl.text.trim(),
          'minBuild': int.tryParse(_minBuildCtrl.text.trim()) ?? 0,
          'title': _updateTitleCtrl.text.trim(),
          'message': _updateMessageCtrl.text.trim(),
          'storeUrl': _storeUrlCtrl.text.trim(),
        },
      });
      final config = res['config'] as Map<String, dynamic>? ?? {};
      final screen = config['screenMessage'] as Map<String, dynamic>? ?? {};
      _screenMessageId = '${screen['id'] ?? _screenMessageId}';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _screenMessageEnabled
                ? 'Ujumbe wa skrini umechapishwa kwenye app ya watumiaji'
                : 'Ujumbe wa skrini umezimwa',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kuhifadhi ujumbe wa skrini')),
      );
    } finally {
      if (mounted) setState(() => _savingScreenMessage = false);
    }
  }

  Future<void> _saveForceUpdate() async {
    if (_forceUpdateEnabled &&
        _minVersionCtrl.text.trim().isEmpty &&
        (int.tryParse(_minBuildCtrl.text.trim()) ?? 0) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weka toleo la chini (mf. 1.2.0) au build number'),
        ),
      );
      return;
    }
    setState(() => _savingUpdate = true);
    try {
      await context.read<AdminProvider>().contentService.updateAppConfig({
        'bumpMessageId': false,
        'screenMessage': {
          'enabled': _screenMessageEnabled,
          'id': _screenMessageId,
          'title': _screenTitleCtrl.text.trim(),
          'body': _screenBodyCtrl.text.trim(),
          'style': _screenMessageStyle,
          'dismissible': _screenMessageDismissible,
        },
        'update': {
          'forceUpdate': _forceUpdateEnabled,
          'minVersion': _minVersionCtrl.text.trim(),
          'minBuild': int.tryParse(_minBuildCtrl.text.trim()) ?? 0,
          'title': _updateTitleCtrl.text.trim().isEmpty
              ? 'Sasisha programu'
              : _updateTitleCtrl.text.trim(),
          'message': _updateMessageCtrl.text.trim(),
          'storeUrl': _storeUrlCtrl.text.trim().isEmpty
              ? 'https://play.google.com/store/apps/details?id=com.asilia'
              : _storeUrlCtrl.text.trim(),
        },
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _forceUpdateEnabled
                ? 'Lazima kusasisha imewezeshwa — watumiaji wataelekezwa Play Store'
                : 'Lazima kusasisha imezimwa',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Imeshindwa kuhifadhi mipangilio ya update')),
      );
    } finally {
      if (mounted) setState(() => _savingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        backgroundColor: AdminColors.card,
        onRefresh: () async {
          await provider.refreshData();
          await _loadPremiumSettings();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const AdminPageHeader(
              title: 'Settings',
              subtitle: 'App configuration & pricing',
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Animate(
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: AdminSurface(
                      accentColor: AdminColors.emerald,
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AdminColors.emeraldGlow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.25)),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                color: AdminColors.emerald,
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
                                  provider.adminName ?? 'Super Admin',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AdminColors.textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  provider.adminEmail ?? 'mimeanidawa@gmail.com',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AdminColors.textMuted,
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
                              color: AdminColors.emeraldGlow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AdminColors.emerald.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              'Admin',
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.emerald,
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
                      adsPromoModalEnabled: _adsPromoModalEnabled,
                      onAdsPromoChanged: (v) =>
                          setState(() => _adsPromoModalEnabled = v),
                      onSave: _savePremiumPrice,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Animate(
                    delay: const Duration(milliseconds: 90),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: _MwalimuDetailsCard(
                      nameCtrl: _nameCtrl,
                      imageCtrl: _imageCtrl,
                      welcomeCtrl: _welcomeCtrl,
                      limitCtrl: _limitCtrl,
                      loading: _loadingSettings,
                      saving: _savingMwalimu,
                      onSave: _saveMwalimuDetails,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Animate(
                    delay: const Duration(milliseconds: 95),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: _ScreenMessageCard(
                      enabled: _screenMessageEnabled,
                      dismissible: _screenMessageDismissible,
                      style: _screenMessageStyle,
                      titleCtrl: _screenTitleCtrl,
                      bodyCtrl: _screenBodyCtrl,
                      loading: _loadingSettings,
                      saving: _savingScreenMessage,
                      onEnabledChanged: (v) =>
                          setState(() => _screenMessageEnabled = v),
                      onDismissibleChanged: (v) =>
                          setState(() => _screenMessageDismissible = v),
                      onStyleChanged: (v) =>
                          setState(() => _screenMessageStyle = v),
                      onSave: () => _saveScreenMessage(bumpId: true),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Animate(
                    delay: const Duration(milliseconds: 98),
                    effects: const [
                      FadeEffect(duration: Duration(milliseconds: 400)),
                    ],
                    child: _ForceUpdateCard(
                      enabled: _forceUpdateEnabled,
                      minVersionCtrl: _minVersionCtrl,
                      minBuildCtrl: _minBuildCtrl,
                      titleCtrl: _updateTitleCtrl,
                      messageCtrl: _updateMessageCtrl,
                      storeUrlCtrl: _storeUrlCtrl,
                      loading: _loadingSettings,
                      saving: _savingUpdate,
                      onEnabledChanged: (v) =>
                          setState(() => _forceUpdateEnabled = v),
                      onSave: _saveForceUpdate,
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
                          trailing: '1.0.1',
                          color: AdminColors.blue,
                        ),
                        _SettingsTile(
                          icon: Icons.eco_rounded,
                          label: 'App Name',
                          trailing: 'Dawa Asili',
                          color: AdminColors.emerald,
                        ),
                        _SettingsTile(
                          icon: Icons.storefront_rounded,
                          label: 'Play Store',
                          trailing: 'com.asilia',
                          color: AdminColors.amber,
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

class _MwalimuDetailsCard extends StatelessWidget {
  const _MwalimuDetailsCard({
    required this.nameCtrl,
    required this.imageCtrl,
    required this.welcomeCtrl,
    required this.limitCtrl,
    required this.loading,
    required this.saving,
    required this.onSave,
  });

  final TextEditingController nameCtrl;
  final TextEditingController imageCtrl;
  final TextEditingController welcomeCtrl;
  final TextEditingController limitCtrl;
  final bool loading;
  final bool saving;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'MWALIMU',
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
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Maelezo ya Mwalimu',
                      style: GoogleFonts.inter(
                        color: AdminColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Jina, picha, ujumbe wa karibu na kikomo cha maswali bure',
                      style: GoogleFonts.inter(
                        color: AdminColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _settingsField(nameCtrl, 'Jina la Mwalimu'),
                    _settingsField(imageCtrl, 'URL ya Picha'),
                    _settingsField(
                      welcomeCtrl,
                      'Ujumbe wa Karibu (elimu tu)',
                      maxLines: 3,
                    ),
                    _settingsField(
                      limitCtrl,
                      'Kikomo cha Maswali (Bure)',
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
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
                                'Hifadhi Mwalimu',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _settingsField(
    TextEditingController ctrl,
    String label, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.inter(color: AdminColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AdminColors.textDim),
          filled: true,
          fillColor: AdminColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _ScreenMessageCard extends StatelessWidget {
  const _ScreenMessageCard({
    required this.enabled,
    required this.dismissible,
    required this.style,
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.loading,
    required this.saving,
    required this.onEnabledChanged,
    required this.onDismissibleChanged,
    required this.onStyleChanged,
    required this.onSave,
  });

  final bool enabled;
  final bool dismissible;
  final String style;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final bool loading;
  final bool saving;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<bool> onDismissibleChanged;
  final ValueChanged<String> onStyleChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'UJUMBE WA SKRINI (USER APP)',
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
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Onyesha ujumbe kwenye Home',
                      style: GoogleFonts.inter(
                        color: AdminColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watumiaji wataona banner juu ya ukurasa wa mwanzo mara tu ukihifadhi.',
                      style: GoogleFonts.inter(
                        color: AdminColors.textDim,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AdminSwitchRow(
                      label: 'Wezesha ujumbe',
                      value: enabled,
                      activeColor: AdminColors.emerald,
                      bold: true,
                      onChanged: onEnabledChanged,
                    ),
                    _AdminSwitchRow(
                      label: 'Inaweza kufungwa (X)',
                      value: dismissible,
                      activeColor: AdminColors.emerald,
                      onChanged: onDismissibleChanged,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Aina',
                      style: GoogleFonts.inter(
                        color: AdminColors.textDim,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final s in const ['info', 'warning', 'success'])
                          ChoiceChip(
                            label: Text(s),
                            selected: style == s,
                            onSelected: (_) => onStyleChanged(s),
                            selectedColor: AdminColors.emeraldGlow,
                            labelStyle: GoogleFonts.inter(
                              color: style == s
                                  ? AdminColors.emerald
                                  : AdminColors.textMuted,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _adminField(titleCtrl, 'Kichwa (si lazima)'),
                    _adminField(bodyCtrl, 'Ujumbe wa kuonyesha', maxLines: 4),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: saving ? null : onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.emerald,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AdminColors.emerald.withValues(alpha: 0.4),
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
                                'Chapisha kwenye User App',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ForceUpdateCard extends StatelessWidget {
  const _ForceUpdateCard({
    required this.enabled,
    required this.minVersionCtrl,
    required this.minBuildCtrl,
    required this.titleCtrl,
    required this.messageCtrl,
    required this.storeUrlCtrl,
    required this.loading,
    required this.saving,
    required this.onEnabledChanged,
    required this.onSave,
  });

  final bool enabled;
  final TextEditingController minVersionCtrl;
  final TextEditingController minBuildCtrl;
  final TextEditingController titleCtrl;
  final TextEditingController messageCtrl;
  final TextEditingController storeUrlCtrl;
  final bool loading;
  final bool saving;
  final ValueChanged<bool> onEnabledChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'LAZIMA KUSASISHA (PLAY STORE)',
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
          child: loading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Force update',
                      style: GoogleFonts.inter(
                        color: AdminColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Watumiaji wenye toleo la zamani watafungwa hadi wasasishe kwenye Play Store (com.asilia).',
                      style: GoogleFonts.inter(
                        color: AdminColors.textDim,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AdminSwitchRow(
                      label: 'Lazima kusasisha',
                      value: enabled,
                      activeColor: AdminColors.amber,
                      bold: true,
                      onChanged: onEnabledChanged,
                    ),
                    _adminField(minVersionCtrl, 'Toleo la chini (mf. 1.2.0)'),
                    _adminField(
                      minBuildCtrl,
                      'Build number la chini (si lazima)',
                      keyboardType: TextInputType.number,
                    ),
                    _adminField(titleCtrl, 'Kichwa cha dialog'),
                    _adminField(messageCtrl, 'Ujumbe wa update', maxLines: 3),
                    _adminField(storeUrlCtrl, 'Play Store URL'),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: saving ? null : onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AdminColors.amber,
                          foregroundColor: const Color(0xFF1A1205),
                          disabledBackgroundColor:
                              AdminColors.amber.withValues(alpha: 0.4),
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
                                'Hifadhi Update Rules',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

Widget _adminField(
  TextEditingController ctrl,
  String label, {
  int maxLines = 1,
  TextInputType? keyboardType,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: AdminColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AdminColors.textDim),
        filled: true,
        fillColor: AdminColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}

class _AdminSwitchRow extends StatelessWidget {
  const _AdminSwitchRow({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
    this.bold = false,
  });

  final String label;
  final bool value;
  final Color activeColor;
  final ValueChanged<bool> onChanged;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                color: AdminColors.textPrimary,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            activeThumbColor: activeColor,
            onChanged: onChanged,
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
    required this.adsPromoModalEnabled,
    required this.onAdsPromoChanged,
    this.error,
  });

  final TextEditingController controller;
  final bool loading;
  final bool saving;
  final VoidCallback onSave;
  final bool adsPromoModalEnabled;
  final ValueChanged<bool> onAdsPromoChanged;
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
                          'Bei ya Premium — Ondoa Matangazo',
                          style: GoogleFonts.inter(
                            color: AdminColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Inaondoa matangazo yote, inafungua makala zote, na mazungumzo bila kikomo (siku 30)',
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
                const SizedBox(height: 12),
                _AdminSwitchRow(
                  label: 'Onyesha modal "Ondoa matangazo yote sasa"',
                  value: adsPromoModalEnabled,
                  activeColor: AdminColors.amber,
                  onChanged: loading ? (_) {} : onAdsPromoChanged,
                ),
                Text(
                  'Modal inaonekana mara chache kwa watumiaji wa bure wanaosoma makala',
                  style: GoogleFonts.inter(
                    color: AdminColors.textDim,
                    fontSize: 11,
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
