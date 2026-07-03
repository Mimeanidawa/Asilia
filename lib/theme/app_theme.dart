import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../utils/platform_fonts.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.light(
        primary: AppColors.forest,
        secondary: AppColors.amber,
        surface: Colors.white,
        onPrimary: AppColors.cream,
        onSurface: AppColors.forest,
      ),
    );

    final textTheme = useSystemFonts
        ? base.textTheme
        : GoogleFonts.interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: useSystemFonts
            ? textTheme.displayLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              )
            : GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w800,
                color: AppColors.forest,
              ),
        headlineMedium: useSystemFonts
            ? textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.forest,
              )
            : GoogleFonts.playfairDisplay(
                fontWeight: FontWeight.w700,
                color: AppColors.forest,
              ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.forest,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.forest.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.forest.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.forest.withValues(alpha: 0.3)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
