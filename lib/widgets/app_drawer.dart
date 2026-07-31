import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
      backgroundColor: AppColors.forest,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.forestLight,
                    AppColors.forest,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.eco_rounded, color: AppColors.cream, size: 32),
                  ),
                  const SizedBox(height: 14),
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
                      color: AppColors.cream.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${content.allMakalaPosts.length} makala',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _item(context, Icons.home_rounded, 'Nyumbani', () {
                    Navigator.pop(context);
                    app.navigate(AppScreen.home);
                  }, 0),
                  _item(context, Icons.grass_rounded, 'Dodoso', () {
                    Navigator.pop(context);
                    app.navigate(AppScreen.contentList, contentSection: ContentSections.dodoso);
                  }, 1),
                  _item(context, Icons.category_rounded, 'Chagua Mada', () {
                    Navigator.pop(context);
                    app.navigate(AppScreen.contentList, contentSection: ContentSections.chaguaMada);
                  }, 2),
                  _item(context, Icons.menu_book_rounded, 'Jifunze', () {
                    Navigator.pop(context);
                    app.navigate(AppScreen.learn);
                  }, 3),
                  _item(context, Icons.restaurant_rounded, 'Vyakula na Matunda', () {
                    Navigator.pop(context);
                    app.navigate(AppScreen.contentList, contentSection: ContentSections.vyakulaMatunda);
                  }, 4),
                  const Divider(color: Colors.white24, indent: 20, endIndent: 20),
                  _item(context, Icons.school_outlined, 'Uliza Mwalimu', () {
                    Navigator.pop(context);
                    app.navigate(AppScreen.askExpert);
                  }, 5),
                  _item(context, Icons.notifications_rounded, 'Arifa', () {
                    Navigator.pop(context);
                    app.navigate(AppScreen.notifications);
                  }, 6),
                  _item(context, Icons.person_rounded, 'Mtumiaji', () {
                    Navigator.pop(context);
                    app.navigate(AppScreen.profile);
                  }, 7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
    int index,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.cream, size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.white.withValues(alpha: 0.4), size: 20),
      onTap: onTap,
    ).animate().fadeIn(delay: (index * 40).ms).slideX(begin: -0.05);
  }
}
