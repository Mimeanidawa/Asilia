import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_colors.dart';
import '../utils/platform_fonts.dart';

class SidebarBranding extends StatelessWidget {
  const SidebarBranding({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.forest.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(Icons.eco, color: AppColors.forest),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dawa Asili',
                    style: _serif(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forest,
                    ),
                  ),
                  Text(
                    'NATURAL HEALING. REAL RESULTS.',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: AppColors.amber,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Heal Naturally,\nLive Better.',
            style: _serif(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.1,
              color: AppColors.forest,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Your trusted companion for native herbal remedies, wellness tips, and a healthier, revitalized you. Preserving ancient African healing wisdom.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.gray600.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 24),
          _featureCard(
            Icons.eco,
            '100% Natural Remedies',
            'Discover effective, time-tested herbal treatments.',
          ),
          const SizedBox(height: 12),
          _featureCard(
            Icons.menu_book,
            'Health & Wellness Tips',
            'Learn and live an authentic, vital, disease-free lifestyle.',
          ),
          const SizedBox(height: 12),
          _featureCard(
            Icons.chat_bubble_outline,
            'Ask an Expert',
            'Receive personal consultation from real herbal specialists.',
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.forest.withValues(alpha: 0.2)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 14, color: AppColors.amber),
                SizedBox(width: 8),
                Text(
                  'Rooted in Nature. Backed by Tradition.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.forest,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.forest.withValues(alpha: 0.04)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.forest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.cream, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.forest,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(fontSize: 12, color: AppColors.gray500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _serif({
    required double fontSize,
    FontWeight? fontWeight,
    double? height,
    Color? color,
  }) {
    if (useSystemFonts) {
      return TextStyle(
        fontFamily: 'Georgia',
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        color: color,
      );
    }
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }
}
