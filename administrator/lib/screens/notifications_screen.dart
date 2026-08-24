import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../widgets/admin_ui.dart';
import '../widgets/url_image.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        backgroundColor: AdminColors.card,
        onRefresh: () async {
          await provider.refreshNotifications();
          await provider.refreshData();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            sliverAppBar(context, provider, notifications.length),
            if (notifications.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: AdminEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'No notification history yet',
                  subtitle: 'Sent broadcasts are saved here so you can review or delete them.',
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, idx) => Animate(
                      delay: Duration(milliseconds: idx * 40),
                      effects: const [
                        FadeEffect(duration: Duration(milliseconds: 350)),
                        SlideEffect(
                          begin: Offset(0, 0.05),
                          end: Offset.zero,
                          duration: Duration(milliseconds: 350),
                        ),
                      ],
                      child: _NotificationCard(
                        notification: notifications[idx],
                        onDelete: () => _confirmDeleteOne(context, provider, notifications[idx]),
                      ),
                    ),
                    childCount: notifications.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget sliverAppBar(BuildContext context, AdminProvider provider, int count) {
    return AdminPageHeader(
      title: 'Notifications',
      subtitle: '$count in history',
      actions: [
        if (count > 0)
          AdminIconButton(
            icon: Icons.delete_sweep_rounded,
            label: 'Clear',
            color: AdminColors.error,
            onTap: () => _confirmClearAll(context, provider),
          ),
        if (count > 0) const SizedBox(width: 8),
        AdminIconButton(
          icon: Icons.add_rounded,
          label: 'New',
          onTap: () => _showComposeSheet(context, provider),
        ),
      ],
    );
  }

  Future<void> _confirmDeleteOne(
    BuildContext context,
    AdminProvider provider,
    AdminNotification notification,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Text('Delete notification?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Remove "${notification.title}" from history? This does not unsend the push.',
          style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AdminColors.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.inter(color: AdminColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final err = await provider.deleteNotification(notification.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err == null ? 'Notification removed from history' : 'Delete failed: $err',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: err == null ? AdminColors.forest : AdminColors.error,
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, AdminProvider provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        title: Text('Clear all history?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'This permanently deletes every saved notification from admin history.',
          style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AdminColors.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Clear all',
              style: GoogleFonts.inter(color: AdminColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final err = await provider.clearNotificationHistory();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          err == null ? 'Notification history cleared' : 'Clear failed: $err',
          style: GoogleFonts.inter(color: Colors.white),
        ),
        backgroundColor: err == null ? AdminColors.forest : AdminColors.error,
      ),
    );
  }

  void _showComposeSheet(BuildContext context, AdminProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ComposeSheet(provider: provider),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onDelete,
  });

  final AdminNotification notification;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(notification.status);
    final statusLabel = _statusLabel(notification.status);
    final targetLabel = _targetLabel(notification.target);
    final targetColor = _targetColor(notification.target);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AdminColors.error.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_rounded, color: AdminColors.error),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_statusIcon(notification.status), color: statusColor, size: 16),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.title,
                    style: GoogleFonts.inter(
                      color: AdminColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: Icon(Icons.delete_outline_rounded,
                      size: 18, color: AdminColors.textDim.withOpacity(0.9)),
                ),
                _Badge(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              notification.body,
              style: GoogleFonts.inter(
                color: AdminColors.textSecondary,
                fontSize: 12,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AdminColors.cardBorder),
            const SizedBox(height: 10),
            Row(
              children: [
                _Badge(label: targetLabel, color: targetColor),
                const SizedBox(width: 8),
                if (notification.sentCount > 0) ...[
                  const Icon(Icons.send_rounded, size: 11, color: AdminColors.textDim),
                  const SizedBox(width: 4),
                  Text(
                    '${notification.sentCount} sent',
                    style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                  ),
                  const SizedBox(width: 8),
                ],
                const Spacer(),
                Text(
                  _formatDate(notification.createdAt),
                  style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(NotificationStatus s) {
    switch (s) {
      case NotificationStatus.sent:
        return AdminColors.success;
      case NotificationStatus.scheduled:
        return AdminColors.blue;
      case NotificationStatus.draft:
        return AdminColors.textDim;
      case NotificationStatus.failed:
        return AdminColors.error;
    }
  }

  String _statusLabel(NotificationStatus s) {
    switch (s) {
      case NotificationStatus.sent:
        return 'Sent';
      case NotificationStatus.scheduled:
        return 'Scheduled';
      case NotificationStatus.draft:
        return 'Draft';
      case NotificationStatus.failed:
        return 'Failed';
    }
  }

  IconData _statusIcon(NotificationStatus s) {
    switch (s) {
      case NotificationStatus.sent:
        return Icons.check_circle_rounded;
      case NotificationStatus.scheduled:
        return Icons.schedule_rounded;
      case NotificationStatus.draft:
        return Icons.edit_note_rounded;
      case NotificationStatus.failed:
        return Icons.error_rounded;
    }
  }

  String _targetLabel(NotificationTarget t) {
    switch (t) {
      case NotificationTarget.all:
        return 'All Users';
      case NotificationTarget.premium:
        return 'Premium';
      case NotificationTarget.free:
        return 'Free';
    }
  }

  Color _targetColor(NotificationTarget t) {
    switch (t) {
      case NotificationTarget.all:
        return AdminColors.emerald;
      case NotificationTarget.premium:
        return AdminColors.amber;
      case NotificationTarget.free:
        return AdminColors.blue;
    }
  }

  String _formatDate(DateTime dt) => DateFormat('MMM d, y · HH:mm').format(dt.toLocal());
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ComposeSheet extends StatefulWidget {
  const _ComposeSheet({required this.provider});
  final AdminProvider provider;

  @override
  State<_ComposeSheet> createState() => _ComposeSheetState();
}

class _ComposeSheetState extends State<_ComposeSheet> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  NotificationTarget _target = NotificationTarget.all;
  bool _sending = false;
  bool _loadingPosts = true;
  List<Map<String, dynamic>> _posts = [];
  Map<String, dynamic>? _selectedPost;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    try {
      final posts = await widget.provider.contentService.fetchPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts.where((p) => p['isPublished'] == true).toList();
        _loadingPosts = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingPosts = false);
    }
  }

  void _selectPost(Map<String, dynamic>? post) {
    setState(() {
      _selectedPost = post;
      if (post != null) {
        _titleCtrl.text = post['title'] as String? ?? '';
        final excerpt = (post['excerpt'] as String? ?? '').trim();
        _bodyCtrl.text = excerpt.isNotEmpty ? excerpt : 'Gusa kusoma makala kamili';
      }
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);

    final target = switch (_target) {
      NotificationTarget.all => 'all',
      NotificationTarget.premium => 'premium',
      NotificationTarget.free => 'free',
    };

    try {
      final selectedId = _selectedPost?['id'] as String?;
      final Map<String, dynamic> result;
      if (selectedId != null && selectedId.isNotEmpty) {
        result = await widget.provider.contentService.sharePost(
          selectedId,
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
        );
      } else {
        result = await widget.provider.contentService.sendBroadcast(
          title: _titleCtrl.text.trim(),
          body: _bodyCtrl.text.trim(),
          target: target,
        );
      }
      final notification = result['notification'] as Map<String, dynamic>?;
      final sent = notification?['sent'] == true || notification?['status'] == 'sent';
      final targetCount = _target == NotificationTarget.all
          ? widget.provider.stats.totalUsers
          : _target == NotificationTarget.premium
              ? widget.provider.stats.premiumUsers
              : widget.provider.stats.freeUsers;

      if (notification != null) {
        widget.provider.addNotification(AdminNotification.fromJson({
          ...notification,
          'title': notification['title'] ?? _titleCtrl.text.trim(),
          'body': notification['body'] ?? _bodyCtrl.text.trim(),
          'target': notification['target'] ?? target,
          'status': notification['status'] ?? (sent ? 'sent' : 'failed'),
          'sentCount': notification['sentCount'] ?? (sent ? targetCount : 0),
          'createdAt': notification['createdAt'] ?? DateTime.now().toIso8601String(),
          'id': notification['id'] ?? 'n${DateTime.now().millisecondsSinceEpoch}',
        }));
      } else {
        widget.provider.addNotification(
          AdminNotification(
            id: 'n${DateTime.now().millisecondsSinceEpoch}',
            title: _titleCtrl.text.trim(),
            body: _bodyCtrl.text.trim(),
            target: _target,
            status: sent ? NotificationStatus.sent : NotificationStatus.failed,
            createdAt: DateTime.now(),
            sentCount: sent ? targetCount : 0,
          ),
        );
      }

      await widget.provider.refreshNotifications();

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent
                ? (_selectedPost != null
                    ? 'Makala imetumwa. Watumiaji wanaweza kubofya kuisoma.'
                    : 'Notification sent and saved to history')
                : 'Saved to history. Configure Firebase on Railway for push delivery.',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: sent ? AdminColors.forest : AdminColors.amber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: $e', style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: AdminColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _pickMakala() async {
    if (_posts.isEmpty) return;
    final selected = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.65,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Chagua makala iliyochapishwa',
                        style: GoogleFonts.inter(
                          color: AdminColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded, color: AdminColors.textDim),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: _posts.length,
                  itemBuilder: (_, i) {
                    final p = _posts[i];
                    final imageUrl = p['imageUrl'] as String? ?? '';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: AdminColors.card,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => Navigator.pop(ctx, p),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: imageUrl.isNotEmpty
                                      ? UrlImage(url: imageUrl, width: 56, height: 56, borderRadius: 8)
                                      : Container(
                                          width: 56,
                                          height: 56,
                                          color: AdminColors.card,
                                          child: const Icon(Icons.article_rounded, color: AdminColors.emerald),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p['title'] as String? ?? 'Makala',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(
                                          color: AdminColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Gusa kutuma — mtumiaji atasoma ukurasa',
                                        style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: AdminColors.textDim),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (selected != null) _selectPost(selected);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Compose Notification',
                style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close_rounded, color: AdminColors.textDim, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Makala (si lazima)',
            style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Material(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _loadingPosts ? null : _pickMakala,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _loadingPosts
                    ? const SizedBox(
                        height: 36,
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AdminColors.emerald),
                          ),
                        ),
                      )
                    : _selectedPost == null
                        ? Row(
                            children: [
                              const Icon(Icons.article_outlined, color: AdminColors.emerald, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _posts.isEmpty
                                      ? 'Hakuna makala iliyochapishwa bado'
                                      : 'Chagua makala ili watumiaji waisome kwa kubofya',
                                  style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AdminColors.textDim),
                            ],
                          )
                        : Row(
                            children: [
                              UrlImage(
                                url: _selectedPost!['imageUrl'] as String? ?? '',
                                width: 48,
                                height: 48,
                                borderRadius: 8,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _selectedPost!['title'] as String? ?? 'Makala',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: AdminColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Ondoa',
                                onPressed: () => _selectPost(null),
                                icon: const Icon(Icons.close_rounded, color: AdminColors.textDim, size: 18),
                              ),
                            ],
                          ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Title', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _titleCtrl,
            style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Notification title...'),
          ),
          const SizedBox(height: 14),
          Text('Message', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _bodyCtrl,
            maxLines: 3,
            style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
            decoration: const InputDecoration(hintText: 'Write your message...'),
          ),
          if (_selectedPost == null) ...[
          const SizedBox(height: 14),
          Text('Target Audience', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: NotificationTarget.values.map((t) {
              final selected = _target == t;
              final label = t == NotificationTarget.all
                  ? 'All'
                  : t == NotificationTarget.premium
                      ? 'Premium'
                      : 'Free';
              final color = t == NotificationTarget.all
                  ? AdminColors.emerald
                  : t == NotificationTarget.premium
                      ? AdminColors.amber
                      : AdminColors.blue;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _target = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? color.withOpacity(0.2) : AdminColors.card,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: selected ? color : AdminColors.cardBorder),
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inter(
                        color: selected ? color : AdminColors.textDim,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _sending ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AdminColors.emerald,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _sending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _selectedPost != null ? 'Tuma makala' : 'Send Notification',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
