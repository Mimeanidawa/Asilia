import 'package:flutter/material.dart';

class AdminColors {
  AdminColors._();

  // Backgrounds
  static const bg = Color(0xFF0A1612);
  static const surface = Color(0xFF0F1E17);
  static const card = Color(0xFF132019);
  static const cardBorder = Color(0xFF1E3328);

  // Brand
  static const forest = Color(0xFF113121);
  static const forestLight = Color(0xFF1A4A2E);
  static const emerald = Color(0xFF10B981);
  static const emeraldDim = Color(0xFF059669);
  static const emeraldGlow = Color(0x2010B981);

  // Accents
  static const amber = Color(0xFFF59E0B);
  static const amberDim = Color(0xFF836C45);
  static const amberGlow = Color(0x20F59E0B);

  static const blue = Color(0xFF3B82F6);
  static const blueGlow = Color(0x203B82F6);

  static const purple = Color(0xFFA855F7);
  static const purpleGlow = Color(0x20A855F7);

  static const red = Color(0xFFEF4444);
  static const redGlow = Color(0x20EF4444);

  // Text
  static const textPrimary = Color(0xFFF0FDF4);
  static const textSecondary = Color(0xFF86EFAC);
  static const textMuted = Color(0xFF4ADE80);
  static const textDim = Color(0xFF6B7280);

  // Status
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // Charts
  static const chart1 = Color(0xFF10B981);
  static const chart2 = Color(0xFF3B82F6);
  static const chart3 = Color(0xFFF59E0B);
  static const chart4 = Color(0xFFA855F7);
  static const chart5 = Color(0xFFEF4444);

  // Gradients
  static const gradientStart = Color(0xFF0A1612);
  static const gradientEnd = Color(0xFF0D2018);

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [forest, forestLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get emeraldGradient => const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF10B981)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get amberGradient => const LinearGradient(
        colors: [Color(0xFF92400E), Color(0xFFF59E0B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get blueGradient => const LinearGradient(
        colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
