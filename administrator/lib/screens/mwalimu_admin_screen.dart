import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/makala_share.dart';
import '../utils/phone_call.dart';
import '../widgets/admin_blur.dart';
import '../widgets/admin_bottom_nav.dart';
import '../widgets/makala_message.dart';
import '../widgets/makala_picker_sheet.dart';
import 'users_screen.dart';

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
  final _messageScroll = ScrollController();
  Timer? _refreshTimer;
  bool _loadingInbox = true;
  bool _loadingMessages = false;
  bool _sending = false;
  bool _uploadingImage = false;
  bool _savingProspect = false;
  final _imagePicker = ImagePicker();

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
    if (mounted) setState(() => _loadingInbox = false);
  }

  Future<void> _loadConversations({bool silent = false}) async {
    try {
      final list =
          await context.read<AdminProvider>().contentService.fetchConversations();
      if (!mounted) return;
      setState(() {
        _conversations = list;
        _loadingInbox = false;
      });
      await context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
    } catch (_) {}
  }

  Future<void> _openConversation(String convId) async {
    // Clear previous thread immediately so it never flashes while loading.
    setState(() {
      _selectedConvId = convId;
      _messages = [];
      _loadingMessages = true;
      _replyCtrl.clear();
    });
    final openedFor = convId;
    final svc = context.read<AdminProvider>().contentService;
    try {
      await svc.markConversationRead(convId);
      final msgs = await svc.fetchMessages(convId);
      if (!mounted || _selectedConvId != openedFor) return;
      setState(() {
        _messages = msgs;
        _loadingMessages = false;
      });
      _scrollMessagesToEnd();
      await context.read<AdminProvider>().refreshMwalimuUnread(silent: true);
      await _loadConversations(silent: true);
      if (!mounted || _selectedConvId != openedFor) return;
      final opened = _conversations.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['id']?.toString() == convId,
            orElse: () => null,
          );
      final userId = opened?['userId']?.toString();
      final provider = context.read<AdminProvider>();
      if (userId != null &&
          userId.isNotEmpty &&
          provider.users.every((u) => u.id != userId)) {
        unawaited(provider.refreshData());
      }
    } catch (_) {
      if (mounted && _selectedConvId == openedFor) {
        setState(() => _loadingMessages = false);
      }
    }
  }

  Future<void> _reloadMessages({bool silent = false}) async {
    final id = _selectedConvId;
    if (id == null || _loadingMessages) return;
    try {
      final msgs =
          await context.read<AdminProvider>().contentService.fetchMessages(id);
      if (!mounted || _selectedConvId != id) return;
      final pending = _messages.where((m) => m['pending'] == true).toList();
      final grew = msgs.length + pending.length > _messages.length;
      setState(() => _messages = [...msgs, ...pending]);
      if (grew) _scrollMessagesToEnd();
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
    _messageScroll.dispose();
    super.dispose();
  }

  String _previewMessage(String? raw) {
    final text = raw ?? '';
    if (text.contains('[IMAGE:')) {
      return '📷 Picha';
    }
    if (text.contains('[MAKALA:')) {
      return '📄 Makala imeshirikiwa';
    }
    return text;
  }

  int get _unreadTotal => _conversations.fold<int>(
        0,
        (sum, c) => sum + ((c['unreadCount'] as int?) ?? 0),
      );

  Map<String, dynamic>? get _selectedConversation {
    final id = _selectedConvId;
    if (id == null) return null;
    for (final c in _conversations) {
      if (c['id']?.toString() == id) return c;
    }
    return null;
  }

  AdminUser? _linkedUser(AdminProvider provider, Map<String, dynamic> conv) {
    final id = conv['userId']?.toString();
    if (id == null || id.isEmpty) return null;
    for (final user in provider.users) {
      if (user.id == id) return user;
    }
    return null;
  }

  bool _conversationIsProspect(AdminProvider provider, Map<String, dynamic> conv) {
    return _linkedUser(provider, conv)?.isProspect ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final providerUnread = provider.mwalimuUnreadCount;
    final badge = providerUnread > 0 ? providerUnread : _unreadTotal;
    final conv = _selectedConversation;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // Handle keyboard + floating nav insets ourselves in the reply bar.
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        flexibleSpace: const AdminBarBlur(),
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
        title: conv == null
            ? Row(
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
              )
            : _ChatTitle(conv: conv),
        actions: conv == null
            ? null
            : [
                if (conv['isGuest'] != true && conv['userId'] != null)
                  IconButton(
                    tooltip: _conversationIsProspect(provider, conv)
                        ? 'Remove from Prospects'
                        : 'Save as Prospect',
                    onPressed: _savingProspect ? null : () => _toggleProspect(conv),
                    icon: Icon(
                      _conversationIsProspect(provider, conv)
                          ? Icons.bookmark_added_rounded
                          : Icons.bookmark_add_outlined,
                      color: AdminColors.purple,
                    ),
                  ),
                IconButton(
                  tooltip: 'Profile',
                  onPressed: () => _openProfile(conv),
                  icon: const Icon(Icons.person_rounded, color: AdminColors.emerald),
                ),
              ],
      ),
      body: _selectedConvId != null ? _buildChatDetail() : _buildChats(),
    );
  }

  Widget _buildChats() {
    return RefreshIndicator(
      color: AdminColors.emerald,
      onRefresh: () async {
        await _loadConversations();
        await _load();
      },
      child: _loadingInbox && _conversations.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [_InboxLoading()],
            )
          : _conversations.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.45,
                      child: Center(
                        child: Text(
                          'Hakuna maswali bado',
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textDim,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 120),
                  itemCount: _conversations.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    thickness: 1,
                    indent: 76,
                    color: AdminColors.cardBorder.withValues(alpha: 0.55),
                  ),
                  itemBuilder: (_, i) => _conversationTile(_conversations[i]),
                ),
    );
  }

  Widget _conversationTile(Map<String, dynamic> c) {
    final unread = (c['unreadCount'] as int?) ?? 0;
    final hasUnread = unread > 0 || c['hasUnread'] == true;
    final name = (c['userName'] as String?)?.trim().isNotEmpty == true
        ? (c['userName'] as String).trim()
        : (c['isGuest'] == true ? 'Mgeni' : 'Mtumiaji');
    final preview = c['isGuest'] == true
        ? 'Mgeni · ${_previewMessage(c['lastMessage'] as String?)}'
        : _previewMessage(c['lastMessage'] as String?);
    final timeLabel = _formatListTime(c['updatedAt'] ?? c['lastMessageAt'] ?? c['createdAt']);

    return Material(
      color: hasUnread
          ? AdminColors.emerald.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: () => _openConversation(c['id'] as String),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AdminColors.emerald.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.emerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                      if (hasUnread)
                    Positioned(
                      right: -1,
                      top: -1,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: AdminColors.rose,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: AdminColors.bg, width: 1.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unread > 9 ? '9+' : '${unread == 0 ? 1 : unread}',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: AdminColors.textPrimary,
                              fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (timeLabel.isNotEmpty)
                          Text(
                            timeLabel,
                            style: GoogleFonts.plusJakartaSans(
                              color: hasUnread
                                  ? AdminColors.emerald
                                  : AdminColors.textDim,
                              fontSize: 11,
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              color: hasUnread
                                  ? AdminColors.textSecondary
                                  : AdminColors.textMuted,
                              fontSize: 13,
                              fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (c['isPremium'] == true) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.star_rounded, color: AdminColors.amber, size: 14),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatListTime(dynamic raw) {
    if (raw == null) return '';
    final dt = raw is DateTime
        ? raw
        : DateTime.tryParse(raw.toString());
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(local.year, local.month, local.day);
    if (day == today) {
      final h = local.hour.toString().padLeft(2, '0');
      final m = local.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (day == today.subtract(const Duration(days: 1))) return 'Jana';
    if (now.difference(local).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[local.weekday - 1];
    }
    return '${local.day}/${local.month}';
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

  void _scrollMessagesToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_messageScroll.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_messageScroll.hasClients) return;
          _messageScroll.jumpTo(_messageScroll.position.maxScrollExtent);
        });
        return;
      }
      _messageScroll.animateTo(
        _messageScroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendReply() async {
    await _deliver(_replyCtrl.text.trim(), clearField: true);
  }

  Future<void> _pickAndSendImage() async {
    if (_selectedConvId == null || _uploadingImage || _sending) return;

    final source = await showAdminSheet<ImageSource>(
      context: context,
      backgroundColor: AdminColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AdminColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'Tuma picha',
                style: GoogleFonts.plusJakartaSans(
                  color: AdminColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AdminColors.emerald),
                title: Text('Kutoka gallery', style: GoogleFonts.plusJakartaSans(color: AdminColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded, color: AdminColors.blue),
                title: Text('Piga picha', style: GoogleFonts.plusJakartaSans(color: AdminColors.textPrimary)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final file = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1280,
        maxHeight: 1280,
        imageQuality: 70,
      );
      if (file == null || !mounted) return;

      setState(() => _uploadingImage = true);
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Picha haina data');
      }
      // Keep payload under typical proxy limits (~4–6MB).
      if (bytes.length > 5 * 1024 * 1024) {
        throw Exception('Picha ni kubwa mno. Chagua picha ndogo.');
      }
      final b64 = base64Encode(bytes);
      final mime = (file.mimeType?.startsWith('image/') == true)
          ? file.mimeType!
          : 'image/jpeg';

      debugPrint('Uploading chat image (${bytes.length} bytes, $mime)…');
      final uploaded = await context
          .read<AdminProvider>()
          .contentService
          .uploadChatImage(base64Data: b64, contentType: mime);
      if (!mounted) return;

      final url = (uploaded['url'] as String?)?.trim().isNotEmpty == true
          ? (uploaded['url'] as String).trim()
          : (uploaded['path'] as String?)?.trim() ?? '';
      if (url.isEmpty) {
        throw Exception('Seva haikurudisha URL ya picha');
      }

      final caption = _replyCtrl.text.trim();
      final body = caption.isEmpty ? '[IMAGE:$url]' : '[IMAGE:$url]\n$caption';
      _replyCtrl.clear();
      final sent = await _deliver(body);
      if (!sent && mounted) {
        throw Exception('Picha imepakuliwa lakini haijatumwa. Jaribu tena.');
      }
    } catch (e) {
      debugPrint('Chat image send failed: $e');
      if (!mounted) return;
      final msg = e.toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('ApiException: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            msg.contains('haijasasishwa')
                ? 'Seva haijasasishwa bado. Deploy backend mpya kisha ujaribu tena.'
                : msg,
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AdminColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _uploadingImage = false);
    }
  }

  Future<bool> _deliver(String text, {bool clearField = false}) async {
    final convId = _selectedConvId;
    if (text.isEmpty || convId == null) return false;

    final localId = 'local_${DateTime.now().microsecondsSinceEpoch}';
    final pending = <String, dynamic>{
      'id': localId,
      'senderType': 'admin',
      'content': text,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'pending': true,
    };
    if (clearField) _replyCtrl.clear();
    setState(() {
      _sending = true;
      _messages = [..._messages, pending];
    });
    _scrollMessagesToEnd();

    try {
      final data = await context
          .read<AdminProvider>()
          .contentService
          .replyToConversation(convId, text);
      if (!mounted) return false;
      final saved = data['message'];
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m['id'] == localId)
              saved is Map<String, dynamic>
                  ? Map<String, dynamic>.from(saved)
                  : {...pending, 'pending': false}
            else
              m,
        ];
        _sending = _messages.any((m) => m['pending'] == true);
      });
      unawaited(context.read<AdminProvider>().refreshMwalimuUnread(silent: true));
      return true;
    } catch (_) {
      if (!mounted) return false;
      setState(() {
        _messages = [
          for (final m in _messages)
            if (m['id'] == localId)
              {...m, 'pending': false, 'failed': true}
            else
              m,
        ];
        _sending = _messages.any((m) => m['pending'] == true);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Imeshindwa kutuma ujumbe', style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AdminColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
  }

  Future<void> _openProfile(Map<String, dynamic> conv) async {
    final userId = conv['userId']?.toString();
    if (conv['isGuest'] == true || userId == null || userId.isEmpty) {
      _showGuestInfo();
      return;
    }

    final provider = context.read<AdminProvider>();
    var user = _linkedUser(provider, conv);
    if (user == null) {
      await provider.refreshData();
      if (!mounted) return;
      user = _linkedUser(context.read<AdminProvider>(), conv);
    }
    if (!mounted) return;
    final profile = user ?? _fallbackUser(conv, userId);
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserDetailScreen(user: profile)),
    );
  }

  AdminUser _fallbackUser(Map<String, dynamic> conv, String userId) {
    final updated = DateTime.tryParse(conv['updatedAt']?.toString() ?? '') ?? DateTime.now();
    return AdminUser(
      id: userId,
      name: (conv['userName'] as String?)?.trim().isNotEmpty == true
          ? (conv['userName'] as String).trim()
          : 'Mtumiaji',
      email: conv['userEmail'] as String?,
      phone: conv['userPhone'] as String?,
      authProvider: 'phone',
      plan: conv['isPremium'] == true ? UserPlan.premium : UserPlan.free,
      status: UserStatus.active,
      joinedAt: updated,
      lastActiveAt: updated,
      messageCount: (conv['messageCount'] as num?)?.toInt() ?? 0,
      purchaseCount: 0,
      totalSpent: 0,
    );
  }

  void _showGuestInfo() {
    showAdminSheet<void>(
      context: context,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mgeni',
              style: GoogleFonts.plusJakartaSans(
                color: AdminColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Huyu hajaingia kwenye akaunti, kwa hiyo hana wasifu wa kuhifadhi kama prospect.',
              style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleProspect(Map<String, dynamic> conv) async {
    final userId = conv['userId']?.toString();
    if (userId == null || userId.isEmpty || _savingProspect) return;
    final provider = context.read<AdminProvider>();
    final saving = !_conversationIsProspect(provider, conv);
    setState(() => _savingProspect = true);
    final error = await provider.updateUserProspect(userId, saving);
    if (!mounted) return;
    setState(() => _savingProspect = false);
    final name = conv['userName'] as String? ?? 'Mtumiaji';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? (saving ? '$name saved as a prospect' : '$name removed from prospects'),
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: error != null ? AdminColors.error : AdminColors.forest,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _callFromChat(String? phone) async {
    final raw = phone?.trim() ?? '';
    if (raw.isEmpty) return;
    final opened = await callPhoneNumber(raw);
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Could not open the phone app for $raw', style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: AdminColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildChatDetail() {
    final provider = context.watch<AdminProvider>();
    final conv = _selectedConversation;
    final bottomInset = _replyBarBottomInset(context);

    return Column(
      children: [
        if (conv != null) _ChatPersonBar(
          conv: conv,
          isProspect: _conversationIsProspect(provider, conv),
          saving: _savingProspect,
          onProfile: () => _openProfile(conv),
          onProspect: conv['isGuest'] == true ? null : () => _toggleProspect(conv),
          onCall: () => _callFromChat(conv['userPhone'] as String?),
        ),
        Expanded(
          child: _loadingMessages && _messages.isEmpty
              ? const _ThreadLoading()
              : RefreshIndicator(
                  color: AdminColors.emerald,
                  onRefresh: () => _reloadMessages(),
                  child: ListView.builder(
                    controller: _messageScroll,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final isAdmin = m['senderType'] == 'admin';
                      final prev = i > 0 ? _messages[i - 1] : null;
                      final sameSender = prev != null &&
                          prev['senderType'] == m['senderType'];
                      return _AdminBubble(
                        isAdmin: isAdmin,
                        content: m['content'] as String? ?? '',
                        createdAt: m['createdAt'],
                        sending: m['pending'] == true,
                        failed: m['failed'] == true,
                        grouped: sameSender,
                      );
                    },
                  ),
                ),
        ),
        ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Material(
          color: AdminColors.surface.withValues(alpha: 0.84),
          elevation: 0,
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
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickAndShareArticle,
                        icon: const Icon(Icons.article_outlined, size: 18),
                        label: Text(
                          'Makala',
                          style: GoogleFonts.plusJakartaSans(
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
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: (_uploadingImage || _sending) ? null : _pickAndSendImage,
                        icon: _uploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AdminColors.amber,
                                ),
                              )
                            : const Icon(Icons.image_rounded, size: 18),
                        label: Text(
                          _uploadingImage ? 'Inapakia…' : 'Picha',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AdminColors.amber,
                          side: BorderSide(
                            color: AdminColors.amber.withValues(alpha: 0.45),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
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
                        style: GoogleFonts.plusJakartaSans(color: AdminColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Andika jibu… (au caption ya picha)',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textDim,
                            fontSize: 13,
                          ),
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
                        onTap: (_sending || _uploadingImage) ? null : _sendReply,
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: _sending
                              ? const Padding(
                                  padding: EdgeInsets.all(14),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Color(0xFF052E16),
                                  ),
                                )
                              : const Icon(
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
    final selected = await showAdminSheet<Map<String, dynamic>>(
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

    final sent = await _deliver(body);
    if (sent && mounted) {
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

class _InboxLoading extends StatelessWidget {
  const _InboxLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          _LoadRow(width: 220),
          _LoadRow(width: 180),
          _LoadRow(width: 200),
          SizedBox(height: 8),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AdminColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadLoading extends StatelessWidget {
  const _ThreadLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        children: [
          _LoadBubble(alignEnd: false),
          _LoadBubble(alignEnd: true),
          _LoadBubble(alignEnd: false),
          SizedBox(height: 12),
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AdminColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadRow extends StatelessWidget {
  const _LoadRow({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: width,
        height: 58,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.cardBorder),
        ),
      ),
    );
  }
}

class _LoadBubble extends StatelessWidget {
  const _LoadBubble({required this.alignEnd});

  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: alignEnd ? 150 : 190,
        height: 44,
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: alignEnd
              ? AdminColors.emerald.withValues(alpha: 0.16)
              : AdminColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(alignEnd ? 16 : 4),
            bottomRight: Radius.circular(alignEnd ? 4 : 16),
          ),
        ),
      ),
    );
  }
}

class _AdminBubble extends StatelessWidget {
  const _AdminBubble({
    required this.isAdmin,
    required this.content,
    this.createdAt,
    this.sending = false,
    this.failed = false,
    this.grouped = false,
  });

  final bool isAdmin;
  final String content;
  final dynamic createdAt;
  final bool sending;
  final bool failed;
  final bool grouped;

  String get _timeLabel {
    if (createdAt == null) return '';
    final dt = createdAt is DateTime
        ? createdAt as DateTime
        : DateTime.tryParse(createdAt.toString());
    if (dt == null) return '';
    final local = dt.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;
    final radius = BorderRadius.only(
      topLeft: Radius.circular(isAdmin || !grouped ? 18 : 10),
      topRight: Radius.circular(!isAdmin || !grouped ? 18 : 10),
      bottomLeft: Radius.circular(isAdmin ? 18 : 6),
      bottomRight: Radius.circular(isAdmin ? 6 : 18),
    );

    return Padding(
      padding: EdgeInsets.only(
        top: grouped ? 3 : 10,
        bottom: 2,
        left: isAdmin ? 40 : 0,
        right: isAdmin ? 0 : 40,
      ),
      child: Align(
        alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth, minWidth: 56),
          child: Column(
            crossAxisAlignment:
                isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
                decoration: BoxDecoration(
                  color: isAdmin
                      ? (sending
                          ? AdminColors.emerald.withValues(alpha: 0.22)
                          : const Color(0xFF0F2A20))
                      : AdminColors.card,
                  borderRadius: radius,
                  border: Border.all(
                    color: isAdmin
                        ? AdminColors.emerald.withValues(alpha: 0.35)
                        : AdminColors.cardBorder.withValues(alpha: 0.8),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MakalaMessageContent(
                      content: content,
                      compact: true,
                      textStyle: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textPrimary,
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_timeLabel.isNotEmpty || sending || failed) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (failed)
                            Text(
                              'Imeshindwa',
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.error,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else if (sending)
                            Text(
                              'Inatuma…',
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text(
                              _timeLabel,
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.textDim,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (isAdmin && !sending && !failed) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.done_all_rounded,
                              size: 13,
                              color: AdminColors.emerald.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatTitle extends StatelessWidget {
  const _ChatTitle({required this.conv});

  final Map<String, dynamic> conv;

  @override
  Widget build(BuildContext context) {
    final name = (conv['userName'] as String?)?.trim().isNotEmpty == true
        ? (conv['userName'] as String).trim()
        : 'Mtumiaji';
    final phone = (conv['userPhone'] as String?)?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        Text(
          phone != null && phone.isNotEmpty
              ? phone
              : (conv['isGuest'] == true ? 'Mgeni' : 'Akaunti'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: AdminColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChatPersonBar extends StatelessWidget {
  const _ChatPersonBar({
    required this.conv,
    required this.isProspect,
    required this.saving,
    required this.onProfile,
    required this.onCall,
    this.onProspect,
  });

  final Map<String, dynamic> conv;
  final bool isProspect;
  final bool saving;
  final VoidCallback onProfile;
  final VoidCallback onCall;
  final VoidCallback? onProspect;

  @override
  Widget build(BuildContext context) {
    final name = (conv['userName'] as String?)?.trim().isNotEmpty == true
        ? (conv['userName'] as String).trim()
        : 'Mtumiaji';
    final phone = (conv['userPhone'] as String?)?.trim();
    final email = (conv['userEmail'] as String?)?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final detail = [
      if (hasPhone) phone,
      if (email != null && email.isNotEmpty) email,
      if (conv['isPremium'] == true) 'Premium',
      if (conv['isGuest'] == true) 'Mgeni',
    ].join(' · ');

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Material(
      color: AdminColors.card.withValues(alpha: 0.72),
      child: InkWell(
        onTap: onProfile,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AdminColors.emerald.withValues(alpha: 0.16),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    color: AdminColors.emerald,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    if (detail.isNotEmpty)
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasPhone)
                IconButton(
                  tooltip: 'Call',
                  onPressed: onCall,
                  icon: const Icon(Icons.call_rounded, color: AdminColors.emerald, size: 20),
                ),
              if (onProspect != null)
                IconButton(
                  tooltip: isProspect ? 'Remove from Prospects' : 'Save as Prospect',
                  onPressed: saving ? null : onProspect,
                  icon: Icon(
                    isProspect ? Icons.bookmark_added_rounded : Icons.bookmark_add_outlined,
                    color: AdminColors.purple,
                    size: 22,
                  ),
                ),
              IconButton(
                tooltip: 'Profile',
                onPressed: onProfile,
                icon: const Icon(Icons.chevron_right_rounded, color: AdminColors.textDim),
              ),
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }
}
