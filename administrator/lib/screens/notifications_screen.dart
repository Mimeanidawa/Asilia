import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final notifications = provider.notifications;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: AdminColors.bg,
            pinned: true,
            elevation: 0,
            toolbarHeight: 72,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: GoogleFonts.inter(
                          color: AdminColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        '${notifications.length} total',
                        style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showComposeSheet(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        gradient: AdminColors.emeraldGradient,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: AdminColors.emerald.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'New',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, idx) => Animate(
                  delay: Duration(milliseconds: idx * 50),
                  effects: const [
                    FadeEffect(duration: Duration(milliseconds: 350)),
                    SlideEffect(begin: Offset(0, 0.05), end: Offset.zero, duration: Duration(milliseconds: 350)),
                  ],
                  child: _NotificationCard(notification: notifications[idx]),
                ),
                childCount: notifications.length,
              ),
            ),
          ),
        ],
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
  const _NotificationCard({required this.notification});
  final AdminNotification notification;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(notification.status);
    final statusLabel = _statusLabel(notification.status);
    final targetLabel = _targetLabel(notification.target);
    final targetColor = _targetColor(notification.target);

    return Container(
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
                  '${notification.sentCount.toString()} sent',
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

  String _formatDate(DateTime dt) => DateFormat('MMM d, y').format(dt);
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

// ---- Compose Sheet ----

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

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_titleCtrl.text.trim().isEmpty || _bodyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    final targetCount = _target == NotificationTarget.all
        ? widget.provider.stats.totalUsers
        : _target == NotificationTarget.premium
            ? widget.provider.stats.premiumUsers
            : widget.provider.stats.freeUsers;
    widget.provider.addNotification(
      AdminNotification(
        id: 'n${DateTime.now().millisecondsSinceEpoch}',
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        target: _target,
        status: NotificationStatus.sent,
        createdAt: DateTime.now(),
        sentCount: targetCount,
      ),
    );
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Notification sent to $targetCount users',
            style: GoogleFonts.inter(color: Colors.white),
          ),
          backgroundColor: AdminColors.forest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottom),
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
          const SizedBox(height: 20),
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
          const SizedBox(height: 14),
          Text('Target Audience', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: NotificationTarget.values.map((t) {
              final selected = _target == t;
              final label = t == NotificationTarget.all ? 'All' : t == NotificationTarget.premium ? 'Premium' : 'Free';
              final color = t == NotificationTarget.all ? AdminColors.emerald : t == NotificationTarget.premium ? AdminColors.amber : AdminColors.blue;
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
                        Text('Send Notification', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
