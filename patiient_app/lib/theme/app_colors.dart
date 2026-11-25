import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Professional hospital teal
  static const Color primary = Color(0xFF007C89);
  static const Color primaryDark = Color(0xFF005B66);
  static const Color primaryLight = Color(0xFF36B6C5);
  static const Color primaryContainer = Color(0xFFDDF7FA);

  // Secondary Colors - Trustworthy clinical blue
  static const Color secondary = Color(0xFF2563EB);
  static const Color secondaryDark = Color(0xFF1D4ED8);
  static const Color secondaryLight = Color(0xFF60A5FA);
  static const Color secondaryContainer = Color(0xFFEAF2FF);

  // Supporting accents for colorful healthcare UI moments
  static const Color accentBlue = Color(0xFF0EA5E9);
  static const Color accentViolet = Color(0xFF7C3AED);
  static const Color accentOrange = Color(0xFFF59E0B);
  static const Color accentRose = Color(0xFFE11D48);

  // Background Colors - Clean clinical surfaces
  static const Color background = Color(0xFFF6FAFB);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFEEF6F8);
  static const Color cardBackground = Colors.white;
  static const Color scaffold = Color(0xFFF6FAFB);

  // Text Colors - Crisp, high contrast hierarchy
  static const Color textPrimary = Color(0xFF102A43);
  static const Color textSecondary = Color(0xFF526D82);
  static const Color textTertiary = Color(0xFF8BA3AF);
  static const Color textHint = Color(0xFFADC1C9);
  static const Color textWhite = Colors.white;
  static const Color textDisabled = Color(0xFFD5E2E7);

  // Status Colors - Vibrant & Clear
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFE9F8EF);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFF6E5);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF2563EB);
  static const Color infoLight = Color(0xFFEAF2FF);

  // Appointment/Booking Status Colors
  static const Color pending = Color(0xFFF59E0B);
  static const Color confirmed = Color(0xFF16A34A);
  static const Color completed = Color(0xFF2563EB);
  static const Color cancelled = Color(0xFF94A3B8);
  static const Color rejected = Color(0xFFDC2626);

  // Border & Divider Colors - Subtle
  static const Color border = Color(0xFFD9E8ED);
  static const Color borderLight = Color(0xFFEAF3F6);
  static const Color divider = Color(0xFFE3EEF2);

  // Overlay & Shadow Colors - Depth System
  static const Color shadow = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowHeavy = Color(0x1F000000);
  static const Color overlay = Color(0x66000000);
  static const Color overlayLight = Color(0x33000000);
  static const Color scrim = Color(0x80000000);

  // Interactive States
  static const Color ripple = Color(0x1A007C89);
  static const Color hover = Color(0x0A000000);
  static const Color pressed = Color(0x14000000);
  static const Color focus = Color(0x1F007C89);

  // Gradients - Modern & Smooth
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0097A7), Color(0xFF007C89), Color(0xFF005B66)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient appointmentGradient = LinearGradient(
    colors: [Color(0xFF00A7B5), Color(0xFF007C89), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFEAF3F6), Color(0xFFF6FAFB), Color(0xFFEAF3F6)],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
}
