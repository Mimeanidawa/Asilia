import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/admin_models.dart';
import '../theme/admin_colors.dart';

class UserListTile extends StatelessWidget {
  const UserListTile({
    super.key,
    required this.user,
    required this.onTap,
  });

  final AdminUser user;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: AdminColors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.cardBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AdminColors.emerald.withValues(alpha: 0.2),
                            AdminColors.blue.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AdminColors.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.emerald,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: _statusColor(user.status),
                          shape: BoxShape.circle,
                          border: const Border.fromBorderSide(
                            BorderSide(color: AdminColors.card, width: 2),
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
                              user.name,
                              style: GoogleFonts.plusJakartaSans(
                                color: AdminColors.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PlanBadge(plan: user.plan),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.displayContact,
                        style: GoogleFonts.plusJakartaSans(
                          color: AdminColors.textMuted,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          _MetaChip(icon: Icons.chat_bubble_outline_rounded, text: '${user.messageCount} msgs'),
                          _MetaChip(icon: Icons.shopping_bag_outlined, text: '${user.purchaseCount} buys'),
                          _MetaChip(
                            icon: Icons.calendar_today_rounded,
                            text: DateFormat('MMM d, y').format(user.joinedAt),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded, color: AdminColors.textDim, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(UserStatus status) {
    switch (status) {
      case UserStatus.active:
        return AdminColors.success;
      case UserStatus.suspended:
        return AdminColors.warning;
      case UserStatus.banned:
        return AdminColors.error;
    }
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: AdminColors.textDim),
        const SizedBox(width: 3),
        Text(
          text,
          style: GoogleFonts.plusJakartaSans(color: AdminColors.textDim, fontSize: 10),
        ),
      ],
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});
  final UserPlan plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan == UserPlan.premium;
    final color = isPremium ? AdminColors.amber : AdminColors.blue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.workspace_premium_rounded : Icons.person_rounded,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 3),
          Text(
            isPremium ? 'Premium' : 'Free',
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
