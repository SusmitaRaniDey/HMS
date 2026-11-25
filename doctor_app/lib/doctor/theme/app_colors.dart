import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Doctor dashboard teal palette
  static const Color primary = Color(0xFF0F7895);
  static const Color primaryDark = Color(0xFF0A4A5D);
  static const Color primaryLight = Color(0xFF63B7C7);
  static const Color primaryContainer = Color(0xFFEAF6F8);
  static const Color primarySoft = Color(0xFFF5FBFF);
  static const Color primaryBorder = Color(0xFFDCEFFB);

  // Secondary Colors - Refined cyan accent
  static const Color secondary = Color(0xFF26A6B8);
  static const Color secondaryDark = Color(0xFF168294);
  static const Color secondaryLight = Color(0xFF83D6DF);
  static const Color secondaryContainer = Color(0xFFE8F8FA);

  // Background Colors - Layered System
  static const Color background = Color(0xFFF6FAFB);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF0F7F8);
  static const Color cardBackground = Colors.white;
  static const Color scaffold = Color(0xFFF7FBFC);

  // Text Colors - Enhanced Hierarchy
  static const Color textPrimary = Color(0xFF102A33);
  static const Color textSecondary = Color(0xFF5F737A);
  static const Color textTertiary = Color(0xFF8AA0A7);
  static const Color textHint = Color(0xFFA8B8BD);
  static const Color textWhite = Colors.white;
  static const Color textDisabled = Color(0xFFC7D3D7);

  // Status Colors - Vibrant & Clear
  static const Color success = Color(0xFF34C759);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9500);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF0F7895);
  static const Color infoLight = Color(0xFFEAF6F8);

  // Appointment/Booking Status Colors
  static const Color pending = Color(0xFFFF9500);
  static const Color confirmed = Color(0xFF34C759);
  static const Color completed = Color(0xFF0F7895);
  static const Color cancelled = Color(0xFF8AA0A7);
  static const Color rejected = Color(0xFFFF3B30);

  // Border & Divider Colors - Subtle
  static const Color border = Color(0xFFDDE9EC);
  static const Color borderLight = Color(0xFFEAF2F4);
  static const Color divider = Color(0xFFE4EEF1);

  // Overlay & Shadow Colors - Depth System
  static const Color shadow = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowHeavy = Color(0x1F000000);
  static const Color overlay = Color(0x66000000);
  static const Color overlayLight = Color(0x33000000);
  static const Color scrim = Color(0x80000000);

  // Interactive States
  static const Color ripple = Color(0x1A0F7895);
  static const Color hover = Color(0x0A000000);
  static const Color pressed = Color(0x14000000);
  static const Color focus = Color(0x1F0F7895);

  // Gradients - Modern & Smooth
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F7895), Color(0xFF63B7C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient dashboardGradient = LinearGradient(
    colors: [Color(0xFF0F7895), Color(0xFF63B7C7), Color(0xFFEAF6F8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF26A6B8), Color(0xFF168294)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF2FB34C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFE4EEF1), Color(0xFFF6FAFB), Color(0xFFE4EEF1)],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
}
