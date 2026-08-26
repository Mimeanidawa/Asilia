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
        tertiary: AppColors.emerald700,
        surface: AppColors.surfaceElevated,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.forest,
        surfaceContainerHighest: AppColors.creamDark,
        outline: AppColors.forest.withValues(alpha: 0.08),
      ),
      splashFactory: InkSparkle.splashFactory,
    );

    final textTheme = useSystemFonts
        ? base.textTheme
        : GoogleFonts.plusJakartaSansTextTheme(base.textTheme);

    TextStyle? display(TextStyle? fallback, {FontWeight? weight, double? size}) {
      if (useSystemFonts) {
        return fallback?.copyWith(
          fontWeight: weight ?? FontWeight.w800,
          color: AppColors.forest,
          letterSpacing: -0.8,
          height: 1.15,
          fontSize: size,
        );
      }
      return GoogleFonts.outfit(
        fontWeight: weight ?? FontWeight.w700,
        color: AppColors.forest,
        letterSpacing: -0.8,
        height: 1.15,
        fontSize: size,
      );
    }

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: display(textTheme.displayLarge, size: 36),
        displayMedium: display(textTheme.displayMedium, size: 28),
        headlineLarge: display(textTheme.headlineLarge, weight: FontWeight.w700, size: 26),
        headlineMedium: display(textTheme.headlineMedium, weight: FontWeight.w700, size: 22),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.forest,
          letterSpacing: -0.4,
          fontSize: 18,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: AppColors.forest,
          letterSpacing: -0.2,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: AppColors.gray600,
          height: 1.5,
          fontSize: 15,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.gray600,
          height: 1.5,
          fontSize: 14,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.gray500,
          height: 1.4,
          fontSize: 12,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.92),
        foregroundColor: AppColors.forest,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.forest,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          side: BorderSide(color: AppColors.forest.withValues(alpha: 0.04)),
        ),
        margin: EdgeInsets.zero,
        shadowColor: AppColors.cardShadow,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.emerald50,
        selectedColor: AppColors.forest,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: AppColors.forest.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide(color: AppColors.forest.withValues(alpha: 0.07)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: BorderSide(color: AppColors.forest.withValues(alpha: 0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.emerald700, width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(
          color: AppColors.forest.withValues(alpha: 0.35),
          fontWeight: FontWeight.w500,
        ),
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
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.forest,
        contentTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
