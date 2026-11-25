import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Modern Blue Palette
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);
  static const Color primaryContainer = Color(0xFFE3F2FD);

  // Secondary Colors - Accent Teal
  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryDark = Color(0xFF00897B);
  static const Color secondaryLight = Color(0xFF4DB6AC);
  static const Color secondaryContainer = Color(0xFFE0F2F1);

  // Background Colors - Layered System
  static const Color background = Color(0xFFF8F9FA);
  static const Color surface = Colors.white;
  static const Color surfaceVariant = Color(0xFFF5F5F7);
  static const Color cardBackground = Colors.white;
  static const Color scaffold = Color(0xFFFAFAFC);

  // Text Colors - Enhanced Hierarchy
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textTertiary = Color(0xFF8E8E93);
  static const Color textHint = Color(0xFFAAAAAA);
  static const Color textWhite = Colors.white;
  static const Color textDisabled = Color(0xFFC7C7CC);

  // Status Colors - Vibrant & Clear
  static const Color success = Color(0xFF34C759);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFFF9500);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color error = Color(0xFFFF3B30);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF007AFF);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Appointment/Booking Status Colors
  static const Color pending = Color(0xFFFF9500);
  static const Color confirmed = Color(0xFF34C759);
  static const Color completed = Color(0xFF007AFF);
  static const Color cancelled = Color(0xFF8E8E93);
  static const Color rejected = Color(0xFFFF3B30);

  // Border & Divider Colors - Subtle
  static const Color border = Color(0xFFE5E5EA);
  static const Color borderLight = Color(0xFFF2F2F7);
  static const Color divider = Color(0xFFEFEFF4);

  // Overlay & Shadow Colors - Depth System
  static const Color shadow = Color(0x0A000000);
  static const Color shadowMedium = Color(0x14000000);
  static const Color shadowHeavy = Color(0x1F000000);
  static const Color overlay = Color(0x66000000);
  static const Color overlayLight = Color(0x33000000);
  static const Color scrim = Color(0x80000000);

  // Interactive States
  static const Color ripple = Color(0x1A1E88E5);
  static const Color hover = Color(0x0A000000);
  static const Color pressed = Color(0x14000000);
  static const Color focus = Color(0x1F1E88E5);

  // Gradients - Modern & Smooth
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFF26A69A), Color(0xFF00897B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF2FB34C)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient shimmerGradient = LinearGradient(
    colors: [Color(0xFFEBEBF4), Color(0xFFF4F4F4), Color(0xFFEBEBF4)],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );
}
