import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../services/content_service.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    final content = context.watch<ContentService>();

    return Drawer(
      backgroundColor: AppColors.surfaceElevated,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                gradient: AppColors.heroGradient,
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Icon(
                      Icons.spa_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Dawa Asili',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Elimu ya dawa za asili kwa Kiswahili',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${content.allMakalaPosts.length} makala zilizopo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                children: [
                  _drawerItem(
                    context,
                    Icons.home_rounded,
                    'Nyumbani',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.home);
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.school_rounded,
                    'Darasa Huru',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.darasaHuru);
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.menu_book_rounded,
                    'Jifunze',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.learn);
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.grass_rounded,
                    'Dodoso',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.contentList, contentSection: ContentSections.dodoso);
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.category_rounded,
                    'Chagua Mada',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.contentList, contentSection: ContentSections.chaguaMada);
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.restaurant_rounded,
                    'Vyakula na Matunda',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.contentList, contentSection: ContentSections.vyakulaMatunda);
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _drawerItem(
                    context,
                    Icons.chat_bubble_rounded,
                    'Uliza Mwalimu',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.askExpert);
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.notifications_rounded,
                    'Taarifa',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.notifications);
                    },
                  ),
                  _drawerItem(
                    context,
                    Icons.person_rounded,
                    'Akaunti Yangu',
                    () {
                      Navigator.pop(context);
                      app.navigate(AppScreen.profile);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.emerald50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.forest, size: 20),
        ),
        title: Text(
          label,
          style: const TextStyle(
            color: AppColors.forest,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.gray400,
          size: 18,
        ),
        onTap: onTap,
      ),
    );
  }
}
