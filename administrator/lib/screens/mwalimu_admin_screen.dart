import 'dart:async';

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

class _MwalimuAdminScreenState extends State<MwalimuAdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _publishedArticles = [];
  String? _selectedConvId;
  final _replyCtrl = TextEditingController();
  Timer? _refreshTimer;
  bool _loadingMessages = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging && _tabs.index == 1) {
        _loadConversations();
      }
    });
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (_tabs.index == 1) {
        if (_selectedConvId != null) {
          _reloadMessages(silent: true);
        } else {
          _loadConversations(silent: true);
        }
      }
      context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
    });
  }

  Future<void> _load() async {
    final svc = context.read<AdminProvider>().contentService;
    try {
      final s = await svc.fetchMwalimuSettings();
      _settings = s['settings'] as Map<String, dynamic>;
      _conversations = await svc.fetchConversations();
      final posts = await svc.fetchPosts();
      _publishedArticles = posts.where((p) => p['isPublished'] == true).toList()
        ..sort((a, b) => ((a['title'] as String?) ?? '')
            .toLowerCase()
            .compareTo(((b['title'] as String?) ?? '').toLowerCase()));
      await context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _loadConversations({bool silent = false}) async {
    try {
      final list =
          await context.read<AdminProvider>().contentService.fetchConversations();
      if (!mounted) return;
      setState(() => _conversations = list);
      await context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
    } catch (_) {
      if (!silent) {
        // Keep existing list.
      }
    }
  }

  Future<void> _openConversation(String convId) async {
    setState(() {
      _selectedConvId = convId;
      _loadingMessages = true;
    });
    final svc = context.read<AdminProvider>().contentService;
    try {
      await svc.markConversationRead(convId);
      _messages = await svc.fetchMessages(convId);
      await context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
      await _loadConversations(silent: true);
    } catch (_) {}
    if (mounted) setState(() => _loadingMessages = false);
  }

  Future<void> _reloadMessages({bool silent = false}) async {
    final id = _selectedConvId;
    if (id == null) return;
    try {
      final msgs =
          await context.read<AdminProvider>().contentService.fetchMessages(id);
      if (!mounted) return;
      final grew = msgs.length > _messages.length;
      setState(() => _messages = msgs);
      if (grew) {
        await context
            .read<AdminProvider>()
            .contentService
            .markConversationRead(id);
        await context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
      }
    } catch (_) {
      if (!silent) rethrow;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabs.dispose();
    _replyCtrl.dispose();
    super.dispose();
  }

  String _setting(String key, String fallbackKey) =>
      _settings[key] as String? ?? _settings[fallbackKey] as String? ?? '';

  int get _unreadTotal => _conversations.fold<int>(
        0,
        (sum, c) => sum + ((c['unreadCount'] as int?) ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final providerUnread = context.watch<AdminProvider>().mwalimuUnreadCount;
    final badge = providerUnread > 0 ? providerUnread : _unreadTotal;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.bg,
        title: Text('Mwalimu',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AdminColors.emerald,
          labelColor: AdminColors.emerald,
          unselectedLabelColor: AdminColors.textDim,
          tabs: [
            const Tab(text: 'Mipangilio'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Maswali'),
                  if (badge > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AdminColors.error,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badge > 99 ? '99+' : '$badge',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [_buildSettings(), _buildChats()],
      ),
    );
  }

  Widget _buildSettings() {
    final nameCtrl =
        TextEditingController(text: _setting('mwalimuName', 'mtabibuName'));
    final imgCtrl =
        TextEditingController(text: _setting('mwalimuImage', 'mtabibuImage'));
    final welcomeCtrl = TextEditingController(
        text: _setting('mwalimuWelcome', 'mtabibuWelcome'));
    final limitCtrl =
        TextEditingController(text: '${_settings['freeMessageLimit'] ?? 5}');
    final priceCtrl =
        TextEditingController(text: '${_settings['premiumPrice'] ?? 15000}');

    return RefreshIndicator(
      color: AdminColors.emerald,
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text('Mwalimu wa Elimu',
              style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
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
          _field(priceCtrl, 'Bei ya Fungua Makala Zote / Premium (TZS)'),
          const SizedBox(height: 8),
          Text(
            'Bei hii inaonekana pia kwenye Settings → Malipo. Inatumika kwa Premium siku 30 (makala zote + maswali bila kikomo).',
            style: GoogleFonts.inter(
                color: AdminColors.textDim, fontSize: 11, height: 1.35),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              await context
                  .read<AdminProvider>()
                  .contentService
                  .updateMwalimuSettings({
                'mwalimuName': nameCtrl.text,
                'mwalimuImage': imgCtrl.text,
                'mwalimuWelcome': welcomeCtrl.text,
                'freeMessageLimit': int.tryParse(limitCtrl.text) ?? 5,
                'premiumPrice': int.tryParse(priceCtrl.text) ?? 15000,
              });
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Imehifadhiwa')));
                _load();
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.emerald,
                minimumSize: const Size(double.infinity, 48)),
            child: const Text('Hifadhi Mipangilio'),
          ),
        ],
      ),
    );
  }

  Widget _buildChats() {
    if (_selectedConvId != null) return _buildChatDetail();

    final inbox = context.watch<AdminProvider>().mwalimuInbox;

    return RefreshIndicator(
      color: AdminColors.emerald,
      onRefresh: () async {
        await _loadConversations();
        await _load();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (inbox.isNotEmpty) ...[
            Text(
              'Ujumbe mpya',
              style: GoogleFonts.inter(
                color: AdminColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            ...inbox.take(5).map((item) {
              return Card(
                color: AdminColors.emerald.withValues(alpha: 0.08),
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.mark_email_unread_rounded,
                      color: AdminColors.emerald),
                  title: Text(
                    item['userName'] as String? ?? 'Mtumiaji',
                    style: GoogleFonts.inter(
                      color: AdminColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    item['preview'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                        color: AdminColors.textDim, fontSize: 12),
                  ),
                  onTap: () {
                    final id = item['conversationId'] as String?;
                    if (id != null) _openConversation(id);
                  },
                ),
              );
            }),
            const SizedBox(height: 12),
            Text(
              'Mazungumzo yote',
              style: GoogleFonts.inter(
                color: AdminColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (_conversations.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Hakuna maswali bado',
                  style: GoogleFonts.inter(color: AdminColors.textDim),
                ),
              ),
            )
          else
            ..._conversations.map(_conversationTile),
        ],
      ),
    );
  }

  Widget _conversationTile(Map<String, dynamic> c) {
    final unread = (c['unreadCount'] as int?) ?? 0;
    final hasUnread = unread > 0 || c['hasUnread'] == true;
    return Card(
      color: hasUnread
          ? AdminColors.emerald.withValues(alpha: 0.1)
          : AdminColors.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          leading: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                backgroundColor: AdminColors.emerald.withValues(alpha: 0.2),
                child: Text(
                  (c['isGuest'] == true
                      ? 'M'
                      : (c['userName'] as String? ?? 'U'))[0],
                  style: const TextStyle(color: AdminColors.emerald),
                ),
              ),
              if (hasUnread)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: AdminColors.error,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      unread > 9 ? '9+' : '$unread',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            c['userName'] as String? ?? '',
            style: GoogleFonts.inter(
              color: AdminColors.textPrimary,
              fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            c['isGuest'] == true
                ? 'Mgeni · ${c['lastMessage'] as String? ?? ''}'
                : (c['lastMessage'] as String? ?? ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: hasUnread ? AdminColors.textPrimary : AdminColors.textDim,
              fontSize: 12,
              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          trailing: c['isPremium'] == true
              ? const Icon(Icons.star, color: AdminColors.amber, size: 16)
              : c['isGuest'] == true
                  ? Icon(Icons.person_outline,
                      color: AdminColors.textDim.withValues(alpha: 0.6),
                      size: 18)
                  : hasUnread
                      ? const Icon(Icons.circle,
                          color: AdminColors.emerald, size: 10)
                      : null,
          onTap: () => _openConversation(c['id'] as String),
        ),
      ),
    );
  }

  Widget _buildChatDetail() {
    return Column(
      children: [
        ListTile(
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AdminColors.emerald),
              onPressed: () async {
                setState(() => _selectedConvId = null);
                await _loadConversations(silent: true);
              }),
          title: Text('Maswali ya Mwanafunzi',
              style: GoogleFonts.inter(
                  color: AdminColors.textPrimary, fontWeight: FontWeight.w700)),
          subtitle: Text(
            'Inasasishwa kiotomatiki',
            style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
          ),
        ),
        Expanded(
          child: _loadingMessages
              ? const Center(
                  child: CircularProgressIndicator(color: AdminColors.emerald),
                )
              : RefreshIndicator(
                  color: AdminColors.emerald,
                  onRefresh: () => _reloadMessages(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final isAdmin = m['senderType'] == 'admin';
                      return Align(
                        alignment: isAdmin
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: isAdmin
                                ? AdminColors.emerald.withValues(alpha: 0.2)
                                : AdminColors.surface,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(m['content'] as String,
                              style: GoogleFonts.inter(
                                  color: AdminColors.textPrimary,
                                  fontSize: 13)),
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
              IconButton(
                tooltip: 'Shiriki makala',
                onPressed: _pickAndShareArticle,
                icon:
                    const Icon(Icons.link_rounded, color: AdminColors.emerald),
              ),
              Expanded(
                child: TextField(
                  controller: _replyCtrl,
                  style: GoogleFonts.inter(color: AdminColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Jibu kwa elimu tu...',
                    hintStyle: GoogleFonts.inter(color: AdminColors.textDim),
                    filled: true,
                    fillColor: AdminColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  if (_replyCtrl.text.trim().isEmpty ||
                      _selectedConvId == null) {
                    return;
                  }
                  await context
                      .read<AdminProvider>()
                      .contentService
                      .replyToConversation(
                          _selectedConvId!, _replyCtrl.text);
                  _replyCtrl.clear();
                  await _reloadMessages();
                  await context
                      .read<AdminProvider>()
                      .refreshMwalimuUnread(silent: true);
                },
                icon: const Icon(Icons.send, color: AdminColors.emerald),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndShareArticle() async {
    if (_selectedConvId == null || _publishedArticles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hakuna makala zilizochapishwa')),
        );
      }
      return;
    }
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: AdminColors.surface,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Chagua makala ya kushiriki',
                  style: GoogleFonts.inter(
                      color: AdminColors.textPrimary,
                      fontWeight: FontWeight.w700)),
            ),
            ..._publishedArticles.map((p) => ListTile(
                  title: Text(p['title'] as String? ?? '',
                      style: GoogleFonts.inter(color: AdminColors.textPrimary)),
                  onTap: () => Navigator.pop(ctx, p),
                )),
          ],
        ),
      ),
    );
    if (selected == null || _selectedConvId == null) return;
    final title = selected['title'] as String? ?? 'Makala';
    final excerpt = selected['excerpt'] as String? ?? '';
    final body =
        'Soma makala: $title${excerpt.isNotEmpty ? '\n\n$excerpt' : ''}';
    await context
        .read<AdminProvider>()
        .contentService
        .replyToConversation(_selectedConvId!, body);
    await _reloadMessages();
  }

  Widget _field(TextEditingController ctrl, String label, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        style: GoogleFonts.inter(color: AdminColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.inter(color: AdminColors.textDim),
          filled: true,
          fillColor: AdminColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
        ),
      ),
    );
  }
}
