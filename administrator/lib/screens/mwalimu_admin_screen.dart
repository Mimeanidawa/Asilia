import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

class MwalimuAdminScreen extends StatefulWidget {
  const MwalimuAdminScreen({super.key});

  @override
  State<MwalimuAdminScreen> createState() => _MwalimuAdminScreenState();
}

class _MwalimuAdminScreenState extends State<MwalimuAdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  String? _selectedConvId;
  final _replyCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    final svc = context.read<AdminProvider>().contentService;
    try {
      final s = await svc.fetchMwalimuSettings();
      _settings = s['settings'] as Map<String, dynamic>;
      _conversations = await svc.fetchConversations();
    } catch (_) {}
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabs.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  String _setting(String key, String fallbackKey) =>
      _settings[key] as String? ?? _settings[fallbackKey] as String? ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.bg,
        title: Text('Mwalimu', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AdminColors.emerald,
          labelColor: AdminColors.emerald,
          unselectedLabelColor: AdminColors.textDim,
          tabs: const [Tab(text: 'Mipangilio'), Tab(text: 'Maswali')],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildSettings(), _buildChats()],
      ),
    );
  }

  Widget _buildSettings() {
    final nameCtrl = TextEditingController(text: _setting('mwalimuName', 'mtabibuName'));
    final imgCtrl = TextEditingController(text: _setting('mwalimuImage', 'mtabibuImage'));
    final welcomeCtrl = TextEditingController(text: _setting('mwalimuWelcome', 'mtabibuWelcome'));
    final limitCtrl = TextEditingController(text: '${_settings['freeMessageLimit'] ?? 5}');
    final priceCtrl = TextEditingController(text: '${_settings['premiumPrice'] ?? 15000}');

    return RefreshIndicator(
      color: AdminColors.emerald,
      onRefresh: _load,
      child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        Text('Mwalimu wa Elimu', style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          'Kwa elimu tu — si ushauri wa kimatibabu',
          style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12),
        ),
        const SizedBox(height: 16),
        _field(nameCtrl, 'Jina la Mwalimu'),
        _field(imgCtrl, 'URL ya Picha'),
        _field(welcomeCtrl, 'Ujumbe wa Karibu (elimu tu)', maxLines: 3),
        _field(limitCtrl, 'Kikomo cha Maswali (Bure)'),
        _field(priceCtrl, 'Bei ya Premium (TZS)'),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            await context.read<AdminProvider>().contentService.updateMwalimuSettings({
              'mwalimuName': nameCtrl.text,
              'mwalimuImage': imgCtrl.text,
              'mwalimuWelcome': welcomeCtrl.text,
              'freeMessageLimit': int.tryParse(limitCtrl.text) ?? 5,
              'premiumPrice': int.tryParse(priceCtrl.text) ?? 15000,
            });
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imehifadhiwa')));
              _load();
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AdminColors.emerald, minimumSize: const Size(double.infinity, 48)),
          child: const Text('Hifadhi Mipangilio'),
        ),
      ],
    ),
    );
  }

  Widget _buildChats() {
    if (_selectedConvId != null) return _buildChatDetail();
    return RefreshIndicator(
      color: AdminColors.emerald,
      onRefresh: _load,
      child: ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _conversations.length,
      itemBuilder: (_, i) {
        final c = _conversations[i];
        return Card(
          color: AdminColors.surface,
          margin: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: Colors.transparent,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AdminColors.emerald.withValues(alpha: 0.2),
                child: Text((c['userName'] as String? ?? 'U')[0], style: const TextStyle(color: AdminColors.emerald)),
              ),
              title: Text(c['userName'] as String? ?? '', style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w600)),
              subtitle: Text(c['lastMessage'] as String? ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12)),
              trailing: c['isPremium'] == true ? const Icon(Icons.star, color: AdminColors.amber, size: 16) : null,
              onTap: () async {
                _selectedConvId = c['id'] as String;
                _messages = await context.read<AdminProvider>().contentService.fetchMessages(_selectedConvId!);
                setState(() {});
              },
            ),
          ),
        );
      },
    ),
    );
  }

  Widget _buildChatDetail() {
    return Column(
      children: [
        ListTile(
          leading: IconButton(icon: const Icon(Icons.arrow_back, color: AdminColors.emerald), onPressed: () => setState(() => _selectedConvId = null)),
          title: Text('Maswali ya Mwanafunzi', style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: RefreshIndicator(
            color: AdminColors.emerald,
            onRefresh: _load,
            child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (_, i) {
              final m = _messages[i];
              final isAdmin = m['senderType'] == 'admin';
              return Align(
                alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  decoration: BoxDecoration(
                    color: isAdmin ? AdminColors.emerald.withValues(alpha: 0.2) : AdminColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(m['content'] as String, style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13)),
                ),
              );
            },
          ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  style: GoogleFonts.inter(color: AdminColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Jibu kwa elimu tu...',
                    hintStyle: GoogleFonts.inter(color: AdminColors.textDim),
                    filled: true,
                    fillColor: AdminColors.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (_replyCtrl.text.trim().isEmpty) return;
                  await context.read<AdminProvider>().contentService.replyToConversation(_selectedConvId!, _replyCtrl.text);
                  _replyCtrl.clear();
                  _messages = await context.read<AdminProvider>().contentService.fetchMessages(_selectedConvId!);
                  setState(() {});
                },
                icon: const Icon(Icons.send, color: AdminColors.emerald),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: AdminColors.textPrimary),
        decoration: InputDecoration(labelText: label, labelStyle: GoogleFonts.inter(color: AdminColors.textDim)),
      ),
    );
  }
}
