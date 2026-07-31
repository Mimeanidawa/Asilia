import 'package:flutter/material.dart';

/// Botanical palette for Dawa Asili — soft sage canvas, deep forest, honey accent.
class AppColors {
  // Canvas (kept as cream* for API compatibility)
  static const cream = Color(0xFFF1F5F2);
  static const creamDark = Color(0xFFE3EBE6);

  // Brand
  static const forest = Color(0xFF0C2A1B);
  static const forestLight = Color(0xFF1A4532);
  static const amber = Color(0xFFB8894A);
  static const amberLight = Color(0xFFD4B483);
  static const deviceBorder = Color(0xFF071A11);

  // Surfaces — slightly cool white so cards sit cleanly on sage canvas
  static const surface = Color(0xFFFBFCFB);
  static const surfaceElevated = Color(0xFFFFFFFF);

  // Harmonized botanical greens (no neon Tailwind clash)
  static const emerald50 = Color(0xFFEDF5F0);
  static const emerald100 = Color(0xFFD7E8DE);
  static const emerald200 = Color(0xFFB3D2C1);
  static const emerald400 = Color(0xFF4CA67F);
  static const emerald700 = Color(0xFF1E6A49);
  static const emerald800 = Color(0xFF165338);
  static const emerald900 = Color(0xFF0E3B28);

  // Neutrals with green undertone
  static const gray200 = Color(0xFFD9E1DC);
  static const gray400 = Color(0xFF88948E);
  static const gray500 = Color(0xFF65726B);
  static const gray600 = Color(0xFF48544D);

  // Semantic
  static const orange50 = Color(0xFFFFF7ED);
  static const orange200 = Color(0xFFFED7AA);
  static const red50 = Color(0xFFFEF2F2);
  static const red600 = Color(0xFFDC2626);
  static const blue50 = Color(0xFFEFF6FF);
  static const blue900 = Color(0xFF1E3A8A);

  static const cardShadow = Color(0x180C2A1B);
  static const softShadow = Color(0x0C0C2A1B);

  static LinearGradient get heroGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [forestLight, forest],
      );

  /// Soft mist wash for greeting / hero bands
  static LinearGradient get warmGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFE8F0EB),
          cream,
        ],
      );

  /// Subtle canvas depth behind scroll content
  static LinearGradient get canvasGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFFF6F9F7),
          cream,
          Color(0xFFECEFEA),
        ],
        stops: [0.0, 0.45, 1.0],
      );

  static LinearGradient get accentGlow => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          emerald50,
          cream,
          amberLight.withValues(alpha: 0.18),
        ],
      );
}
