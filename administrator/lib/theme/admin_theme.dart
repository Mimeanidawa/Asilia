import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_colors.dart';

class AdminTheme {
  AdminTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AdminColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.emerald,
        secondary: AdminColors.amber,
        surface: AdminColors.surface,
        error: AdminColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AdminColors.textPrimary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AdminColors.bg,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AdminColors.textPrimary,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: AdminColors.textPrimary),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.inter(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w800,
          fontSize: 32,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.inter(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 26,
          letterSpacing: -0.4,
        ),
        headlineMedium: GoogleFonts.inter(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
          letterSpacing: -0.3,
        ),
        headlineSmall: GoogleFonts.inter(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
        titleLarge: GoogleFonts.inter(
          color: AdminColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        titleMedium: GoogleFonts.inter(
          color: AdminColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        bodyLarge: GoogleFonts.inter(
          color: AdminColors.textPrimary,
          fontSize: 15,
        ),
        bodyMedium: GoogleFonts.inter(
          color: AdminColors.textSecondary,
          fontSize: 13,
        ),
        bodySmall: GoogleFonts.inter(
          color: AdminColors.textDim,
          fontSize: 12,
        ),
      ),
      cardTheme: CardThemeData(
        color: AdminColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AdminColors.cardBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AdminColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AdminColors.emerald, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 14),
        hintStyle: GoogleFonts.inter(color: AdminColors.textDim, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AdminColors.emerald,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AdminColors.cardBorder,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AdminColors.surface,
        selectedItemColor: AdminColors.emerald,
        unselectedItemColor: AdminColors.textDim,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AdminColors.card,
        selectedColor: AdminColors.emeraldGlow,
        side: const BorderSide(color: AdminColors.cardBorder),
        labelStyle: GoogleFonts.inter(fontSize: 12, color: AdminColors.textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
