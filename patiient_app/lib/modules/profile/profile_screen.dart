import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/bottom_nav_bar.dart';
import 'profile_controller.dart';

class ProfileScreen extends GetView<ProfileController> {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: AppColors.primary,
               // gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32.r),
                  bottomRight: Radius.circular(32.r),
                ),
              ),
              child: Obx(() {
                final patient = controller.patient.value;
                return Column(
                  children: [
                    SizedBox(height: 30,),
                    Container(
                      width: 100.w,
                      height: 100.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.person,
                        size: 50.sp,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      patient?.name ?? 'Guest',
                      style: AppTextStyles.h4.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (patient?.email != null)
                      Text(
                        patient!.email!,
                        style: AppTextStyles.body1.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    if (patient?.phone != null)
                      Text(
                        patient!.phone,
                        style: AppTextStyles.body1.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                  ],
                );
              }),
            ),

            SizedBox(height: 24.h),

            // Menu Items
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: Icons.person_outline,
                    title: 'Edit Profile',
                    subtitle: 'Update your personal information',
                    onTap: () => Get.toNamed(AppRoutes.EDIT_PROFILE),
                  ),
                  SizedBox(height: 12.h),
                  _buildMenuItem(
                    icon: Icons.lock_outline,
                    title: 'Change Password',
                    subtitle: 'Update your account password',
                    onTap: () => Get.toNamed(AppRoutes.CHANGE_PASSWORD),
                  ),
                  SizedBox(height: 12.h),
                  _buildMenuItem(
                    icon: Icons.calendar_today_outlined,
                    title: 'My Appointments',
                    subtitle: 'View all your appointments',
                    onTap: () => Get.toNamed(AppRoutes.APPOINTMENTS),
                  ),
                  SizedBox(height: 12.h),
                  _buildMenuItem(
                    icon: Icons.science_outlined,
                    title: 'My Bookings',
                    subtitle: 'View all your test bookings',
                    onTap: () => Get.toNamed(AppRoutes.BOOKINGS),
                  ),
                  SizedBox(height: 12.h),
                  // _buildMenuItem(
                  //   icon: Icons.info_outline,
                  //   title: 'About',
                  //   subtitle: 'App version and information',
                  //   onTap: () {
                  //     Get.dialog(
                  //       AlertDialog(
                  //         title: const Text('About'),
                  //         content: const Text(
                  //           'Hospital Patient App\nVersion 1.0.0\n\n'
                  //               'Your health, our priority.',
                  //         ),
                  //         actions: [
                  //           TextButton(
                  //             onPressed: () => Get.back(),
                  //             child: const Text('Close'),
                  //           ),
                  //         ],
                  //       ),
                  //     );
                  //   },
                  // ),
                  SizedBox(height: 12.h),
                  _buildMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    subtitle: 'Sign out from your account',
                    onTap: controller.logout,
                    iconColor: AppColors.error,
                    titleColor: AppColors.error,
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppColors.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.subtitle1.copyWith(
                      fontWeight: FontWeight.w600,
                      color: titleColor,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16.sp,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}