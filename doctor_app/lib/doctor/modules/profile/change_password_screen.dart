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
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Change Password')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.info, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Password must be at least 6 characters long',
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            // Current Password
            Text(
              'Current Password',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            CustomTextField(
              controller: controller.oldPasswordController,
              hint: 'Enter your current password',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
              label: 'enter password',
            ),

            SizedBox(height: 24.h),

            // New Password
            Text(
              'New Password',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            CustomTextField(
              controller: controller.newPasswordController,
              hint: 'Enter new password (min 6 characters)',
              prefixIcon: Icons.lock,
              obscureText: true,
              label: 'change password',
            ),

            SizedBox(height: 24.h),

            // Confirm New Password
            Text(
              'Confirm New Password',
              style: AppTextStyles.subtitle1.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            CustomTextField(
              controller: controller.confirmPasswordController,
              hint: 'Re-enter new password',
              prefixIcon: Icons.lock,
              obscureText: true,
              label: 'change password',
            ),

            SizedBox(height: 32.h),

            // Change Password Button
            Obx(
              () => CustomButton(
                text: 'Change Password',
                onPressed: controller.changePassword,
                isLoading: controller.isLoading.value,
              ),
            ),

            SizedBox(height: 16.h),

            // Security Note
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.security, color: AppColors.warning, size: 20.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'For security reasons, you will remain logged in after changing your password.',
                      style: AppTextStyles.caption.copyWith(
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
