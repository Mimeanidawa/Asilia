import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({
    super.key,
    required this.current,
    required this.onTap,
  });

  final AdminScreen current;
  final void Function(AdminScreen) onTap;

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<AdminProvider>().mwalimuUnreadCount;

    return Container(
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(top: BorderSide(color: AdminColors.cardBorder, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: _NavItem(
                  icon: Icons.dashboard_rounded,
                  label: 'Dashboard',
                  screen: AdminScreen.dashboard,
                  current: current,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.people_rounded,
                  label: 'Users',
                  screen: AdminScreen.users,
                  current: current,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Analytics',
                  screen: AdminScreen.analytics,
                  current: current,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.notifications_rounded,
                  label: 'Notify',
                  screen: AdminScreen.notifications,
                  current: current,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.auto_stories_rounded,
                  label: 'Content',
                  screen: AdminScreen.content,
                  current: current,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.school_rounded,
                  label: 'Darasa',
                  screen: AdminScreen.darasaHuru,
                  current: current,
                  onTap: onTap,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.medical_services_rounded,
                  label: 'Mwalimu',
                  screen: AdminScreen.mwalimu,
                  current: current,
                  onTap: onTap,
                  badgeCount: unread,
                ),
              ),
              Expanded(
                child: _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  screen: AdminScreen.settings,
                  current: current,
                  onTap: onTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.screen,
    required this.current,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String label;
  final AdminScreen screen;
  final AdminScreen current;
  final void Function(AdminScreen) onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final isActive = screen == current;
    return GestureDetector(
      onTap: () => onTap(screen),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? AdminColors.emeraldGlow : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    key: ValueKey(isActive),
                    color: isActive ? AdminColors.emerald : AdminColors.textDim,
                    size: 20,
                  ),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -8,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 16),
                      decoration: BoxDecoration(
                        color: AdminColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 8,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? AdminColors.emerald : AdminColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
