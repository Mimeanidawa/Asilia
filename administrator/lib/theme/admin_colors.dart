import 'package:flutter/material.dart';

class AdminColors {
  AdminColors._();

  // ── Surfaces (zinc dark) ──────────────────────────────────────────────────
  static const bg = Color(0xFF09090B);
  static const surface = Color(0xFF111113);
  static const surfaceElevated = Color(0xFF1C1C20);
  static const card = Color(0xFF18181B);
  static const cardHover = Color(0xFF1F1F23);
  static const cardBorder = Color(0xFF27272A);
  static const divider = Color(0xFF3F3F46);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const forest = Color(0xFF064E3B);
  static const forestLight = Color(0xFF065F46);
  static const emerald = Color(0xFF34D399);
  static const emeraldDim = Color(0xFF10B981);
  static const emeraldGlow = Color(0x1A34D399);
  static const emeraldMuted = Color(0xFF052E16);

  // ── Accents ───────────────────────────────────────────────────────────────
  static const amber = Color(0xFFFBBF24);
  static const amberDim = Color(0xFFD97706);
  static const amberGlow = Color(0x1AFBBF24);

  static const blue = Color(0xFF60A5FA);
  static const blueDim = Color(0xFF3B82F6);
  static const blueGlow = Color(0x1A60A5FA);

  static const purple = Color(0xFFC084FC);
  static const purpleDim = Color(0xFFA855F7);
  static const purpleGlow = Color(0x1AC084FC);

  static const rose = Color(0xFFFB7185);
  static const roseGlow = Color(0x1AFB7185);

  static const red = Color(0xFFF87171);
  static const redGlow = Color(0x1AF87171);

  // ── Text (neutral — no green body text) ───────────────────────────────────
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const textDim = Color(0xFF52525B);

  // ── Status ────────────────────────────────────────────────────────────────
  static const success = Color(0xFF4ADE80);
  static const warning = Color(0xFFFBBF24);
  static const error = Color(0xFFF87171);
  static const info = Color(0xFF60A5FA);

  // ── Charts ────────────────────────────────────────────────────────────────
  static const chart1 = Color(0xFF34D399);
  static const chart2 = Color(0xFF60A5FA);
  static const chart3 = Color(0xFFFBBF24);
  static const chart4 = Color(0xFFC084FC);
  static const chart5 = Color(0xFFFB7185);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const gradientStart = Color(0xFF09090B);
  static const gradientMid = Color(0xFF0C0C0F);
  static const gradientEnd = Color(0xFF111113);

  static LinearGradient get pageGradient => const LinearGradient(
        colors: [gradientStart, gradientMid, gradientEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get meshGradient => const LinearGradient(
        colors: [Color(0xFF09090B), Color(0xFF0A0F0D), Color(0xFF09090B)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get primaryGradient => const LinearGradient(
        colors: [Color(0xFF059669), Color(0xFF34D399)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get emeraldGradient => primaryGradient;

  static LinearGradient get amberGradient => const LinearGradient(
        colors: [Color(0xFFB45309), Color(0xFFFBBF24)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get blueGradient => const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF60A5FA)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFFC084FC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get roseGradient => const LinearGradient(
        colors: [Color(0xFFE11D48), Color(0xFFFB7185)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static BoxDecoration get navBarDecoration => BoxDecoration(
        color: surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: cardBorder.withValues(alpha: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
