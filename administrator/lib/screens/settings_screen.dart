import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();

    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: RefreshIndicator(
        color: AdminColors.emerald,
        onRefresh: provider.refreshData,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
          SliverAppBar(
            backgroundColor: AdminColors.bg,
            pinned: true,
            elevation: 0,
            toolbarHeight: 72,
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Settings',
                style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Admin profile card
                Animate(
                  effects: const [FadeEffect(duration: Duration(milliseconds: 400))],
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AdminColors.forest, AdminColors.forestLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AdminColors.emerald.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Super Admin',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                provider.adminEmail ?? 'mimeanidawa@gmail.com',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Admin',
                            style: GoogleFonts.inter(
                              color: Colors.white,
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
                // App section
                Animate(
                  delay: const Duration(milliseconds: 100),
                  effects: const [FadeEffect(duration: Duration(milliseconds: 400))],
                  child: _SettingsSection(
                    title: 'Application',
                    items: [
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        label: 'App Version',
                        trailing: '1.0.0',
                        color: AdminColors.blue,
                      ),
                      _SettingsTile(
                        icon: Icons.eco_rounded,
                        label: 'App Name',
                        trailing: 'Dawa Asili',
                        color: AdminColors.emerald,
                      ),
                      _SettingsTile(
                        icon: Icons.people_rounded,
                        label: 'Total Users',
                        trailing: '12,847',
                        color: AdminColors.purple,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Logout
                Animate(
                  delay: const Duration(milliseconds: 400),
                  effects: const [FadeEffect(duration: Duration(milliseconds: 400))],
                  child: GestureDetector(
                    onTap: () => _confirmLogout(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: AdminColors.redGlow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AdminColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.logout_rounded, color: AdminColors.error, size: 20),
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
                          const Icon(Icons.chevron_right_rounded, color: AdminColors.error, size: 20),
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
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You will be returned to the login screen.',
          style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AdminColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(context);
              provider.logout();
            },
            child: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
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
                  if (!isLast) const Divider(height: 1, indent: 52, color: AdminColors.cardBorder),
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
                style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 13),
              ),
            if (showArrow)
              const Icon(Icons.chevron_right_rounded, color: AdminColors.textDim, size: 18),
          ],
        ),
      ),
    );
  }
}
