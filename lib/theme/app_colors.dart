import 'package:flutter/material.dart';

/// Dawa Asili — Modern, premium botanical design system.
/// Crisp luminous canvas, deep forest ink, emerald accents, and warm golden embers.
class AppColors {
  // Canvas & surfaces
  static const cream = Color(0xFFF4F7F4);
  static const creamDark = Color(0xFFE8EFEA);
  static const surface = Color(0xFFF9FBF9);
  static const surfaceElevated = Color(0xFFFFFFFF);
  static const canvas = Color(0xFFF6F9F7);

  // Brand ink
  static const forest = Color(0xFF09281E);
  static const forestLight = Color(0xFF144534);
  static const deviceBorder = Color(0xFF061A13);

  // Accent & Sparks
  static const amber = Color(0xFFD97706);
  static const amberLight = Color(0xFFFDE68A);
  static const gold = Color(0xFFF59E0B);

  // Emerald leaf scale
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);
  static const emerald900 = Color(0xFF064E3B);

  // Neutrals with subtle botanic undertone
  static const gray100 = Color(0xFFF3F4F6);
  static const gray200 = Color(0xFFE5E7EB);
  static const gray300 = Color(0xFFD1D5DB);
  static const gray400 = Color(0xFF9CA3AF);
  static const gray500 = Color(0xFF6B7280);
  static const gray600 = Color(0xFF4B5563);
  static const gray700 = Color(0xFF374151);

  // Modern typography & input helpers
  static const textPrimary = Color(0xFF09281E);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const borderLight = Color(0x1409281E);
  static const inputFill = Color(0xFFF9FBF9);

  // Semantic
  static const orange50 = Color(0xFFFFF7ED);
  static const orange200 = Color(0xFFFED7AA);
  static const red50 = Color(0xFFFEF2F2);
  static const red600 = Color(0xFFDC2626);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue900 = Color(0xFF1E3A8A);

  // Modern soft shadows
  static const cardShadow = Color(0x0C09281E);
  static const softShadow = Color(0x0809281E);

  // Standard radii
  static const radiusXs = 8.0;
  static const radiusSm = 12.0;
  static const radiusMd = 16.0;
  static const radiusLg = 20.0;
  static const radiusXl = 26.0;
  static const radiusPill = 999.0;

  static List<BoxShadow> get elevationSm => [
        const BoxShadow(
          color: Color(0x08000000),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ];

  static List<BoxShadow> get elevationMd => [
        const BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 20,
          offset: Offset(0, 6),
          spreadRadius: -2,
        ),
      ];

  static List<BoxShadow> get elevationLg => [
        const BoxShadow(
          color: Color(0x1409281E),
          blurRadius: 32,
          offset: Offset(0, 12),
          spreadRadius: -4,
        ),
      ];

  static List<BoxShadow> get navShadow => [
        const BoxShadow(
          color: Color(0x1209281E),
          blurRadius: 28,
          offset: Offset(0, 8),
          spreadRadius: -2,
        ),
        const BoxShadow(
          color: Color(0x06000000),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ];

  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF0D3D2E), forest],
      );

  static LinearGradient get warmGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFF1F6F2), cream],
      );

  static LinearGradient get canvasGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFFAFBF9),
          Color(0xFFF4F7F4),
          Color(0xFFEEF3EF),
        ],
        stops: [0.0, 0.5, 1.0],
      );

  static const accentGlow = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFECFDF5),
          Color(0xFFF4F7F4),
          Color(0xFFD1FAE5),
        ],
      );

  static LinearGradient get inkWash => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          forestLight,
          forest,
          Color(0xFF04140F),
        ],
      );

  static LinearGradient get leafSheen => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF10B981), Color(0xFF047857)],
      );

  static LinearGradient get headerSheen => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          surfaceElevated,
          surfaceElevated.withValues(alpha: 0.94),
        ],
      );
}
