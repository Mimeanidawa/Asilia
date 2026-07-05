import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/app_refresh.dart';
import '../widgets/pull_to_refresh.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final userService = context.watch<UserService>();

    return SizedBox.expand(
      child: PullToRefresh(
        onRefresh: () async {
          await AppRefresh.user(context);
          await AppRefresh.catalog(context);
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              color: Colors.white,
              child: const Row(
                children: [
                  Icon(Icons.person_outline, color: AppColors.emerald800, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'MTUMIAJI',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: AppColors.forest,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: userService.isLoggedIn
                  ? Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: AppColors.emerald50,
                          child: Text(
                            userService.user!.fullName.isNotEmpty
                                ? userService.user!.fullName[0].toUpperCase()
                                : 'M',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: AppColors.forest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userService.user!.fullName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.forest,
                                ),
                              ),
                              Text(
                                userService.user!.phone ?? userService.user!.email ?? '',
                                style: const TextStyle(fontSize: 12, color: AppColors.gray400),
                              ),
                              const SizedBox(height: 6),
                              if (userService.user!.isPremiumActive)
                                const _MembershipBadge()
                              else
                                GestureDetector(
                                  onTap: () => userService.purchasePremium(),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.amber.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'PATA PREMIUM',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.amber,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => userService.logout(),
                          icon: Icon(Icons.logout, color: AppColors.gray400, size: 20),
                        ),
                      ],
                    )
                  : _GuestProfileCard(
                      onJoin: () => app.navigate(AppScreen.auth),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: AppColors.red50,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () async {
                    await app.resetProfileState();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile state reset successfully.'),
                      ),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: AppColors.red600, size: 18),
                        SizedBox(width: 12),
                        Text(
                          'Reset Local Profile State',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.red600,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.chevron_right, color: Color(0xFFFECACA)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuestProfileCard extends StatelessWidget {
  const _GuestProfileCard({required this.onJoin});

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.emerald50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          const Icon(Icons.eco, color: AppColors.forest, size: 40),
          const SizedBox(height: 12),
          const Text(
            'Karibu Dawa Asili!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.forest),
          ),
          const SizedBox(height: 6),
          Text(
            'Jiunge ili kusoma makala, kuuliza Mwalimu, na kufungua maudhui ya Premium',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.gray500, height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onJoin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Jiunge au Ingia', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembershipBadge extends StatelessWidget {
  const _MembershipBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'PREMIUM MEMBER',
        style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w900,
          color: AppColors.amber,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
