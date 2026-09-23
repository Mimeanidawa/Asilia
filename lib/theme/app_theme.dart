import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import '../utils/platform_fonts.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: ColorScheme.light(
        primary: AppColors.forest,
        secondary: AppColors.emerald700,
        tertiary: AppColors.amber,
        surface: AppColors.surfaceElevated,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.forest,
        surfaceContainerHighest: AppColors.cream,
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
          letterSpacing: -0.6,
          height: 1.15,
          fontSize: size,
        );
      }
      return GoogleFonts.outfit(
        fontWeight: weight ?? FontWeight.w700,
        color: AppColors.forest,
        letterSpacing: -0.6,
        height: 1.15,
        fontSize: size,
      );
    }

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: display(textTheme.displayLarge, size: 32),
        displayMedium: display(textTheme.displayMedium, size: 26),
        headlineLarge: display(textTheme.headlineLarge, weight: FontWeight.w800, size: AppTypography.displayTitle),
        headlineMedium: display(textTheme.headlineMedium, weight: FontWeight.w800, size: AppTypography.screenTitle),
        titleLarge: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.forest,
          letterSpacing: -0.3,
          fontSize: AppTypography.screenTitle,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.forest,
          letterSpacing: -0.2,
          fontSize: AppTypography.sectionTitle,
        ),
        titleSmall: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.forest,
          letterSpacing: -0.1,
          fontSize: AppTypography.cardTitle,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(
          color: AppColors.textPrimary,
          height: 1.5,
          fontSize: AppTypography.body,
        ),
        bodyMedium: textTheme.bodyMedium?.copyWith(
          color: AppColors.textPrimary,
          height: 1.45,
          fontSize: AppTypography.subtitle,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.35,
          fontSize: AppTypography.caption,
        ),
        labelLarge: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          fontSize: AppTypography.button,
        ),
        labelMedium: textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: AppTypography.caption,
        ),
        labelSmall: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          fontSize: AppTypography.badge,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surfaceElevated.withValues(alpha: 0.95),
        foregroundColor: AppColors.forest,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: AppColors.forest,
          letterSpacing: -0.3,
          fontSize: AppTypography.screenTitle,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surfaceElevated,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusLg),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        margin: EdgeInsets.zero,
        shadowColor: AppColors.cardShadow,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.emerald50,
        selectedColor: AppColors.forest,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: AppTypography.badge),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusPill),
          side: const BorderSide(color: AppColors.borderLight),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: AppColors.forest,
          borderRadius: BorderRadius.circular(AppColors.radiusPill),
          boxShadow: AppColors.elevationSm,
        ),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: AppTypography.subtitle,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppTypography.subtitle,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppColors.radiusMd),
          borderSide: const BorderSide(color: AppColors.forest, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        hintStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w500,
          fontSize: AppTypography.body,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.borderLight,
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppTypography.button,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.forest,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppTypography.button,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.forest,
          side: const BorderSide(color: AppColors.borderLight, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppTypography.button,
            letterSpacing: 0.2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.forest,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppColors.radiusPill),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: AppTypography.subtitle,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.forest,
        contentTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
          fontSize: AppTypography.body,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppColors.radiusSm)),
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
