import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';
import '../theme/admin_colors.dart';
import '../utils/tzs_format.dart';
import '../widgets/user_list_tile.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AdminProvider>();
    final users = provider.filteredUsers;

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Users',
                        style: GoogleFonts.inter(
                          color: AdminColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                        ),
                      ),
                      Text(
                        '${provider.filteredUsers.length} of ${provider.stats.totalUsers}',
                        style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 11),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => _showFilterSheet(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AdminColors.emeraldGlow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AdminColors.emerald.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list_rounded, color: AdminColors.emerald, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Filter',
                            style: GoogleFonts.inter(
                              color: AdminColors.emerald,
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  onChanged: provider.setUserSearch,
                  style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Search by name, email, or phone...',
                    prefixIcon: Icon(Icons.search_rounded, color: AdminColors.textDim, size: 18),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            sliver: users.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Column(
                          children: [
                            const Icon(Icons.search_off_rounded, color: AdminColors.textDim, size: 48),
                            const SizedBox(height: 12),
                            Text(
                              'No users found',
                              style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, idx) => Animate(
                        delay: Duration(milliseconds: idx * 40),
                        effects: const [
                          FadeEffect(duration: Duration(milliseconds: 300)),
                          SlideEffect(begin: Offset(0, 0.05), end: Offset.zero, duration: Duration(milliseconds: 300)),
                        ],
                        child: UserListTile(
                          user: users[idx],
                          onTap: () => _openUserDetail(context, users[idx]),
                        ),
                      ),
                      childCount: users.length,
                    ),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, AdminProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AdminColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(provider: provider),
    );
  }

  void _openUserDetail(BuildContext context, AdminUser user) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => UserDetailScreen(user: user)),
    );
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({required this.provider});
  final AdminProvider provider;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Users',
                style: GoogleFonts.inter(
                  color: AdminColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextButton(
                onPressed: () {
                  provider.clearUserFilters();
                  Navigator.pop(context);
                },
                child: Text(
                  'Clear all',
                  style: GoogleFonts.inter(color: AdminColors.emerald, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Plan', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(label: 'All', selected: provider.userPlanFilter == null, onTap: () => provider.setUserPlanFilter(null)),
              _FilterChip(label: 'Premium', selected: provider.userPlanFilter == UserPlan.premium, onTap: () => provider.setUserPlanFilter(UserPlan.premium)),
              _FilterChip(label: 'Free', selected: provider.userPlanFilter == UserPlan.free, onTap: () => provider.setUserPlanFilter(UserPlan.free)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Status', style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _FilterChip(label: 'Active', selected: provider.userStatusFilter == UserStatus.active, onTap: () => provider.setUserStatusFilter(UserStatus.active)),
              _FilterChip(label: 'Suspended', selected: provider.userStatusFilter == UserStatus.suspended, onTap: () => provider.setUserStatusFilter(UserStatus.suspended)),
              _FilterChip(label: 'Banned', selected: provider.userStatusFilter == UserStatus.banned, onTap: () => provider.setUserStatusFilter(UserStatus.banned)),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AdminColors.emeraldGlow : AdminColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AdminColors.emerald : AdminColors.cardBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: selected ? AdminColors.emerald : AdminColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---- User Detail Screen ----

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.user});
  final AdminUser user;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<AdminProvider>();
    final fmt = DateFormat('MMM d, y');
    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AdminColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Profile',
          style: GoogleFonts.inter(
            color: AdminColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar + name
            Animate(
              effects: const [FadeEffect(duration: Duration(milliseconds: 400))],
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AdminColors.card, AdminColors.surface],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AdminColors.cardBorder),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        gradient: AdminColors.emeraldGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: AdminColors.emerald.withOpacity(0.3), blurRadius: 16),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (user.name.isNotEmpty ? user.name[0] : '?').toUpperCase(),
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      user.name,
                      style: GoogleFonts.inter(
                        color: AdminColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (user.email?.isNotEmpty == true)
                      Text(user.email!, style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 13)),
                    if (user.phone?.isNotEmpty == true)
                      Text(user.phone!, style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _StatusBadge(status: user.status),
                        const SizedBox(width: 8),
                        _PlanBadge(plan: user.plan),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Info grid
            Animate(
              delay: const Duration(milliseconds: 100),
              effects: const [FadeEffect(duration: Duration(milliseconds: 400))],
              child: GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
                children: [
                  _InfoCard(label: 'Messages', value: user.messageCount.toString(), icon: Icons.chat_rounded, color: AdminColors.emerald),
                  _InfoCard(label: 'Purchases', value: user.purchaseCount.toString(), icon: Icons.shopping_bag_rounded, color: AdminColors.blue),
                  _InfoCard(label: 'Total Spent', value: TzsFormat.compact(user.totalSpent.toDouble()), icon: Icons.payments_rounded, color: AdminColors.amber),
                  _InfoCard(label: 'Auth', value: user.authProvider, icon: Icons.login_rounded, color: AdminColors.purple),
                  _InfoCard(label: 'Joined', value: fmt.format(user.joinedAt), icon: Icons.calendar_today_rounded, color: AdminColors.amber),
                  _InfoCard(label: 'Last Active', value: fmt.format(user.lastActiveAt), icon: Icons.access_time_rounded, color: AdminColors.purple),
                  if (user.premiumUntil != null)
                    _InfoCard(label: 'Premium Until', value: fmt.format(user.premiumUntil!), icon: Icons.star_rounded, color: AdminColors.amber),
                ],
              ),
            ),
            if (user.purchasedContentIds.isNotEmpty) ...[
              const SizedBox(height: 16),
              Animate(
                delay: const Duration(milliseconds: 150),
                effects: const [FadeEffect(duration: Duration(milliseconds: 400))],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Purchased Content (${user.purchasedContentIds.length})',
                      style: GoogleFonts.inter(
                        color: AdminColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...user.purchasedContentIds.map(
                      (id) => Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AdminColors.card,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AdminColors.cardBorder),
                        ),
                        child: Text(
                          id,
                          style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Actions
            Animate(
              delay: const Duration(milliseconds: 200),
              effects: const [FadeEffect(duration: Duration(milliseconds: 400))],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: GoogleFonts.inter(
                      color: AdminColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (user.plan == UserPlan.free)
                    _ActionButton(
                      label: 'Upgrade to Premium',
                      icon: Icons.star_rounded,
                      color: AdminColors.amber,
                      onTap: () => _runUserAction(
                        context,
                        provider,
                        () => provider.updateUserPlan(user.id, UserPlan.premium),
                        successMessage: '${user.name} upgraded to Premium',
                      ),
                    )
                  else
                    _ActionButton(
                      label: 'Downgrade to Free',
                      icon: Icons.person_rounded,
                      color: AdminColors.blue,
                      onTap: () => _runUserAction(
                        context,
                        provider,
                        () => provider.updateUserPlan(user.id, UserPlan.free),
                        successMessage: '${user.name} downgraded to Free',
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (user.status == UserStatus.active)
                    _ActionButton(
                      label: 'Suspend Account',
                      icon: Icons.pause_circle_outline_rounded,
                      color: AdminColors.warning,
                      onTap: () => _runUserAction(
                        context,
                        provider,
                        () => provider.updateUserStatus(user.id, UserStatus.suspended),
                        successMessage: '${user.name} suspended',
                      ),
                    )
                  else if (user.status == UserStatus.suspended)
                    _ActionButton(
                      label: 'Reactivate Account',
                      icon: Icons.play_circle_outline_rounded,
                      color: AdminColors.success,
                      onTap: () => _runUserAction(
                        context,
                        provider,
                        () => provider.updateUserStatus(user.id, UserStatus.active),
                        successMessage: '${user.name} reactivated',
                      ),
                    )
                  else if (user.status == UserStatus.banned)
                    _ActionButton(
                      label: 'Unban User',
                      icon: Icons.check_circle_outline_rounded,
                      color: AdminColors.success,
                      onTap: () => _runUserAction(
                        context,
                        provider,
                        () => provider.updateUserStatus(user.id, UserStatus.active),
                        successMessage: '${user.name} has been unbanned',
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (user.status != UserStatus.banned)
                    _ActionButton(
                      label: 'Ban User',
                      icon: Icons.block_rounded,
                      color: AdminColors.error,
                      onTap: () => _confirmBan(context, provider),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBan(BuildContext context, AdminProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Ban User?',
          style: GoogleFonts.inter(color: AdminColors.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will permanently ban ${user.name}. They will lose all access.',
          style: GoogleFonts.inter(color: AdminColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: AdminColors.textDim)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AdminColors.error, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final nav = Navigator.of(context);
              final error = await provider.updateUserStatus(user.id, UserStatus.banned);
              nav.pop();
              if (error != null) {
                messenger.showSnackBar(_snackBar(error, isError: true));
                return;
              }
              nav.pop();
              messenger.showSnackBar(_snackBar('${user.name} has been banned'));
            },
            child: Text('Ban', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _runUserAction(
    BuildContext context,
    AdminProvider provider,
    Future<String?> Function() action, {
    required String successMessage,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final error = await action();
    if (!context.mounted) return;
    nav.pop();
    if (error != null) {
      messenger.showSnackBar(_snackBar(error, isError: true));
      return;
    }
    messenger.showSnackBar(_snackBar(successMessage));
  }

  SnackBar _snackBar(String msg, {bool isError = false}) => SnackBar(
        content: Text(msg, style: GoogleFonts.inter(color: Colors.white)),
        backgroundColor: isError ? AdminColors.error : AdminColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AdminColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AdminColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 10)),
                Text(
                  value,
                  style: GoogleFonts.inter(color: AdminColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: GoogleFonts.inter(color: color, fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6), size: 18),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == UserStatus.active
        ? AdminColors.success
        : status == UserStatus.suspended
            ? AdminColors.warning
            : AdminColors.error;
    final label = status.name[0].toUpperCase() + status.name.substring(1);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  const _PlanBadge({required this.plan});
  final UserPlan plan;

  @override
  Widget build(BuildContext context) {
    final isPremium = plan == UserPlan.premium;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isPremium ? AdminColors.amberGlow : AdminColors.blueGlow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isPremium ? AdminColors.amber.withOpacity(0.4) : AdminColors.blue.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPremium ? Icons.star_rounded : Icons.person_rounded, size: 11, color: isPremium ? AdminColors.amber : AdminColors.blue),
          const SizedBox(width: 4),
          Text(
            isPremium ? 'Premium' : 'Free',
            style: GoogleFonts.inter(
              color: isPremium ? AdminColors.amber : AdminColors.blue,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
