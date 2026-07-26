import 'package:flutter/material.dart';

abstract final class AppColors {
  const AppColors._();

  // Backgrounds
  static const Color canvas = Color(0xFF07111F);
  static const Color surface = Color(0xFF0B1728);
  static const Color surfaceRaised = Color(0xFF12243A);
  static const Color accentSubtle = Color(0xFF1B3552);

  // Brand and data
  static const Color accent = Color(0xFF2F6BFF);
  static const Color gps = Color(0xFF20C6E8);
  static const Color success = Color(0xFF7BE33B);
  static const Color warning = Color(0xFFFFB02E);
  static const Color error = Color(0xFFFF5A6B);

  // Borders
  static const Color border = Color(0xFF1B3552);
  static const Color borderAccent = Color(0xFF4C82FF);

  // Content
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8C4D6);
  static const Color textMuted = Color(0xFF718096);
  static const Color textOnAccent = Color(0xFFFFFFFF);

  static const Color scrim = Color(0x99000000);
  static const double disabledOpacity = 0.45;

  // Compatibility aliases for the original screens. New UI should use the
  // semantic names above.
  static const Color scaffoldBlue = canvas;
  static const Color primaryBlue = accent;
  static const Color cardWhite = surfaceRaised;
  static const Color speedLine = borderAccent;
  static const Color heightLine = gps;
  static const Color accelLine = warning;
  static const Color grid = border;
  static const Color validRed = error;
}
