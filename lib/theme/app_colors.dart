import 'package:flutter/material.dart';

/// Dawa Asili — Verdant Ink.
/// Cool mist canvas, deep botanical ink, celadon leaf, copper spark.
class AppColors {
  // Canvas (cream* kept for API compatibility) — slightly deeper so cards pop
  static const cream = Color(0xFFDEE8E2);
  static const creamDark = Color(0xFFCDD9D2);

  // Brand ink
  static const forest = Color(0xFF0A1F1A);
  static const forestLight = Color(0xFF163D32);
  static const amber = Color(0xFFC17A45);
  static const amberLight = Color(0xFFE0B089);
  static const deviceBorder = Color(0xFF041510);

  // Surfaces — keep elevated white for contrast against darker canvas
  static const surface = Color(0xFFF2F6F3);
  static const surfaceElevated = Color(0xFFFFFFFF);

  // Celadon leaf scale
  static const emerald50 = Color(0xFFDCECE3);
  static const emerald100 = Color(0xFFC3DDCF);
  static const emerald200 = Color(0xFFA5D4B8);
  static const emerald400 = Color(0xFF3FAE78);
  static const emerald700 = Color(0xFF1B7A52);
  static const emerald800 = Color(0xFF145C3E);
  static const emerald900 = Color(0xFF0C3D2A);

  // Neutrals — cool green undertone
  static const gray200 = Color(0xFFC8D3CD);
  static const gray400 = Color(0xFF7E8C85);
  static const gray500 = Color(0xFF5A6A63);
  static const gray600 = Color(0xFF3D4A44);

  // Semantic
  static const orange50 = Color(0xFFFFF4EB);
  static const orange200 = Color(0xFFF5C9A8);
  static const red50 = Color(0xFFFFF1F1);
  static const red600 = Color(0xFFD14343);
  static const blue50 = Color(0xFFEEF5FB);
  static const blue900 = Color(0xFF1A3A5C);

  static const cardShadow = Color(0x1A0A1F1A);
  static const softShadow = Color(0x120A1F1A);

  static const radiusSm = 12.0;
  static const radiusMd = 18.0;
  static const radiusLg = 24.0;
  static const radiusXl = 28.0;

  static List<BoxShadow> get elevationSm => [
        BoxShadow(
          color: softShadow,
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get elevationMd => [
        BoxShadow(
          color: cardShadow,
          blurRadius: 24,
          offset: const Offset(0, 10),
          spreadRadius: -6,
        ),
      ];

  static List<BoxShadow> get elevationLg => [
        BoxShadow(
          color: forest.withValues(alpha: 0.16),
          blurRadius: 32,
          offset: const Offset(0, 16),
          spreadRadius: -8,
        ),
      ];

  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A5C45), forest],
      );

  static LinearGradient get warmGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFD4E2DA), cream],
      );

  static LinearGradient get canvasGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFE4EDE7),
          cream,
          Color(0xFFD2DFD7),
        ],
        stops: [0.0, 0.5, 1.0],
      );

  static const accentGlow = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFD8E8DF),
          Color(0xFFE2EBE5),
          Color(0xFFD5E3DB),
        ],
      );

  static LinearGradient get inkWash => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          forestLight.withValues(alpha: 0.95),
          forest,
          const Color(0xFF041510),
        ],
      );

  static LinearGradient get leafSheen => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF2D9B6F), Color(0xFF1B7A52)],
      );
}
