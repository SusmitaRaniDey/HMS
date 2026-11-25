import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

class AppTextStyles {
  // Display Styles - Large Prominent Text
  static TextStyle displayLarge = TextStyle(
    fontSize: 36.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static TextStyle displayMedium = TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.15,
    letterSpacing: -0.25,
  );

  // Heading Styles - Hierarchy Headers
  static TextStyle h1 = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.2,
    letterSpacing: 0,
  );

  static TextStyle h2 = TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    height: 1.25,
    letterSpacing: 0.15,
  );

  static TextStyle h3 = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.3,
    letterSpacing: 0.15,
  );

  static TextStyle h4 = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.35,
    letterSpacing: 0.1,
  );

  static TextStyle h5 = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  // Body Text - Default Reading
  static TextStyle body1 = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle body2 = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static TextStyle body3 = TextStyle(
    fontSize: 13.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.5,
    letterSpacing: 0.1,
  );

  // Button Text - Interactive Elements
  static TextStyle button = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    letterSpacing: 0.5,
    height: 1.4,
  );

  static TextStyle buttonSmall = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
    letterSpacing: 0.4,
    height: 1.3,
  );

  // Label Text - Form & UI Labels
  static TextStyle label = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: 0.1,
    height: 1.4,
  );

  static TextStyle labelSmall = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.5,
    height: 1.3,
  );

  // Subtitle Text - Secondary Information
  static TextStyle subtitle1 = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle subtitle2 = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.45,
    letterSpacing: 0.1,
  );

  // Caption & Hint Text - Small & Supplementary
  static TextStyle caption = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.4,
    letterSpacing: 0.4,
  );

  static TextStyle captionSmall = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    height: 1.3,
    letterSpacing: 0.4,
  );

  // Overline - Tiny Uppercase Text
  static TextStyle overline = TextStyle(
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.textTertiary,
    letterSpacing: 1.5,
    height: 1.6,
  );

  // Special Styles
  static TextStyle error = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.error,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle success = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeight.w500,
    color: AppColors.success,
    height: 1.4,
    letterSpacing: 0.1,
  );

  static TextStyle link = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.primary,
    decoration: TextDecoration.none,
    height: 1.4,
    letterSpacing: 0.1,
  );
}
