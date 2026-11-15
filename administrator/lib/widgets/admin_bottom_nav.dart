import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import 'admin_blur.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.current,
    required this.onTap,
    this.mwalimuUnread = 0,
    this.prospectCount = 0,
    this.onMaswaliTap,
  });

  final AdminScreen current;
  final void Function(AdminScreen) onTap;
  final int mwalimuUnread;
  final int prospectCount;
  final VoidCallback? onMaswaliTap;

  /// Height of the floating bar itself (matches the Container height below).
  static const double barHeight = 68;

  /// Outer bottom margin under the bar (matches Padding below).
  static const double barBottomMargin = 12;

  /// Space to leave clear above the floating nav for FABs / last list items.
  static double contentBottomInset(BuildContext context, {double extra = 0}) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return barHeight + barBottomMargin + safeBottom + extra;
  }

  static const _primaryScreens = {
    AdminScreen.dashboard,
    AdminScreen.users,
    AdminScreen.content,
    AdminScreen.mwalimu,
  };

  bool _isMoreActive() => !_primaryScreens.contains(current);

  void _showMoreMenu(BuildContext context) {
    showAdminSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _MoreMenuSheet(
        current: current,
        prospectCount: prospectCount,
        onSelect: (screen) {
          Navigator.pop(ctx);
          onTap(screen);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: AdminColors.surface.withValues(alpha: 0.62),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AdminColors.cardBorder.withValues(alpha: 0.8)),
              ),
              child: Row(
          children: [
            _NavSlot(
              icon: Icons.space_dashboard_rounded,
              label: 'Home',
              active: current == AdminScreen.dashboard,
              onTap: () => onTap(AdminScreen.dashboard),
            ),
            _NavSlot(
              icon: Icons.group_rounded,
              label: 'Users',
              active: current == AdminScreen.users,
              onTap: () => onTap(AdminScreen.users),
            ),
            _MaswaliSlot(
              active: current == AdminScreen.mwalimu,
              unread: mwalimuUnread,
              onTap: onMaswaliTap ?? () => onTap(AdminScreen.mwalimu),
            ),
            _NavSlot(
              icon: Icons.article_rounded,
              label: 'Content',
              active: current == AdminScreen.content,
              onTap: () => onTap(AdminScreen.content),
            ),
            _NavSlot(
              icon: Icons.grid_view_rounded,
              label: 'More',
              active: _isMoreActive(),
              onTap: () => _showMoreMenu(context),
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

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: active ? AdminColors.emeraldGlow : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: active ? AdminColors.emerald : AdminColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AdminColors.emerald : AdminColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaswaliSlot extends StatelessWidget {
  const _MaswaliSlot({
    required this.active,
    required this.unread,
    required this.onTap,
  });

  final bool active;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: active
                          ? AdminColors.primaryGradient
                          : const LinearGradient(
                              colors: [
                                AdminColors.card,
                                AdminColors.cardHover,
                              ],
                            ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: active
                            ? AdminColors.emerald.withValues(alpha: 0.5)
                            : AdminColors.cardBorder,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AdminColors.emerald.withValues(alpha: active ? 0.3 : 0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.forum_rounded,
                      color: active ? const Color(0xFF052E16) : AdminColors.emerald,
                      size: 22,
                    ),
                  ),
                  if (unread > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        decoration: BoxDecoration(
                          color: AdminColors.rose,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.surface, width: 2),
                        ),
                        child: Text(
                          unread > 99 ? '99+' : '$unread',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Maswali',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? AdminColors.emerald : AdminColors.textDim,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreMenuSheet extends StatelessWidget {
  const _MoreMenuSheet({
    required this.current,
    required this.onSelect,
    this.prospectCount = 0,
  });

  final AdminScreen current;
  final void Function(AdminScreen) onSelect;
  final int prospectCount;

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(
            color: AdminColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AdminColors.cardBorder),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AdminColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'More',
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
                _MoreTile(
                  icon: Icons.medication_rounded,
                  label: 'Dawa & Bidhaa',
                  subtitle: 'Post & manage dawa (50% off)',
                  color: AdminColors.emerald,
                  active: current == AdminScreen.products,
                  onTap: () => onSelect(AdminScreen.products),
                ),
                _MoreTile(
                  icon: Icons.local_shipping_rounded,
                  label: 'Oda & Risiti',
                  subtitle: 'Customer orders & transit',
                  color: AdminColors.rose,
                  active: current == AdminScreen.orders,
                  onTap: () => onSelect(AdminScreen.orders),
                ),
                _MoreTile(
                  icon: Icons.payments_rounded,
                  label: 'Malipo',
                  subtitle: 'Premium, makala & dawa — live',
                  color: AdminColors.amber,
                  active: current == AdminScreen.payments,
                  onTap: () => onSelect(AdminScreen.payments),
                ),
                _MoreTile(
                  icon: Icons.bookmark_added_rounded,
                  label: 'Prospects',
                  subtitle: 'Promised to buy later',
                  color: AdminColors.purple,
                  active: current == AdminScreen.prospects,
                  count: prospectCount,
                  onTap: () => onSelect(AdminScreen.prospects),
                ),
                _MoreTile(
                  icon: Icons.insights_rounded,
                  label: 'Analytics',
                  subtitle: 'Charts & performance',
                  color: AdminColors.blue,
                  active: current == AdminScreen.analytics,
                  onTap: () => onSelect(AdminScreen.analytics),
                ),
                _MoreTile(
                  icon: Icons.campaign_rounded,
                  label: 'Notifications',
                  subtitle: 'Broadcast history',
                  color: AdminColors.amber,
                  active: current == AdminScreen.notifications,
                  onTap: () => onSelect(AdminScreen.notifications),
                ),
                _MoreTile(
                  icon: Icons.school_rounded,
                  label: 'Darasa Huru',
                  subtitle: 'Daily lessons',
                  color: AdminColors.purple,
                  active: current == AdminScreen.darasaHuru,
                  onTap: () => onSelect(AdminScreen.darasaHuru),
                ),
                _MoreTile(
                  icon: Icons.tune_rounded,
                  label: 'Settings',
                  subtitle: 'App configuration',
                  color: AdminColors.textMuted,
                  active: current == AdminScreen.settings,
                  onTap: () => onSelect(AdminScreen.settings),
                ),
                SizedBox(height: bottomPad + 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.active,
    required this.onTap,
    this.count = 0,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool active;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: active ? 0.18 : 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? color.withValues(alpha: 0.4) : AdminColors.cardBorder,
                  ),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        color: AdminColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: GoogleFonts.plusJakartaSans(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (active)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AdminColors.emerald,
                    shape: BoxShape.circle,
                  ),
                )
              else
                const Icon(Icons.chevron_right_rounded, color: AdminColors.textDim, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
