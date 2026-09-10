import 'package:flutter/material.dart';

/// Dawa Asili — refined botanical system.
/// Soft mist canvas, deep forest ink, leaf accent, warm copper spark.
class AppColors {
  // Canvas (cream* kept for API compatibility)
  static const cream = Color(0xFFF3F7F4);
  static const creamDark = Color(0xFFE4EDE7);

  // Brand ink
  static const forest = Color(0xFF0C231C);
  static const forestLight = Color(0xFF1A4034);
  static const amber = Color(0xFFC17A45);
  static const amberLight = Color(0xFFE4BC96);
  static const deviceBorder = Color(0xFF041510);

  // Surfaces
  static const surface = Color(0xFFF7FAF8);
  static const surfaceElevated = Color(0xFFFFFFFF);

  // Leaf scale
  static const emerald50 = Color(0xFFE8F3EC);
  static const emerald100 = Color(0xFFD0E6D9);
  static const emerald200 = Color(0xFFA8D4BC);
  static const emerald400 = Color(0xFF3FAE78);
  static const emerald700 = Color(0xFF1B7A52);
  static const emerald800 = Color(0xFF145C3E);
  static const emerald900 = Color(0xFF0C3D2A);

  // Neutrals — cool green undertone
  static const gray200 = Color(0xFFD0DAD4);
  static const gray400 = Color(0xFF84928B);
  static const gray500 = Color(0xFF5E6E66);
  static const gray600 = Color(0xFF3A4741);

  // Semantic
  static const orange50 = Color(0xFFFFF4EB);
  static const orange200 = Color(0xFFF5C9A8);
  static const red50 = Color(0xFFFFF1F1);
  static const red600 = Color(0xFFD14343);
  static const blue50 = Color(0xFFEEF5FB);
  static const blue900 = Color(0xFF1A3A5C);

  static const cardShadow = Color(0x140C231C);
  static const softShadow = Color(0x0D0C231C);

  static const radiusSm = 14.0;
  static const radiusMd = 18.0;
  static const radiusLg = 22.0;
  static const radiusXl = 28.0;
  static const radiusPill = 999.0;

  static List<BoxShadow> get elevationSm => [
        BoxShadow(
          color: softShadow,
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get elevationMd => [
        BoxShadow(
          color: cardShadow,
          blurRadius: 28,
          offset: const Offset(0, 12),
          spreadRadius: -8,
        ),
      ];

  static List<BoxShadow> get elevationLg => [
        BoxShadow(
          color: forest.withValues(alpha: 0.12),
          blurRadius: 36,
          offset: const Offset(0, 18),
          spreadRadius: -10,
        ),
      ];

  static List<BoxShadow> get navShadow => [
        BoxShadow(
          color: forest.withValues(alpha: 0.10),
          blurRadius: 32,
          offset: const Offset(0, 12),
          spreadRadius: -4,
        ),
        BoxShadow(
          color: forest.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1F6B52), forest],
      );

  static LinearGradient get warmGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE8F0EB), cream],
      );

  static LinearGradient get canvasGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF7FAF8),
          cream,
          Color(0xFFEAF1EC),
        ],
        stops: [0.0, 0.45, 1.0],
      );

  static const accentGlow = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE8F3EC),
          Color(0xFFF2F7F4),
          Color(0xFFE0EDE5),
        ],
      );

  static LinearGradient get inkWash => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          forestLight.withValues(alpha: 0.96),
          forest,
          const Color(0xFF061610),
        ],
      );

  static LinearGradient get leafSheen => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D9B6F), Color(0xFF1B7A52)],
      );

  static LinearGradient get headerSheen => LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          surfaceElevated.withValues(alpha: 0.98),
          surfaceElevated.withValues(alpha: 0.92),
        ],
      );
}
