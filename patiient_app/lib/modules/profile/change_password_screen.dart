import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_textfield.dart';
import 'profile_controller.dart';

class ChangePasswordScreen extends GetView<ProfileController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          children: [
            // Security Icon
            Container(
              width: 100.w,
              height: 100.w,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                size: 50.sp,
                color: AppColors.primary,
              ),
            ),

            SizedBox(height: 32.h),

            // Information Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.warning.withOpacity(0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password Requirements',
                          style: AppTextStyles.subtitle2.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '• Must be at least 6 characters long\n'
                              '• Should be different from current password\n'
                              '• Use a strong, unique password',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Current Password Field
            CustomTextField(
              controller: controller.oldPasswordController,
              label: 'Current Password',
              hint: 'Enter your current password',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),

            SizedBox(height: 20.h),

            // New Password Field
            CustomTextField(
              controller: controller.newPasswordController,
              label: 'New Password',
              hint: 'Enter your new password',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),

            SizedBox(height: 20.h),

            // Confirm New Password Field
            CustomTextField(
              controller: controller.confirmPasswordController,
              label: 'Confirm New Password',
              hint: 'Re-enter your new password',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),

            SizedBox(height: 32.h),

            // Change Password Button
            Obx(() => CustomButton(
              text: 'Change Password',
              onPressed: controller.changePassword,
              isLoading: controller.isLoading.value,
            )),

            SizedBox(height: 16.h),

            // Security Note
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    size: 20.sp,
                    color: AppColors.success,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Your password is encrypted and secure',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}