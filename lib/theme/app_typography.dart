import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Single source of truth for app-wide responsive typography.
/// Ensures all screens have identical, balanced, and legible font hierarchies.
class AppTypography {
  AppTypography._();

  // Core standardized font sizes
  static const double displayTitle = 24.0;
  static const double screenTitle = 18.0;
  static const double sectionTitle = 16.0;
  static const double cardTitle = 14.5;
  static const double button = 13.5;
  static const double body = 13.0;
  static const double subtitle = 12.0;
  static const double caption = 11.0;
  static const double badge = 10.0;

  // Standardized text styles
  static TextStyle display({
    Color? color,
    double? size,
    FontWeight? weight,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size ?? displayTitle,
    fontWeight: weight ?? FontWeight.w900,
    color: color ?? AppColors.forest,
    letterSpacing: letterSpacing ?? -0.6,
    height: height ?? 1.15,
  );

  static TextStyle screen({
    Color? color,
    double? size,
    FontWeight? weight,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size ?? screenTitle,
    fontWeight: weight ?? FontWeight.w800,
    color: color ?? AppColors.forest,
    letterSpacing: letterSpacing ?? -0.4,
    height: height ?? 1.2,
  );

  static TextStyle section({
    Color? color,
    double? size,
    FontWeight? weight,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size ?? sectionTitle,
    fontWeight: weight ?? FontWeight.w800,
    color: color ?? AppColors.forest,
    letterSpacing: letterSpacing ?? -0.3,
    height: height ?? 1.2,
  );

  static TextStyle card({
    Color? color,
    double? size,
    FontWeight? weight,
    double? height,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size ?? cardTitle,
    fontWeight: weight ?? FontWeight.w800,
    color: color ?? AppColors.forest,
    letterSpacing: letterSpacing ?? -0.2,
    height: height ?? 1.25,
  );

  static TextStyle btn({
    Color? color,
    double? size,
    FontWeight? weight,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size ?? button,
    fontWeight: weight ?? FontWeight.w800,
    color: color,
    letterSpacing: letterSpacing ?? 0.2,
  );

  static TextStyle bodyRegular({
    Color? color,
    double? size,
    FontWeight? weight,
    double? height,
  }) => TextStyle(
    fontSize: size ?? body,
    fontWeight: weight ?? FontWeight.w500,
    color: color ?? AppColors.textPrimary,
    height: height ?? 1.5,
  );

  static TextStyle sub({
    Color? color,
    double? size,
    FontWeight? weight,
    double? height,
  }) => TextStyle(
    fontSize: size ?? subtitle,
    fontWeight: weight ?? FontWeight.w500,
    color: color ?? AppColors.textSecondary,
    height: height ?? 1.35,
  );

  static TextStyle cap({
    Color? color,
    double? size,
    FontWeight? weight,
    double? height,
  }) => TextStyle(
    fontSize: size ?? caption,
    fontWeight: weight ?? FontWeight.w600,
    color: color ?? AppColors.textSecondary,
    height: height ?? 1.3,
  );

  static TextStyle microBadge({
    Color? color,
    double? size,
    FontWeight? weight,
    double? letterSpacing,
  }) => TextStyle(
    fontSize: size ?? badge,
    fontWeight: weight ?? FontWeight.w800,
    color: color,
    letterSpacing: letterSpacing ?? 0.3,
  );
}
