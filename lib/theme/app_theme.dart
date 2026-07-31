import 'package:flutter/cupertino.dart';
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
        surface: AppColors.surfaceElevated,
        onPrimary: AppColors.cream,
        onSurface: AppColors.forest,
        surfaceContainerHighest: AppColors.creamDark,
        outline: AppColors.forest.withValues(alpha: 0.08),
      ),
      splashFactory: InkSparkle.splashFactory,
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
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.forest,
          letterSpacing: -0.3,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.gray600,
          height: 1.45,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: AppColors.forest,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.forest.withValues(alpha: 0.055)),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.emerald50,
        selectedColor: AppColors.forest,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: AppColors.forest.withValues(alpha: 0.07)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.forest.withValues(alpha: 0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.forest.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.emerald700, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.forest.withValues(alpha: 0.06),
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
