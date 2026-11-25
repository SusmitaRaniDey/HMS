import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'auth_controller.dart';

class RegisterScreen extends GetView<AuthController> {
  const RegisterScreen({super.key});

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
                        'Create Account',
                        style: AppTextStyles.h2.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: isSmallScreen ? 22.sp : null,
                        ),
                      ),

                      SizedBox(height: 4.h),

                      Text(
                        'Sign up to get started',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isSmallScreen ? 12.sp : null,
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 24.h : 32.h),

                      // Register Type Toggle
                      Obx(() => Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildToggleButton(
                                'Email',
                                controller.isRegisterWithEmail.value,
                                () => controller.toggleRegisterType(),
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                            Expanded(
                              child: _buildToggleButton(
                                'Phone',
                                !controller.isRegisterWithEmail.value,
                                () => controller.toggleRegisterType(),
                                isSmallScreen: isSmallScreen,
                              ),
                            ),
                          ],
                        ),
                      )),

                      SizedBox(height: isSmallScreen ? 16.h : 24.h),

                      // Name Field
                      CustomTextField(
                        controller: controller.registerNameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        prefixIcon: Icons.person_outline,
                        keyboardType: TextInputType.name,
                      ),

                      SizedBox(height: 16.h),

                      // Email/Phone Field
                      Obx(() => CustomTextField(
                        controller: controller.registerEmailPhoneController,
                        label: controller.isRegisterWithEmail.value ? 'Email' : 'Phone Number',
                        hint: controller.isRegisterWithEmail.value
                            ? 'Enter your email'
                            : 'Enter your phone number',
                        prefixIcon: controller.isRegisterWithEmail.value
                            ? Icons.email_outlined
                            : Icons.phone_outlined,
                        keyboardType: controller.isRegisterWithEmail.value
                            ? TextInputType.emailAddress
                            : TextInputType.phone,
                      )),

                      SizedBox(height: 16.h),

                      // Password Field
                      CustomTextField(
                        controller: controller.registerPasswordController,
                        label: 'Password',
                        hint: 'Enter your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                      ),

                      SizedBox(height: 16.h),

                      // Confirm Password Field
                      CustomTextField(
                        controller: controller.registerConfirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        prefixIcon: Icons.lock_outline,
                        obscureText: true,
                      ),

                      SizedBox(height: isSmallScreen ? 20.h : 24.h),

                      // Register Button
                      Obx(() => CustomButton(
                        text: 'Create Account',
                        onPressed: controller.register,
                        isLoading: controller.isLoading.value,
                      )),

                      SizedBox(height: 16.h),

                      // Terms and Conditions
                      Text(
                        'By creating an account, you agree to our Terms of Service and Privacy Policy',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: isSmallScreen ? 10.sp : null,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      SizedBox(height: 16.h),

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

                      SizedBox(height: 16.h),

                      // Login Link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Already have an account? ',
                            style: AppTextStyles.body2,
                          ),
                          GestureDetector(
                            onTap: () => Get.offNamed(AppRoutes.LOGIN),
                            child: Text(
                              'Login',
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

  Widget _buildToggleButton(String text, bool isActive, VoidCallback onTap, {required bool isSmallScreen}) {
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