import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/makala_share.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/makala_message.dart';
import '../widgets/makala_picker_sheet.dart';

/// Maswali inbox — opened from the dashboard floating message button.
class MwalimuAdminScreen extends StatefulWidget {
  const MwalimuAdminScreen({super.key});

  @override
  State<MwalimuAdminScreen> createState() => _MwalimuAdminScreenState();
}

class _MwalimuAdminScreenState extends State<MwalimuAdminScreen> {
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
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      if (_selectedConvId != null) {
        _reloadMessages(silent: true);
      } else {
        _loadConversations(silent: true);
      }
      context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
    });
  }

  Future<void> _load() async {
    final svc = context.read<AdminProvider>().contentService;
    try {
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
    } catch (_) {}
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
    _replyCtrl.dispose();
    super.dispose();
  }

  String _previewMessage(String? raw) {
    final text = raw ?? '';
    if (text.contains('[MAKALA:')) {
      return '📄 Makala imeshirikiwa';
    }
    return text;
  }

  int get _unreadTotal => _conversations.fold<int>(
        0,
        (sum, c) => sum + ((c['unreadCount'] as int?) ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    final providerUnread = context.watch<AdminProvider>().mwalimuUnreadCount;
    final badge = providerUnread > 0 ? providerUnread : _unreadTotal;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Handle keyboard + floating nav insets ourselves in the reply bar.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (_selectedConvId != null) {
              setState(() => _selectedConvId = null);
              _loadConversations(silent: true);
            } else {
              context.read<AdminProvider>().setScreen(AdminScreen.dashboard);
            }
          },
        ),
        title: Row(
          children: [
            Text(
              'Maswali',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            if (badge > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AdminColors.rose,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: GoogleFonts.plusJakartaSans(
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
      body: _selectedConvId != null ? _buildChatDetail() : _buildChats(),
    );
  }

  Widget _buildChats() {
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
                    item['preview'] as String? ?? 'New message from user',
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
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
                ? 'Mgeni · ${_previewMessage(c['lastMessage'] as String?)}'
                : _previewMessage(c['lastMessage'] as String?),
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

  double _replyBarBottomInset(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context).bottom;
    if (viewInsets > 0) {
      // Sit just above the keyboard.
      return viewInsets + 8;
    }
    // Floating AdminBottomNav: bar + margin + safe area + breathing room.
    return AdminBottomNav.contentBottomInset(context, extra: 8);
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty || _selectedConvId == null) return;
    await context
        .read<AdminProvider>()
        .contentService
        .replyToConversation(_selectedConvId!, _replyCtrl.text);
    _replyCtrl.clear();
    await _reloadMessages();
    await context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
  }

  Widget _buildChatDetail() {
    final bottomInset = _replyBarBottomInset(context);

    return Column(
      children: [
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
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
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
                          child: MakalaMessageContent(
                            content: m['content'] as String? ?? '',
                            compact: true,
                            textStyle: GoogleFonts.inter(
                              color: AdminColors.textPrimary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
        Material(
          color: AdminColors.surface,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: 0.35),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: AdminColors.cardBorder.withValues(alpha: 0.6),
                ),
              ),
            ),
            padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _pickAndShareArticle,
                    icon: const Icon(Icons.article_outlined, size: 18),
                    label: Text(
                      'Shiriki makala',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AdminColors.emerald,
                      side: BorderSide(
                        color: AdminColors.emerald.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyCtrl,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        style: GoogleFonts.inter(color: AdminColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Andika jibu lako hapa...',
                          hintStyle:
                              GoogleFonts.inter(color: AdminColors.textDim),
                          filled: true,
                          fillColor: AdminColors.card,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: AdminColors.cardBorder
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AdminColors.emerald,
                              width: 1.4,
                            ),
                          ),
                        ),
                        onSubmitted: (_) => _sendReply(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: AdminColors.emerald,
                      borderRadius: BorderRadius.circular(14),
                      child: InkWell(
                        onTap: _sendReply,
                        borderRadius: BorderRadius.circular(14),
                        child: const SizedBox(
                          width: 48,
                          height: 48,
                          child: Icon(
                            Icons.send_rounded,
                            color: Color(0xFF052E16),
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MakalaPickerSheet(articles: _publishedArticles),
    );
    if (selected == null || _selectedConvId == null) return;

    final id = selected['id'] as String? ?? '';
    if (id.isEmpty) return;

    final title = selected['title'] as String? ?? 'Makala';
    final imageUrl = selected['imageUrl'] as String? ?? '';
    final body = MakalaShare.formatMessage(
      id: id,
      title: title,
      imageUrl: imageUrl.isNotEmpty ? imageUrl : null,
    );

    await context
        .read<AdminProvider>()
        .contentService
        .replyToConversation(_selectedConvId!, body);
    await _reloadMessages();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Makala imeshirikiwa: $title',
              style: GoogleFonts.inter()),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
