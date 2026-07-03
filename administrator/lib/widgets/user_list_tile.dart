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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AdminColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AdminColors.cardBorder),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AdminColors.forestLight,
                  child: Text(
                    user.name.substring(0, 1).toUpperCase(),
                    style: GoogleFonts.inter(
                      color: AdminColors.emerald,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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
                      border: const Border.fromBorderSide(BorderSide(color: AdminColors.card, width: 2)),
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
                          style: GoogleFonts.inter(
                            color: AdminColors.textPrimary,
                            fontWeight: FontWeight.w600,
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
                    user.email,
                    style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.flag_rounded, size: 10, color: AdminColors.textDim),
                      const SizedBox(width: 3),
                      Text(
                        user.country,
                        style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.calendar_today_rounded, size: 10, color: AdminColors.textDim),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('MMM d, y').format(user.joinedAt),
                        style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AdminColors.textDim, size: 18),
          ],
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

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});
  final UserPlan plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan == UserPlan.premium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPremium ? AdminColors.amberGlow : AdminColors.blueGlow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPremium ? AdminColors.amber.withOpacity(0.4) : AdminColors.blue.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPremium ? Icons.star_rounded : Icons.person_rounded,
            size: 10,
            color: isPremium ? AdminColors.amber : AdminColors.blue,
          ),
          const SizedBox(width: 3),
          Text(
            isPremium ? 'Premium' : 'Free',
            style: GoogleFonts.inter(
              color: isPremium ? AdminColors.amber : AdminColors.blue,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
