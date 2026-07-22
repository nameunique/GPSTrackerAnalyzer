import 'package:flutter/material.dart';
import 'package:gps_tracker_analyzer/core/theme/app_colors.dart';

abstract final class AppTextStyles {
  const AppTextStyles._();

  static const List<String> fallback = <String>[
    'Roboto',
    'Arial',
    'sans-serif',
  ];

  static const TextStyle display = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 48,
    height: 52 / 48,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 12,
    height: 18 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textSecondary,
  );

  static const TextStyle navigation = TextStyle(
    fontFamily: 'Roboto',
    fontFamilyFallback: fallback,
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.textMuted,
  );
}
