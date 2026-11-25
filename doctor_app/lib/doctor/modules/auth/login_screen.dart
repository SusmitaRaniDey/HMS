import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  String? get tag => 'doctor';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                onPressed: () => Get.back(),
                icon: Icon(Icons.arrow_back, size: 24.sp),
                padding: EdgeInsets.zero,
              ),

              SizedBox(height: 16.h),

              // Title
              Text(
                'Doctor Login',
                style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8.h),

              Text(
                'Login with your doctor credentials',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 24.h),

              // Email Field
              CustomTextField(
                controller: controller.loginEmailController,
                label: 'Email',
                hint: 'Enter your email',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              SizedBox(height: 16.h),

              // Password Field
              CustomTextField(
                controller: controller.loginPasswordController,
                label: 'Password',
                hint: 'Enter your password',
                prefixIcon: Icons.lock_outline,
                obscureText: true,
              ),

              SizedBox(height: 24.h),

              // Login Button
              Obx(
                () => CustomButton(
                  text: 'Login',
                  onPressed: controller.login,
                  isLoading: controller.isLoading.value,
                ),
              ),

              SizedBox(height: 24.h),

              // Info Note
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                      size: 18.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Use the email and password for your doctor account.',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
