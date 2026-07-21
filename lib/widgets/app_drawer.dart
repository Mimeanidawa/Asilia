import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/content_models.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_colors.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();

    return Drawer(
      backgroundColor: AppColors.forest,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.eco, color: AppColors.cream, size: 36),
                  SizedBox(height: 12),
                  Text(
                    'Dawa Asili',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'Elimu ya dawa za asili kwa Kiswahili',
                    style: TextStyle(color: AppColors.cream, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24),
            _item(context, Icons.home_rounded, 'Nyumbani', () {
              Navigator.pop(context);
              app.navigate(AppScreen.home);
            }),
            _item(context, Icons.school_rounded, 'Dodoso', () {
              Navigator.pop(context);
              app.navigate(AppScreen.contentList, contentSection: ContentSections.dodoso);
            }),
            _item(context, Icons.category_rounded, 'Chagua Mada', () {
              Navigator.pop(context);
              app.navigate(AppScreen.contentList, contentSection: ContentSections.chaguaMada);
            }),
            _item(context, Icons.menu_book_rounded, 'Jifunze', () {
              Navigator.pop(context);
              app.navigate(AppScreen.learn);
            }),
            _item(context, Icons.restaurant_rounded, 'Vyakula na Matunda', () {
              Navigator.pop(context);
              app.navigate(AppScreen.contentList, contentSection: ContentSections.vyakulaMatunda);
            }),
            _item(context, Icons.school_outlined, 'Uliza Mwalimu', () {
              Navigator.pop(context);
              app.navigate(AppScreen.askExpert);
            }),
            _item(context, Icons.notifications_rounded, 'Arifa', () {
              Navigator.pop(context);
              app.navigate(AppScreen.notifications);
            }),
            _item(context, Icons.person_rounded, 'Mtumiaji', () {
              Navigator.pop(context);
              app.navigate(AppScreen.profile);
            }),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: AppColors.cream, size: 22),
      title: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      onTap: onTap,
    );
  }
}
