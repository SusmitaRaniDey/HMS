import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'auth_controller.dart';

class LoginScreen extends GetView<AuthController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight = constraints.maxHeight;
            final isSmallScreen = screenHeight < 700;

            return SingleChildScrollView(
              padding: EdgeInsets.all(24.w),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48.w,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back Button
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(Icons.arrow_back, size: 24.sp),
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                      ),

                      SizedBox(height: isSmallScreen ? 16.h : 24.h),

                      // Title
                      Text(
                        'Welcome Back, Patient!',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 22.sp : null,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Text(
                        'Login to your patient account',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isSmallScreen ? 12.sp : null,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24.h : 32.h),

                      // Login Type Toggle
                      Obx(
                        () => Container(
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildToggleButton(
                                  'Email',
                                  controller.isLoginWithEmail.value,
                                  () => controller.toggleLoginType(),
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                              Expanded(
                                child: _buildToggleButton(
                                  'Phone',
                                  !controller.isLoginWithEmail.value,
                                  () => controller.toggleLoginType(),
                                  isSmallScreen: isSmallScreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20.h : 24.h),

                      // Email/Phone Field
                      Obx(
                        () => CustomTextField(
                          controller: controller.loginEmailPhoneController,
                          label: controller.isLoginWithEmail.value
                              ? 'Email'
                              : 'Phone Number',
                          hint: controller.isLoginWithEmail.value
                              ? 'Enter your email'
                              : 'Enter your phone number',
                          prefixIcon: controller.isLoginWithEmail.value
                              ? Icons.email_outlined
                              : Icons.phone_outlined,
                          keyboardType: controller.isLoginWithEmail.value
                              ? TextInputType.emailAddress
                              : TextInputType.phone,
                        ),
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

                      SizedBox(height: 8.h),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Get.snackbar(
                              'Forgot Password',
                              'Self-service password reset isn\'t available yet. '
                                  'Please contact the hospital reception/support '
                                  'desk to have your password reset.',
                              backgroundColor: AppColors.info,
                              colorText: Colors.white,
                              duration: const Duration(seconds: 5),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: isSmallScreen ? 11.sp : null,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 20.h : 24.h),

                      // Login Button
                      Obx(
                        () => CustomButton(
                          text: 'Login',
                          onPressed: controller.login,
                          isLoading: controller.isLoading.value,
                        ),
                      ),

                      SizedBox(height: 20.h),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'OR',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.textHint,
                                fontSize: isSmallScreen ? 11.sp : null,
                              ),
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),

                      SizedBox(height: 20.h),

                      // Register Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: AppTextStyles.body2,
                          ),
                          GestureDetector(
                            onTap: () => Get.offNamed(AppRoutes.REGISTER),
                            child: Text(
                              'Register',
                              style: AppTextStyles.body2.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 11.sp : null,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 16.h : 24.h),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildToggleButton(
    String text,
    bool isActive,
    VoidCallback onTap, {
    required bool isSmallScreen,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 10.h : 12.h),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Center(
          child: Text(
            text,
            style: AppTextStyles.body1.copyWith(
              color: isActive ? Colors.white : AppColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              fontSize: isSmallScreen ? 12.sp : null,
            ),
          ),
        ),
      ),
    );
  }
}
