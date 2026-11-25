import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import 'welcome_controller.dart';

class WelcomeScreen extends GetView<WelcomeController> {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Gradient hero area
          Container(
            height: screenHeight * 0.50,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
            ),
          ),

          // Decorative blobs
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 180.w,
              height: 180.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            top: 80,
            right: 30,
            child: Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            top: 160,
            left: -20,
            child: Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Back button
                Padding(
                  padding: EdgeInsets.only(left: 8.w, top: 4.h),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 4.h),

                // Logo
                Center(
                  child: Container(
                    width: 86.w,
                    height: 86.w,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.favorite,
                      size: 44.sp,
                      color: AppColors.primary,
                    ),
                  ),
                ),

                SizedBox(height: 16.h),

                // Title
                Center(
                  child: Text(
                    'Patient Portal',
                    style: AppTextStyles.h1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ),

                SizedBox(height: 6.h),

                Center(
                  child: Text(
                    'Your health, our priority',
                    style: AppTextStyles.body1.copyWith(
                      color: Colors.white.withValues(alpha: 0.82),
                    ),
                  ),
                ),

                SizedBox(height: 28.h),

                // White bottom card
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(36.r),
                        topRight: Radius.circular(36.r),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 24,
                          offset: const Offset(0, -6),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 24.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section label
                          Row(
                            children: [
                              Container(
                                width: 4.w,
                                height: 22.h,
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2.r),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Text(
                                'What you can do',
                                style: AppTextStyles.h4.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 18.h),

                          _FeatureCard(
                            icon: Icons.calendar_month_rounded,
                            color: AppColors.primary,
                            title: 'Book Appointments',
                            subtitle: 'Schedule visits with top specialists',
                          ),

                          SizedBox(height: 12.h),

                          _FeatureCard(
                            icon: Icons.biotech_rounded,
                            color: AppColors.secondary,
                            title: 'Diagnostic Tests',
                            subtitle: 'Book lab tests from home',
                          ),

                          SizedBox(height: 12.h),

                          _FeatureCard(
                            icon: Icons.history_rounded,
                            color: AppColors.accentViolet,
                            title: 'Health History',
                            subtitle: 'Track your medical records & visits',
                          ),

                          SizedBox(height: 32.h),

                          CustomButton(
                            text: 'Login to Account',
                            onPressed: () => controller.navigateToLogin(),
                            icon: Icons.login_rounded,
                          ),

                          SizedBox(height: 12.h),

                          CustomButton(
                            text: 'Create New Account',
                            onPressed: () => controller.navigateToRegister(),
                            isOutlined: true,
                            color: AppColors.primary,
                          ),

                          SizedBox(height: 20.h),

                          Center(
                            child: Text(
                              'Trusted by thousands of patients',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textHint,
                              ),
                            ),
                          ),

                          SizedBox(height: 8.h),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.borderLight, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: color, size: 26.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(subtitle, style: AppTextStyles.body3),
              ],
            ),
          ),
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: color,
              size: 15.sp,
            ),
          ),
        ],
      ),
    );
  }
}
