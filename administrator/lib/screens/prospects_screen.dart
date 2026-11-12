import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/phone_call.dart';
import '../widgets/admin_ui.dart';
import 'users_screen.dart';

class ProspectsScreen extends StatefulWidget {
  const ProspectsScreen({super.key});

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final all = provider.prospects;
    final q = _query.trim().toLowerCase();
    final prospects = q.isEmpty
        ? all
        : all.where((u) {
            return u.name.toLowerCase().contains(q) || (u.phone?.toLowerCase().contains(q) ?? false);
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        backgroundColor: AdminColors.card,
        onRefresh: provider.refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            AdminPageHeader(
              title: 'Prospects',
              subtitle: '${all.length} promised to buy later',
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: AdminSearchField(
                    hint: 'Search by name or phone...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
              sliver: prospects.isEmpty
                  ? SliverToBoxAdapter(
                      child: AdminEmptyState(
                        icon: Icons.bookmark_border_rounded,
                        title: all.isEmpty ? 'No prospects yet' : 'No matches',
                        subtitle: all.isEmpty
                            ? 'Open a user and tap Save as Prospect when they promise to buy later'
                            : 'Try another name or phone number',
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, idx) => Animate(
                          delay: Duration(milliseconds: idx.clamp(0, 8) * 40),
                          effects: const [
                            FadeEffect(duration: Duration(milliseconds: 300)),
                            SlideEffect(begin: Offset(0, 0.05), end: Offset.zero, duration: Duration(milliseconds: 300)),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ProspectTile(
                              user: prospects[idx],
                              onOpen: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => UserDetailScreen(user: prospects[idx])),
                                );
                              },
                              onCall: () => _call(context, prospects[idx]),
                              onRemove: () => _remove(context, provider, prospects[idx]),
                            ),
                          ),
                        ),
                        childCount: prospects.length,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _call(BuildContext context, AdminUser user) async {
    final phone = user.phone?.trim() ?? '';
    if (phone.isEmpty) {
      _snack(context, '${user.name} has no phone number', isError: true);
      return;
    }
    final opened = await callPhoneNumber(phone);
    if (!context.mounted) return;
    if (!opened) {
      _snack(context, 'Could not open the phone app for $phone', isError: true);
    }
  }

  Future<void> _remove(BuildContext context, AdminProvider provider, AdminUser user) async {
    final error = await provider.updateUserProspect(user.id, false);
    if (!context.mounted) return;
    if (error != null) {
      _snack(context, error, isError: true);
      return;
    }
    _snack(context, '${user.name} removed from prospects');
  }

  void _snack(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? AdminColors.error : AdminColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ProspectTile extends StatelessWidget {
  const _ProspectTile({
    required this.user,
    required this.onOpen,
    required this.onCall,
    required this.onRemove,
  });

  final AdminUser user;
  final VoidCallback onOpen;
  final VoidCallback onCall;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final phone = user.phone?.trim();
    final hasPhone = phone != null && phone.isNotEmpty;
    final saved = user.prospectAt;
    final savedLabel = saved == null ? null : 'Saved ${DateFormat('MMM d, y').format(saved)}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AdminColors.purpleGlow,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AdminColors.purple.withValues(alpha: 0.35)),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: AdminColors.purple,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasPhone ? phone : 'No phone number',
                        style: GoogleFonts.plusJakartaSans(
                          color: hasPhone ? AdminColors.textSecondary : AdminColors.textDim,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (savedLabel != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          savedLabel,
                          style: GoogleFonts.plusJakartaSans(
                            color: AdminColors.textDim,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Remove prospect',
                  onPressed: onRemove,
                  icon: const Icon(Icons.bookmark_remove_outlined, color: AdminColors.textMuted, size: 20),
                ),
                _CallButton(enabled: hasPhone, onTap: onCall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? AdminColors.emerald : AdminColors.cardHover,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.call_rounded,
                size: 18,
                color: enabled ? const Color(0xFF052E16) : AdminColors.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                'Call',
                style: GoogleFonts.plusJakartaSans(
                  color: enabled ? const Color(0xFF052E16) : AdminColors.textDim,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
